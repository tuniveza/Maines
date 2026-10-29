#!/usr/bin/env python3
"""Builds the README header banner (run from anywhere: python3 tools/media_banner.py).

Writes docs/media/banner.png (2560x640: a 1280x320 layout drawn at 2x): the Maines logo
beside the name, with a brass rule and the tagline under them, all centred, on the addon's
own parchment with its brass trim. Surfaces reuse the
in-game recipe from maines.lua: flat colour + soft vertical shade + textures/grain.tga tinted
(0.30, 0.18, 0.06); the top and bottom trim bands use textures/brushed.tga over brass.

Needs Pillow and numpy. Optional: oxipng shrinks the file further if installed.
"""
import os
import shutil
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "media", "banner.png")
LOGO = os.path.join(ROOT, "docs", "branding", "maines-logo-1200.png")
GRAIN = os.path.join(ROOT, "textures", "grain.tga")
BRUSHED = os.path.join(ROOT, "textures", "brushed.tga")

W, H = 1280, 320  # layout size; every pixel size below is in these units
S = 2   # output scale: the PNG is W*S x H*S
SS = 2  # supersampling on top of that: draw at S*SS, then downsample once for smooth edges

TITLE = "Maines"
TAGLINE = "Take your main name to the chat frame, then gtfo."

# Heading font: the addon uses WoW's MORPHEUS in game; Noto Serif Display is the closest
# installed classic serif. Tagline: Noto Sans for a clean read at small sizes.
TITLE_FONTS = [
    "/usr/share/fonts/noto/NotoSerifDisplay-Bold.ttf",
    "/usr/share/fonts/noto/NotoSerif-Bold.ttf",
    "/usr/share/fonts/TTF/DejaVuSerif-Bold.ttf",
]
TAG_FONTS = [
    "/usr/share/fonts/noto/NotoSans-Medium.ttf",
    "/usr/share/fonts/noto/NotoSans-Regular.ttf",
    "/usr/share/fonts/TTF/DejaVuSans.ttf",
]

# Palette from maines.lua.
INK = (0.14, 0.08, 0.03)
INK_SOFT = (0.32, 0.22, 0.13)
PLATE_TEXT = (0.96, 0.91, 0.78)
ACCENT = (0.70, 0.47, 0.18)
WINDOW_BG = (0.68, 0.55, 0.34)
CONTENT_BG = (0.80, 0.68, 0.46)
PLATE_BG = (0.24, 0.16, 0.09)
BORDER_DARK = (0.30, 0.19, 0.09)
GRAIN_TINT = (0.30, 0.18, 0.06)
BRUSH_TINT = (0.36, 0.22, 0.07)


def font(paths, size):
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    raise SystemExit("no usable font found among: " + ", ".join(paths))


def tiled_alpha(path, w, h, scale=1):
    """The texture's alpha (0..1) tiled over w x h, each tile drawn at `scale`."""
    tex = Image.open(path).convert("RGBA").getchannel("A")
    if scale != 1:
        tex = tex.resize((tex.width * scale, tex.height * scale), Image.BICUBIC)
    a = np.array(tex, dtype=np.float32) / 255.0
    reps = (h // a.shape[0] + 1, w // a.shape[1] + 1)
    return np.tile(a, reps)[:h, :w]


def over(base, colour, alpha):
    """Blend a flat colour over base (HxWx3 floats) with per-pixel alpha (HxW)."""
    a = alpha[..., None]
    return base * (1 - a) + np.array(colour, dtype=np.float32) * a


def vgrad(h, w, top, bottom):
    t = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    img = np.array(top, np.float32) * (1 - t) + np.array(bottom, np.float32) * t
    return np.broadcast_to(img, (h, w, 3)).copy()


def rounded_mask(w, h, box, radius, blur=0):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    if blur:
        m = m.filter(ImageFilter.GaussianBlur(blur))
    return np.array(m, dtype=np.float32) / 255.0


def to_img(arr):
    return Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def build():
    s = S * SS
    w, h = W * s, H * s

    # Parchment body: CONTENT_BG with the in-game soft shade and grain.
    img = vgrad(h, w, [c * 1.04 for c in CONTENT_BG], [c * 0.92 for c in CONTENT_BG])
    img = over(img, GRAIN_TINT, tiled_alpha(GRAIN, w, h, s) * 0.30)

    # Gentle darkening toward the edges (worn parchment), strongest at the corners.
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    nx, ny = (xx / w - 0.5) * 2, (yy / h - 0.5) * 2
    edge = np.clip((nx ** 2) * 0.55 + (ny ** 2) * 0.45, 0, 1) ** 1.6
    img = over(img, BORDER_DARK, edge * 0.42)

    # Brushed brass trim bands top and bottom, like the window's title band.
    band = 10 * s
    for y0, y1 in ((0, band), (h - band, h)):
        strip = vgrad(y1 - y0, w, (0.60, 0.45, 0.24), (0.82, 0.67, 0.42))
        if y0:
            strip = strip[::-1]
        strip = over(strip, BRUSH_TINT, tiled_alpha(BRUSHED, w, y1 - y0, s) * 0.38)
        img[y0:y1] = strip

    # Layout, all centred: [logo] Maines on one row, a brass rule under it, the tagline below.
    # The title fonts are needed now to size the row; drawing happens after the logo is printed.
    title_f = font(TITLE_FONTS, 112 * s)
    tag_f = font(TAG_FONTS, 32 * s)
    probe = ImageDraw.Draw(Image.new("L", (1, 1)))
    tb = probe.textbbox((0, 0), TITLE, font=title_f, anchor="ls")
    gb = probe.textbbox((0, 0), TAGLINE, font=tag_f, anchor="ls")
    title_w, title_h = tb[2] - tb[0], -tb[1]   # cap height above baseline (no descenders)
    tag_w, tag_h = gb[2] - gb[0], -gb[1]
    size = 156 * s                              # logo square
    # Logo: its ink is printed straight onto the banner's parchment (luminance -> ink alpha),
    # so the logo's own paper and burnt edge melt away and only the M and a hint of its
    # mottling remain. The crop trims the burnt border; a feathered mask hides any rest.
    # (Mask sizes are in logo-square units: they were tuned on a 260px square.)
    k = size / 260
    src = Image.open(LOGO).convert("RGB")
    c = int(src.width * 0.042)
    logo = src.crop((c, c, src.width - c, src.height - c)).resize((size, size), Image.LANCZOS)
    la = np.array(logo, dtype=np.float32) / 255.0
    lum = la @ np.array([0.30, 0.50, 0.20], np.float32)
    # Ink (~0.16) -> nearly opaque; the logo's darker paper mottling (0.28..0.48) -> a faint
    # stain, faded out well inside the square so no edge shows.
    ink_a = np.clip((0.27 - lum) / (0.27 - 0.17), 0, 1) * 0.94
    stain_a = np.clip((0.50 - lum) / 0.30, 0, 1) * 0.16
    e1, e2 = int(4 * k * s), int(22 * k * s)
    ink_m = rounded_mask(size, size, (e1, e1, size - e1, size - e1), 20 * k * s, blur=3 * k * s)
    stain_m = rounded_mask(size, size, (e2, e2, size - e2, size - e2), 60 * k * s, blur=22 * k * s)
    alpha = np.maximum(ink_a * ink_m, stain_a * stain_m)

    # Lay out by the logo's visible ink, not its square: the square has empty margins.
    ys, xs = np.nonzero(alpha > 0.25)
    vt, vb, vl, vr = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    vis_h = vb - vt
    gap_logo = 26 * s
    gap_rule, gap_tag = 18 * s, 24 * s
    block = vis_h + gap_rule + 2 * s + gap_tag + tag_h + 6 * s  # + tagline descenders ("y", "g")
    top = (h - block) // 2
    group_w = (vr - vl) + gap_logo + title_w
    lx, ly = (w - group_w) // 2 - vl, top - vt
    tx = lx + vr + gap_logo - tb[0]
    base1 = top + vis_h // 2 + title_h // 2
    rule_y = top + vis_h + gap_rule
    base2 = rule_y + 2 * s + gap_tag + tag_h
    region = img[ly:ly + size, lx:lx + size]
    img[ly:ly + size, lx:lx + size] = over(region, INK, alpha)

    out = to_img(img)
    d = ImageDraw.Draw(out)

    # Frame: dark outer edge, then a thin brass rule inset.
    d.rectangle((0, 0, w - 1, h - 1), outline=rgb(BORDER_DARK), width=2 * s)
    d.rectangle((band, band, w - 1 - band, h - 1 - band), outline=rgb(BORDER_DARK, 0.85), width=s)
    inset = band + 5 * s
    d.rectangle((inset, inset, w - 1 - inset, h - 1 - inset), outline=rgb(ACCENT), width=s)

    # Title: ink, with a faint light edge below for a pressed-in look.
    d.text((tx, base1 + 2 * s), TITLE, font=title_f, anchor="ls", fill=rgb((1, 0.95, 0.82), 0.55))
    d.text((tx, base1), TITLE, font=title_f, anchor="ls", fill=rgb(INK))

    # Brass rule, centred, fading out at both ends, with a brass diamond in the middle.
    rule_w = tag_w + 120 * s
    rx = (w - rule_w) // 2
    rule = Image.new("RGBA", (rule_w, 2 * s), rgb(ACCENT) + (255,))
    fade = np.clip((1 - np.abs(np.linspace(-1, 1, rule_w))) * 2.2, 0, 1)
    rule.putalpha(Image.fromarray((np.tile(fade, (2 * s, 1)) * 230).astype(np.uint8)))
    out.paste(rule, (rx, rule_y), rule)
    cx, cy, r = w // 2, rule_y + s, 6 * s
    d.polygon(((cx - r, cy), (cx, cy - r), (cx + r, cy), (cx, cy + r)), fill=rgb(ACCENT))

    d.text((w // 2, base2), TAGLINE, font=tag_f, anchor="ms", fill=rgb(INK_SOFT, 1, 0.80))

    out = out.resize((W * S, H * S), Image.LANCZOS)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.save(OUT, optimize=True)
    optimise(OUT)
    print(f"wrote {os.path.relpath(OUT, ROOT)} ({os.path.getsize(OUT) // 1024} KB)")


def rgb(c, mix=1.0, scale=1.0):
    """0..1 colour -> 0..255 tuple; mix < 1 is not alpha, just a lighter tint toward paper."""
    paper = CONTENT_BG
    return tuple(int(round(255 * (v * scale * mix + p * (1 - mix)))) for v, p in zip(c, paper))


def optimise(path):
    if shutil.which("oxipng"):
        subprocess.run(["oxipng", "-q", "-o", "4", "--strip", "safe", path], check=False)


if __name__ == "__main__":
    build()
