#!/usr/bin/env python3
"""Renders README pictures of the Maines window without WoW.

1. Writes font metrics for the fonts the UI uses (so the add-on's own layout code measures
   text the way it will be drawn here).
2. Runs tools/render_ui.lua: loads the add-on in the offline mock (tests/wowmock.lua), sets
   sample settings, opens the window and dumps every visible region with resolved screen
   rectangles, colours, gradients, textures, text and draw order to JSON.
3. Draws that JSON with Pillow + numpy into docs/media/.

Run from anywhere:  python3 tools/render_ui.py
"""
import json
import math
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(ROOT, "docs", "media")
S = 2            # pixels per UI unit (render at 2x for crispness)
MARGIN = 40      # UI units of backdrop around the window

# Font stand-ins. Agave is the add-on's own bundled font (exact). MORPHEUS.TTF, ARIALN.TTF and
# FRIZQT__.TTF ship with the WoW client, which is not on this PC: open look-alikes are used.
LIB_SANS = "/usr/share/fonts/liberation/LiberationSans-Regular.ttf"
FONTS = {
    "agave_regular": {"path": os.path.join(ROOT, "fonts/agave/Agave-Regular.ttf")},
    "agave_bold": {"path": os.path.join(ROOT, "fonts/agave/Agave-Bold.ttf")},
    # WoW's engraved quest-title face -> Cinzel (OFL, tools/fonts/)
    "morpheus": {"path": os.path.join(ROOT, "tools/fonts/Cinzel.ttf"), "variation": b"Bold"},
    # Arial Narrow -> Liberation Sans Narrow (same glyph widths; tools/fonts/, GPLv2 + font exception)
    "arialn": {"path": os.path.join(ROOT, "tools/fonts/LiberationSansNarrow-Regular.ttf")},
    "friz": {"path": LIB_SANS},
}

_font_cache = {}


def font(key, px):
    k = (key, px)
    if k not in _font_cache:
        spec = FONTS[key]
        f = ImageFont.truetype(spec["path"], px)
        if spec.get("variation"):
            try:
                f.set_variation_by_name(spec["variation"])
            except Exception:
                pass
        _font_cache[k] = f
    return _font_cache[k]


# ------------------------------------------------------------------ metrics for the Lua side
def write_metrics(path):
    chars = set(chr(c) for c in range(32, 127)) | {" "}
    for name in os.listdir(ROOT):
        if name.endswith(".lua"):
            with open(os.path.join(ROOT, name), encoding="utf-8", errors="replace") as fh:
                chars |= set(ch for ch in fh.read() if ord(ch) >= 128)
    lines = ["return {"]
    for key, spec in FONTS.items():
        f = font(key, 1000)
        sq = spec.get("squeeze", 1.0)
        lines.append("  %s = { adv = {" % key)
        for ch in sorted(chars):
            try:
                w = f.getlength(ch) * sq
            except Exception:
                continue
            lines.append("    [%d] = %.2f," % (ord(ch), w))
        lines.append("  } },")
    lines.append("}")
    with open(path, "w") as fh:
        fh.write("\n".join(lines))


# ------------------------------------------------------------------ texture loading
_tex_cache = {}


def load_texture(path):
    """WoW texture path -> float RGBA array (0..1), or None."""
    if path in _tex_cache:
        return _tex_cache[path]
    arr = None
    p = path.replace("\\", "/")
    low = p.lower()
    marker = "interface/addons/maines/"
    if low.startswith(marker):
        rel = p[len(marker):]
        cand = os.path.join(ROOT, rel)
        for c in (cand, cand + ".tga", cand + ".png", cand + ".blp"):
            if os.path.isfile(c) and not c.endswith(".blp"):
                arr = np.asarray(Image.open(c).convert("RGBA"), dtype=np.float32) / 255.0
                break
    if arr is None:
        print("  ! texture not available offline:", path)
    _tex_cache[path] = arr
    return arr


# ------------------------------------------------------------------ compositing
class Canvas:
    def __init__(self, x0, y0, w, h, bg):
        self.x0, self.y0 = x0, y0          # UI units of the canvas origin
        self.W, self.H = int(round(w * S)), int(round(h * S))
        self.rgb = bg.copy()

    def px(self, x, y):
        return (x - self.x0) * S, (y - self.y0) * S

    def composite(self, layer_rgba, ox, oy, blend="BLEND", clip=None, alpha=1.0):
        """layer_rgba: float HxWx4 (straight alpha); ox, oy: pixel position on the canvas."""
        h, w = layer_rgba.shape[:2]
        x0, y0, x1, y1 = ox, oy, ox + w, oy + h
        cx0, cy0, cx1, cy1 = 0, 0, self.W, self.H
        if clip:
            ccx, ccy = self.px(clip[0], clip[1])
            cx0, cy0 = max(cx0, int(round(ccx))), max(cy0, int(round(ccy)))
            cx1 = min(cx1, int(round(ccx + clip[2] * S)))
            cy1 = min(cy1, int(round(ccy + clip[3] * S)))
        ax0, ay0, ax1, ay1 = max(x0, cx0), max(y0, cy0), min(x1, cx1), min(y1, cy1)
        if ax0 >= ax1 or ay0 >= ay1:
            return
        sub = layer_rgba[ay0 - oy:ay1 - oy, ax0 - ox:ax1 - ox]
        a = sub[..., 3:4] * alpha
        dst = self.rgb[ay0:ay1, ax0:ax1]
        if blend == "ADD":
            dst += sub[..., :3] * a
            np.clip(dst, 0, 1, out=dst)
        else:
            dst *= (1 - a)
            dst += sub[..., :3] * a


def vertex_colors(item, w, h):
    """Per-pixel RGBA multiplier from vertex colour / gradient."""
    g = item.get("gradient")
    if g:
        mn, mx = np.array(g["min"], np.float32), np.array(g["max"], np.float32)
        if g["orientation"].upper() == "HORIZONTAL":
            t = (np.arange(w, dtype=np.float32) + 0.5) / max(w, 1)
            row = mn[None, :] * (1 - t[:, None]) + mx[None, :] * t[:, None]
            return np.broadcast_to(row[None, :, :], (h, w, 4)).copy()
        # VERTICAL: min colour at the bottom, max at the top
        t = (np.arange(h, dtype=np.float32) + 0.5) / max(h, 1)
        col = mx[None, :] * (1 - t[:, None]) + mn[None, :] * t[:, None]
        return np.broadcast_to(col[:, None, :], (h, w, 4)).copy()
    c = np.array(item.get("color", [1, 1, 1, 1]), np.float32)
    return np.broadcast_to(c, (h, w, 4)).copy()


def draw_texture(cv, item):
    x, y, w, h = item["box"]
    if w <= 0 or h <= 0:
        return
    px0, py0 = cv.px(x, y)
    px1, py1 = cv.px(x + w, y + h)
    ix0, iy0, ix1, iy1 = int(round(px0)), int(round(py0)), int(round(px1)), int(round(py1))
    pw, ph = max(1, ix1 - ix0), max(1, iy1 - iy0)
    tex = item.get("texture")
    if tex == "white":
        img = np.ones((ph, pw, 4), np.float32)
    else:
        src = load_texture(tex)
        if src is None:
            return
        th, tw = src.shape[:2]
        tc = item.get("texcoord")
        if tc:
            l, r, t, b = tc
            src = src[int(round(t * th)):max(int(round(t * th)) + 1, int(round(b * th))),
                      int(round(l * tw)):max(int(round(l * tw)) + 1, int(round(r * tw)))]
        if item.get("htile") or item.get("vtile"):
            # tiles repeat at the texture's own size, in UI units
            sh, sw = src.shape[:2]
            tile = Image.fromarray((src * 255).astype(np.uint8), "RGBA").resize((sw * S, sh * S), Image.BICUBIC)
            tile = np.asarray(tile, np.float32) / 255.0
            reps_y = ph // tile.shape[0] + 1
            reps_x = pw // tile.shape[1] + 1
            img = np.tile(tile, (reps_y, reps_x, 1))[:ph, :pw]
        else:
            im = Image.fromarray((src * 255).astype(np.uint8), "RGBA").resize((pw, ph), Image.BICUBIC)
            img = np.asarray(im, np.float32) / 255.0
        if item.get("desaturated"):
            lum = img[..., :3] @ np.array([0.3, 0.59, 0.11], np.float32)
            img[..., :3] = lum[..., None]
    img = img * vertex_colors(item, pw, ph)
    ox, oy = ix0, iy0
    rot = item.get("rotation")
    if rot:
        # SetRotation turns the whole quad about its centre
        pad = int(math.ceil(max(pw, ph) * 0.45)) + 2
        big = np.zeros((ph + 2 * pad, pw + 2 * pad, 4), np.float32)
        big[pad:pad + ph, pad:pad + pw] = img
        pre = big.copy()
        pre[..., :3] *= pre[..., 3:4]
        im = Image.fromarray((pre * 255).round().astype(np.uint8), "RGBA")
        im = im.rotate(math.degrees(rot), resample=Image.BICUBIC, center=(pad + pw / 2, pad + ph / 2))
        arr = np.asarray(im, np.float32) / 255.0
        a = arr[..., 3:4]
        arr[..., :3] = np.where(a > 0, arr[..., :3] / np.maximum(a, 1e-6), 0)
        img = arr
        ox, oy = ix0 - pad, iy0 - pad
        # supersampled edge looks crisper for these tiny diamonds; rotate already antialiases
    cv.composite(img, ox, oy, item.get("blend") or "BLEND", item.get("clip"), item.get("alpha", 1.0))


def render_line(key, size, runs, shadow=None):
    """Draws one text line into a straight-alpha RGBA array. Returns (array, baseline_y, width)."""
    px = max(1, int(round(size * S)))
    f = font(key, px)
    asc, desc = f.getmetrics()
    sq = FONTS[key].get("squeeze", 1.0)
    pad = 4 * S
    widths = [f.getlength(r["text"]) if "text" in r else r.get("w", 0) * S / sq for r in runs]
    full_w = int(math.ceil(sum(widths))) + 2 * pad
    hgt = asc + desc + 2 * pad
    canvas = np.zeros((hgt, full_w, 4), np.float32)

    def stamp(dx, dy, override=None):
        x = pad + dx
        for r, w in zip(runs, widths):
            if "text" in r:
                col = override or r["color"]
                m = Image.new("L", (full_w, hgt), 0)
                ImageDraw.Draw(m).text((x, pad + asc + dy), r["text"], font=f, anchor="ls", fill=255)
                a = np.asarray(m, np.float32)[..., None] / 255.0 * col[3]
                rgb = np.array(col[:3], np.float32)
                canvas[..., :3] = canvas[..., :3] * (1 - a) + rgb * a
                canvas[..., 3:4] = canvas[..., 3:4] + a * (1 - canvas[..., 3:4])
            elif "tex" in r and override is None:
                stamp_tex(r, x, w)
            x += w

    def stamp_tex(r, x, w):
        # |T...|t inline icon: centred on the line, tinted by the escape's r:g:b if it has them
        src = load_texture(r["tex"])
        if src is None:
            return
        tw, th = max(1, int(round(w))), max(1, int(round(r.get("h", r["w"]) * S)))
        im = Image.fromarray((src * 255).astype(np.uint8), "RGBA").resize((tw, th), Image.LANCZOS)
        img = np.asarray(im, np.float32) / 255.0
        spec = r.get("spec") or []
        if len(spec) >= 14 and all(str(v).strip().isdigit() for v in spec[11:14]):
            img = img * np.array([int(v) / 255 for v in spec[11:14]] + [1], np.float32)
        ix, iy = int(round(x)), int(round(pad + (asc + desc) / 2 - th / 2))
        x0, y0 = max(ix, 0), max(iy, 0)
        x1, y1 = min(ix + tw, canvas.shape[1]), min(iy + th, canvas.shape[0])
        if x1 <= x0 or y1 <= y0:
            return
        sub = img[y0 - iy:y1 - iy, x0 - ix:x1 - ix]
        a = sub[..., 3:4]
        dst = canvas[y0:y1, x0:x1]
        dst[..., :3] = dst[..., :3] * (1 - a) + sub[..., :3] * a
        dst[..., 3:4] = dst[..., 3:4] + a * (1 - dst[..., 3:4])

    if shadow:
        sx, sy = shadow["offset"]
        stamp(sx * S / sq, -sy * S, shadow["color"])
    stamp(0, 0)
    if sq != 1.0:
        im = Image.fromarray((canvas * 255).round().astype(np.uint8), "RGBA")
        im = im.resize((max(1, int(round(full_w * sq))), hgt), Image.LANCZOS)
        canvas = np.asarray(im, np.float32) / 255.0
        pad_x = pad * sq
    else:
        pad_x = pad
    return canvas, pad_x, pad + asc, sum(widths) * sq


def truncate_runs(runs, key, size, max_w):
    """Cuts a line with '...' so it fits max_w UI units (WoW's truncation)."""
    px = max(1, int(round(size * S)))
    f = font(key, px)
    sq = FONTS[key].get("squeeze", 1.0)

    def width(rs):
        return sum(f.getlength(r["text"]) for r in rs if "text" in r) * sq / S

    if width(runs) <= max_w + 0.5:
        return runs
    flat = [(ch, r["color"]) for r in runs if "text" in r for ch in r["text"]]
    while flat:
        flat.pop()
        cand = []
        for ch, col in flat:
            if cand and cand[-1]["color"] == col:
                cand[-1]["text"] += ch
            else:
                cand.append({"text": ch, "color": col})
        last_col = flat[-1][1] if flat else runs[0]["color"]
        cand.append({"text": "...", "color": last_col})
        if width(cand) <= max_w + 0.5:
            return cand
    return [{"text": "...", "color": runs[0]["color"]}]


def draw_text(cv, item):
    x, y, w, h = item["box"]
    key, size = item["font"], item["size"]
    lines = item["lines"]
    lh, sp = item["lineHeight"], item.get("spacing", 0)
    n = len(lines)
    total = n * lh + (n - 1) * sp
    jv = (item.get("justifyV") or "MIDDLE").upper()
    if jv == "TOP":
        top = y
    elif jv == "BOTTOM":
        top = y + h - total
    else:
        top = y + (h - total) / 2
    jh = (item.get("justifyH") or "CENTER").upper()
    clip = item.get("clip")
    if item.get("cliptobox"):
        box = [x, y, w, h]
        if clip:
            x0, y0 = max(box[0], clip[0]), max(box[1], clip[1])
            x1, y1 = min(box[0] + box[2], clip[0] + clip[2]), min(box[1] + box[3], clip[1] + clip[3])
            box = [x0, y0, max(0, x1 - x0), max(0, y1 - y0)]
        clip = box
    for i, line in enumerate(lines):
        runs = [r for r in line["runs"] if "text" in r or "tex" in r]
        if not runs:
            continue
        if item.get("truncate") and not any("tex" in r for r in runs):
            runs = truncate_runs(runs, key, size, w)
        arr, pad_x, base, lw_px = render_line(key, size, runs, item.get("shadow"))
        lw = lw_px / S
        if jh == "LEFT":
            lx = x
        elif jh == "RIGHT":
            lx = x + w - lw
        else:
            lx = x + (w - lw) / 2
        # baseline: the line box is `size` tall with the font's ascent/descent split
        f = font(key, max(1, int(round(size * S))))
        asc, desc = f.getmetrics()
        line_top = top + i * (lh + sp)
        baseline = line_top + size * asc / (asc + desc)
        bx, by = cv.px(lx, baseline)
        cv.composite(arr, int(round(bx - pad_x)), int(round(by - base)), "BLEND", clip, item.get("alpha", 1.0))


# ------------------------------------------------------------------ Blizzard template stand-ins
def rgba_img(w, h):
    return Image.new("RGBA", (max(1, int(w)), max(1, int(h))), (0, 0, 0, 0))


def paste_pil(cv, im, x, y, clip=None, alpha=1.0):
    arr = np.asarray(im, np.float32) / 255.0
    px, py = cv.px(x, y)
    cv.composite(arr, int(round(px)), int(round(py)), "BLEND", clip, alpha)


def c255(c, a=1.0):
    return tuple(int(round(v * 255)) for v in c) + (int(round(a * 255)),)


def draw_standin(cv, item):
    x, y, w, h = item["box"]
    what = item["what"]
    clip, alpha = item.get("clip"), item.get("alpha", 1.0)
    if what == "closebutton":
        # UIPanelCloseButton: red square button, gold rim, light X
        im = rgba_img(w * S, h * S)
        d = ImageDraw.Draw(im)
        inset = 3 * S
        rect = [inset, inset, w * S - inset - 1, h * S - inset - 1]
        d.rounded_rectangle(rect, radius=3 * S, fill=c255((0.62, 0.47, 0.20)))
        r2 = [rect[0] + 1.5 * S, rect[1] + 1.5 * S, rect[2] - 1.5 * S, rect[3] - 1.5 * S]
        d.rounded_rectangle(r2, radius=2 * S, fill=c255((0.60, 0.07, 0.04)))
        d.rounded_rectangle([r2[0], r2[1], r2[2], (r2[1] + r2[3]) / 2], radius=2 * S, fill=c255((0.74, 0.12, 0.07)))
        m = 6.5 * S
        d.line([m, m, w * S - m, h * S - m], fill=c255((0.98, 0.90, 0.72)), width=int(2 * S))
        d.line([w * S - m, m, m, h * S - m], fill=c255((0.98, 0.90, 0.72)), width=int(2 * S))
        paste_pil(cv, im, x, y, clip, alpha)
    elif what == "checkbox":
        # UICheckButtonTemplate: dark square with a grey bevelled rim, yellow tick when checked
        im = rgba_img(w * S, h * S)
        d = ImageDraw.Draw(im)
        inset = w * S * 0.16
        rect = [inset, inset, w * S - inset, h * S - inset]
        d.rounded_rectangle(rect, radius=2 * S, fill=c255((0.10, 0.09, 0.08)), outline=c255((0.62, 0.60, 0.55)),
                            width=int(1.5 * S))
        if item.get("checked"):
            pts = [(w * S * 0.28, h * S * 0.50), (w * S * 0.45, h * S * 0.68), (w * S * 0.80, h * S * 0.24)]
            d.line(pts, fill=c255((0.15, 0.10, 0.0)), width=int(4 * S), joint="curve")
            d.line(pts, fill=c255((1.0, 0.82, 0.0)), width=int(2.4 * S), joint="curve")
        paste_pil(cv, im, x, y, clip, alpha)
    elif what == "inputbox":
        # InputBoxTemplate: dark field, thin silver rim, art starting 5 units left of the box
        bx, bw = x - 5, w + 5
        by, bh = y + h / 2 - 10, 20
        im = rgba_img(bw * S, bh * S)
        d = ImageDraw.Draw(im)
        d.rounded_rectangle([0, 0, bw * S - 1, bh * S - 1], radius=4 * S, fill=c255((0.04, 0.04, 0.04), 0.82),
                            outline=c255((0.55, 0.53, 0.50)), width=int(1.5 * S))
        d.line([4 * S, 2.2 * S, bw * S - 4 * S, 2.2 * S], fill=c255((0, 0, 0), 0.6), width=S)
        paste_pil(cv, im, bx, by, clip, alpha)
    elif what == "scrollbar":
        # UIPanelScrollBarTemplate: round arrow buttons above/below the track, gold knob
        enabled = item.get("scrollable")
        rim = (0.70, 0.56, 0.24) if enabled else (0.45, 0.43, 0.40)
        arrow = (1.0, 0.82, 0.0) if enabled else (0.55, 0.53, 0.50)
        for top, up in ((y - 16, True), (y + h, False)):
            im = rgba_img(18 * S, 16 * S)
            d = ImageDraw.Draw(im)
            d.ellipse([2 * S, 1 * S, 16 * S, 15 * S], fill=c255((0.12, 0.10, 0.08)), outline=c255(rim), width=int(1.5 * S))
            cx, cy = 9 * S, 8 * S
            if up:
                tri = [(cx - 3.5 * S, cy + 2 * S), (cx + 3.5 * S, cy + 2 * S), (cx, cy - 2.5 * S)]
            else:
                tri = [(cx - 3.5 * S, cy - 2 * S), (cx + 3.5 * S, cy - 2 * S), (cx, cy + 2.5 * S)]
            d.polygon(tri, fill=c255(arrow))
            paste_pil(cv, im, x - 1, top, None, alpha)
        if enabled:
            # the knob is a fixed 18x24 texture (UI-ScrollBar-Knob), at the top while unscrolled
            im = rgba_img(16 * S, 24 * S)
            d = ImageDraw.Draw(im)
            d.rounded_rectangle([3 * S, 3 * S, 13 * S, 21 * S], radius=4 * S, fill=c255((0.62, 0.48, 0.20)),
                                outline=c255((0.30, 0.20, 0.08)), width=S)
            d.line([6 * S, 6 * S, 6 * S, 18 * S], fill=c255((0.92, 0.80, 0.50)), width=S)
            paste_pil(cv, im, x, y, None, alpha)


# ------------------------------------------------------------------ scene rendering
def backdrop(w, h):
    """A subtle dark backdrop: soft vertical gradient with a faint vignette."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    t = yy / max(h - 1, 1)
    top = np.array([0.105, 0.095, 0.085], np.float32)
    bot = np.array([0.055, 0.050, 0.047], np.float32)
    img = top * (1 - t[..., None]) + bot * t[..., None]
    dx, dy = (xx / w - 0.5) * 2, (yy / h - 0.45) * 2
    vig = 1 - 0.35 * np.clip(dx * dx + dy * dy, 0, 1.5) / 1.5
    return img * vig[..., None]


def render_scene(scene, crop):
    x0, y0, w, h = crop
    cv = Canvas(x0, y0, w, h, backdrop(int(round(w * S)), int(round(h * S))))
    for it in scene["items"]:
        k = it["kind"]
        if k == "texture":
            draw_texture(cv, it)
        elif k == "text":
            draw_text(cv, it)
        elif k == "standin":
            draw_standin(cv, it)
    return cv.rgb


def to_image(rgb):
    return Image.fromarray((np.clip(rgb, 0, 1) * 255).round().astype(np.uint8), "RGB")


def crop_for(scene):
    x, y, w, h = scene["root"]
    return [x - MARGIN, y - MARGIN, w + 2 * MARGIN, h + 2 * MARGIN]


def blend(a, b, t):
    return a * (1 - t) + b * t


def save_gif(path, frames, durations, width=760):
    small = []
    for f in frames:
        im = to_image(f)
        hh = int(round(im.height * width / im.width))
        small.append(im.resize((width, hh), Image.LANCZOS))
    # One palette for the whole GIF (so unchanged areas between frames compress away), built by
    # libimagequant from every frame at once, so small red/green details such as the close
    # button keep their colour.
    montage = Image.new("RGB", (width, sum(im.height for im in small)))
    yy = 0
    for im in small:
        montage.paste(im, (0, yy))
        yy += im.height
    pal = montage.quantize(colors=256, method=Image.Quantize.LIBIMAGEQUANT)
    q = [im.quantize(palette=pal, dither=Image.Dither.NONE) for im in small]
    q[0].save(path, save_all=True, append_images=q[1:], duration=durations, loop=0, optimize=True, disposal=1)


def caption_strip(rgb, text, h_units=26):
    """Adds a strip under the frame with the add-on's own chat line for that roll."""
    H, W = rgb.shape[:2]
    strip = np.zeros((h_units * S, W, 3), np.float32)
    strip[:] = rgb[-1:, :, :]
    out = np.concatenate([rgb, strip], axis=0)
    im = to_image(out)
    d = ImageDraw.Draw(im)
    f = font("agave_regular", 13 * S)
    tw = f.getlength(text)
    d.text(((W - tw) / 2, H + 2 * S), text, font=f, fill=(222, 206, 170))
    return np.asarray(im, np.float32) / 255.0


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="maines_render_")
    metrics = os.path.join(tmp, "metrics.lua")
    out_json = os.path.join(tmp, "render.json")
    write_metrics(metrics)
    env = dict(os.environ, MAINES_METRICS=metrics, MAINES_RENDER_OUT=out_json)
    subprocess.run(["lua5.1", os.path.join(ROOT, "tools", "render_ui.lua")], check=True, env=env)
    with open(out_json) as fh:
        data = json.load(fh)
    if data.get("errors"):
        print("UI code raised errors under the mock:")
        for e in data["errors"]:
            print("  ", e.splitlines()[0])
    scenes = {s["name"]: s for s in data["scenes"]}
    if os.environ.get("MAINES_KEEP_JSON"):
        import shutil
        shutil.copy(out_json, os.environ["MAINES_KEEP_JSON"])

    crop = crop_for(scenes["tab_main"])
    rendered = {}

    def get(name):
        if name not in rendered:
            rendered[name] = render_scene(scenes[name], crop)
        return rendered[name]

    tabs = ["main", "phrases", "animate", "badges", "filter", "behavior", "cosmetic", "help"]
    for key in tabs:
        to_image(get("tab_" + key)).save(os.path.join(OUT_DIR, "window-%s.png" % key), optimize=True)
        print("wrote docs/media/window-%s.png" % key)

    # note popup
    note = scenes["note"]
    to_image(render_scene(note, crop_for(note))).save(os.path.join(OUT_DIR, "note.png"), optimize=True)
    print("wrote docs/media/note.png")

    # tour: empty backdrop, the window's 0.18 s fade-in (smoothing OUT), then each page ~2 s
    empty = render_scene({"items": []}, crop)
    frames, durs = [empty], [600]
    first = get("tab_main")
    for i in range(1, 6):
        t = i / 5
        frames.append(blend(empty, first, 1 - (1 - t) ** 2))
        durs.append(40)
    for key in tabs:
        if key == "animate":
            for step in range(1, 4):
                frames.append(get("animate_step_%d" % step))
                durs.append(1200)
        else:
            frames.append(get("tab_" + key))
            durs.append(2000)
    save_gif(os.path.join(OUT_DIR, "window-tour.gif"), frames, durs)
    print("wrote docs/media/window-tour.gif")

    # palettes: the window repainted by /maincolor rolls (the add-on's own palette code)
    pframes, pdurs = [], []
    i = 0
    while "palette_%d" % i in scenes:
        sc = scenes["palette_%d" % i]
        pframes.append(caption_strip(render_scene(sc, crop), sc.get("caption", "")))
        pdurs.append(1600)
        i += 1
    save_gif(os.path.join(OUT_DIR, "palettes.gif"), pframes, pdurs)
    print("wrote docs/media/palettes.gif")


if __name__ == "__main__":
    main()
