#!/usr/bin/env python3
"""Rebuilds Maines' icons (run from anywhere: python3 tools/make_icons.py).

textures/icons/<name>.tga  - 64x64 white line-art icons on transparent; the addon tints them
                             with SetVertexColor (ink on parchment, cream on dark wood)
textures/logo.tga          - 64x64 full-colour brass medallion with an ink "M" (minimap / addon list)
textures/icons/preview.png - contact sheet for judging them at 64/32/20 px (dev only, not shipped)

Every shape is a signed distance field in 64-px icon units, rendered at 8x (512x512)
and downsampled with LANCZOS, so edges are clean and the output is fully reproducible.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
TEX = ROOT / "textures"
ICONS = TEX / "icons"

SIZE = 64          # final size
SS = 8             # supersampling factor
N = SIZE * SS      # 512 working canvas
W = 6.5            # main stroke weight in icon px (~10% of 64)
H = W / 2

# pixel-centre coordinates in icon units
PY, PX = (np.mgrid[0:N, 0:N] + 0.5) / SS


# ---------------------------------------------------------------- distance primitives
# All return signed distance in icon px: negative inside, positive outside.

def circle(cx, cy, r):
    return np.hypot(PX - cx, PY - cy) - r


def rbox(cx, cy, hw, hh, r):
    qx = np.abs(PX - cx) - hw + r
    qy = np.abs(PY - cy) - hh + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def seg(ax, ay, bx, by):
    """Unsigned distance to a line segment (stroke it with `stroke`)."""
    ex, ey = bx - ax, by - ay
    wx, wy = PX - ax, PY - ay
    t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
    return np.hypot(wx - ex * t, wy - ey * t)


def arc(cx, cy, r, a0, a1):
    """Unsigned distance to a circular arc from a0 to a1 degrees (screen angles: 0 = right, 90 = down)."""
    dx, dy = PX - cx, PY - cy
    rel = (np.degrees(np.arctan2(dy, dx)) - a0) % 360
    ring = np.abs(np.hypot(dx, dy) - r)
    ends = []
    for a in (a0, a1):
        ex, ey = cx + r * np.cos(np.radians(a)), cy + r * np.sin(np.radians(a))
        ends.append(np.hypot(PX - ex, PY - ey))
    return np.where(rel <= (a1 - a0), ring, np.minimum(*ends))


def poly(pts):
    """Exact signed distance to a closed polygon."""
    pts = np.asarray(pts, float)
    d = (PX - pts[0, 0]) ** 2 + (PY - pts[0, 1]) ** 2
    s = np.ones_like(PX)
    for i in range(len(pts)):
        vi, vj = pts[i], pts[i - 1]
        ex, ey = vj - vi
        wx, wy = PX - vi[0], PY - vi[1]
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0, 1)
        d = np.minimum(d, (wx - ex * t) ** 2 + (wy - ey * t) ** 2)
        c1, c2, c3 = PY >= vi[1], PY < vj[1], ex * wy > ey * wx
        s = np.where((c1 & c2 & c3) | (~c1 & ~c2 & ~c3), -s, s)
    return s * np.sqrt(d)


def sparkle(cx, cy, r, k=2.4, n=240):
    """Four-point star with concave curved sides (a fattened astroid)."""
    t = np.linspace(0, 2 * np.pi, n, endpoint=False)
    c, s = np.cos(t), np.sin(t)
    return poly(np.c_[cx + r * np.sign(c) * np.abs(c) ** k, cy + r * np.sign(s) * np.abs(s) ** k])


def star5(cx, cy, r, inner=0.48):
    pts = []
    for i in range(10):
        a = np.radians(-90 + i * 36)
        rr = r if i % 2 == 0 else r * inner
        pts.append((cx + rr * np.cos(a), cy + rr * np.sin(a)))
    return poly(pts)


def ellipse_poly(cx, cy, a, b, n=180):
    t = np.linspace(0, 2 * np.pi, n, endpoint=False)
    return np.c_[cx + a * np.cos(t), cy + b * np.sin(t)]


def bezier(p0, p1, p2, n=24):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2 = map(np.asarray, (p0, p1, p2))
    return (1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t ** 2 * p2


def union(*ds):
    return np.minimum.reduce(ds)


def cut(a, b):
    return np.maximum(a, -b)


def stroke(d, w=W):
    return np.abs(d) - w / 2


def line(ax, ay, bx, by, w=W):
    return seg(ax, ay, bx, by) - w / 2


def cover(d):
    """Antialiased coverage (0..1) of a signed distance field at working resolution."""
    return np.clip(0.5 - d * SS, 0, 1)


# ---------------------------------------------------------------- the eight icons
# Outer extents stay inside [6, 58] (6 px transparent padding at 64 px).

def icon_main():
    # luggage label: clipped corners at the left, an eyelet, two lines of "name"
    x0, x1, y0, y1 = 6 + H, 58 - H, 12 + H, 52 - H
    body = poly([(x0, 25.5), (19, y0), (x1, y0), (x1, y1), (19, y1), (x0, 38.5)])
    return union(stroke(body),
                 circle(19.5, 32, 4.2),
                 line(29.5, 26.5, 46.5, 26.5, 5.5),
                 line(29.5, 37.5, 41.5, 37.5, 5.5))


def icon_phrases():
    bubble = union(rbox(32, 27.5, 26 - H, 19.5 - H, 11),
                   poly([(15, 38), (28, 38), (12.5, 55)]))
    return union(stroke(bubble), circle(20.5, 27.5, 4), circle(32, 27.5, 4), circle(43.5, 27.5, 4))


def icon_animate():
    return union(sparkle(26, 35, 20, 3.2) - 0.9,
                 sparkle(47, 17, 10.2, 3.2) - 0.9,
                 circle(50.5, 39, 3.2))


def icon_badges():
    top, xl, xr, mid = 7 + H, 10.5 + H, 53.5 - H, 26.5
    left = bezier((32, 57.5 - H), (xl, 50), (xl, mid))
    right = bezier((xr, mid), (xr, 50), (32, 57.5 - H))
    shield = poly([(xl, top), (xr, top)] + [tuple(p) for p in right] + [tuple(p) for p in left[1:]])
    return union(stroke(shield), star5(32, 30, 12, 0.46) - 0.6)


def icon_channels():
    w = 6.0
    return union(circle(32, 32, 5.2),
                 arc(32, 32, 12.5, -48, 48) - w / 2, arc(32, 32, 12.5, 132, 228) - w / 2,
                 arc(32, 32, 22.5, -45, 45) - w / 2, arc(32, 32, 22.5, 135, 225) - w / 2)


def icon_behavior():
    pill = rbox(32, 32, 26 - H, 17 - H, 17 - H)
    return union(stroke(pill), circle(41, 32, 7.2))


def icon_cosmetic():
    body = poly(ellipse_poly(32, 32, 26 - H, 23 - H))
    body = cut(body, circle(50.5, 46, 8.5))          # thumb notch on the lower right
    return union(stroke(body),
                 circle(21, 32, 4), circle(28.5, 23, 4), circle(39.5, 23, 4), circle(25, 41.5, 4))


def icon_help():
    return union(stroke(circle(32, 32, 26 - H)),
                 arc(32, 25, 6.6, 180, 450) - 2.9,
                 line(32, 31.6, 32, 35.5, 5.8),
                 circle(32, 44.2, 3.6))


ICON_DEFS = {
    "main": icon_main,
    "phrases": icon_phrases,
    "animate": icon_animate,
    "badges": icon_badges,
    "channels": icon_channels,
    "behavior": icon_behavior,
    "cosmetic": icon_cosmetic,
    "help": icon_help,
}


def downsample_alpha(a):
    big = Image.fromarray((a * 255 + 0.5).astype(np.uint8), "L")
    return big.resize((SIZE, SIZE), Image.LANCZOS)


def save_white(alpha, path):
    img = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    img.putalpha(alpha)
    img.save(path)


# ---------------------------------------------------------------- the logo

def lerp(a, b, t):
    a, b = np.asarray(a, float), np.asarray(b, float)
    return a + (b - a) * np.asarray(t)[..., None]


def make_logo():
    cx = cy = 32
    R = 30.6
    r = np.hypot(PX - cx, PY - cy)
    diag = np.clip(((PX - cx) + (PY - cy)) / (2 * R) + 0.5, 0, 1)   # 0 top-left .. 1 bottom-right

    # face: warm brass, lit from the top left, with faint lathe rings
    col = lerp((246, 214, 132), (168, 114, 46), diag ** 0.9)
    hl = np.exp(-((PX - 22) ** 2 + (PY - 19) ** 2) / (2 * 11 ** 2))
    col = lerp(col, (255, 242, 196), hl * 0.45)
    col *= (1 + 0.035 * np.sin(r * 2.6))[..., None]

    def paint(mask, c, opacity=1.0):
        nonlocal col
        col = lerp(col, c, mask * opacity)

    # rim: darker brass, lit the opposite way so it reads as a raised bevel
    rim = cover(np.maximum(r - R, 26.6 - r))
    rim_col = lerp((118, 74, 26), (214, 166, 84), diag)
    col = col * (1 - rim[..., None]) + rim_col * rim[..., None]
    # inner bevel: dark groove where the rim meets the face, light lip just inside
    groove_dark = cover(np.abs(r - 26.6) - 0.55)
    paint(groove_dark, (70, 40, 14), 0.85)
    lip = cover(np.abs(r - 25.6) - 0.45) * np.clip(diag * 1.6 - 0.3, 0, 1)
    paint(lip, (255, 236, 170), 0.6)
    # bright catch-light on the rim's top-left edge, dark outline all round
    catch = cover(np.abs(r - 29.4) - 0.4) * np.clip(1.2 - diag * 2.2, 0, 1)
    paint(catch, (255, 240, 190), 0.7)
    paint(cover(np.abs(r - R + 0.45) - 0.55), (52, 30, 10), 0.9)

    # thin engraved ring: dark cut with a light edge below it
    paint(cover(np.abs(r - 22.9) - 0.42), (255, 236, 176), 0.45 * 1)
    paint(cover(np.abs(r - 22.4) - 0.45), (84, 50, 16), 0.75)

    # the M: bold slab-serif monogram in dark ink, with a letterpress highlight below-right
    def m_shape(ox=0.0, oy=0.0):
        global PX, PY
        PX, PY = PX - ox, PY - oy
        try:
            t, b = 20.0, 44.0
            body = poly([(19.5, b), (19.5, t), (26.4, t), (32, 31.2), (37.6, t), (44.5, t),
                         (44.5, b), (38.6, b), (38.6, 29.0), (33.9, 38.4), (30.1, 38.4),
                         (25.4, 29.0), (25.4, b)])
            serifs = union(rbox(22.5, b - 1.2, 6.0, 1.2, 0.4), rbox(41.5, b - 1.2, 6.0, 1.2, 0.4),
                           rbox(21.4, t + 1.2, 4.9, 1.2, 0.4), rbox(42.6, t + 1.2, 4.9, 1.2, 0.4))
            return union(body, serifs) - 0.25
        finally:
            PX, PY = PX + ox, PY + oy

    paint(cover(m_shape(0.75, 0.75)), (255, 238, 180), 0.55)
    paint(cover(m_shape()), (46, 26, 9))

    alpha = cover(r - R)
    rgba = np.dstack([np.clip(col, 0, 255), alpha * 255]).astype(np.uint8)
    # give transparent pixels the edge colour so nothing dark bleeds in when scaled
    rgba[alpha == 0, :3] = (52, 30, 10)
    return Image.fromarray(rgba, "RGBA").resize((SIZE, SIZE), Image.LANCZOS)


# ---------------------------------------------------------------- preview sheet

PARCH, INK = (204, 173, 117), (36, 20, 8)
WOOD, CREAM = (61, 41, 23), (245, 232, 199)


def tinted(alpha, tint, size):
    a = alpha.resize((size, size), Image.LANCZOS) if size != SIZE else alpha
    img = Image.new("RGBA", (size, size), tint + (0,))
    img.putalpha(a)
    return img


def make_preview(alphas, logo):
    names = list(alphas) + ["logo"]
    cell = 80
    rows = [(64, 76), (32, 44), (20, 32), ("zoom", 72)]
    panel_h = sum(h for _, h in rows) + 38
    sheet = Image.new("RGB", (len(names) * cell + 20, panel_h * 2), (30, 30, 30))
    draw = ImageDraw.Draw(sheet)
    for p, (bg, tint, label) in enumerate([(PARCH, INK, "parchment / ink"), (WOOD, CREAM, "dark wood / cream")]):
        y0 = p * panel_h
        draw.rectangle([0, y0, sheet.width, y0 + panel_h - 2], fill=bg)
        draw.text((8, y0 + 4), label + "   (rows: 64, 32, 20 px, 20 px zoomed x3)", fill=tint)
        y = y0 + 20
        for size, h in rows:
            for i, name in enumerate(names):
                x = 10 + i * cell
                s = 20 if size == "zoom" else size
                if name == "logo":
                    ic = logo if s == SIZE else logo.resize((s, s), Image.LANCZOS)
                else:
                    ic = tinted(alphas[name], tint, s)
                if size == "zoom":
                    tile = Image.new("RGBA", (s, s), bg + (255,))
                    tile.alpha_composite(ic)
                    tile = tile.resize((s * 3, s * 3), Image.NEAREST)
                    sheet.paste(tile.convert("RGB"), (x + (cell - s * 3) // 2, y + (h - s * 3) // 2))
                else:
                    sheet.paste(ic, (x + (cell - s) // 2, y + (h - s) // 2), ic)
            y += h
        for i, name in enumerate(names):
            draw.text((10 + i * cell + (cell - draw.textlength(name)) // 2, y + 2), name, fill=tint)
    return sheet


if __name__ == "__main__":
    ICONS.mkdir(parents=True, exist_ok=True)
    alphas = {}
    for name, fn in ICON_DEFS.items():
        alphas[name] = downsample_alpha(cover(fn()))
        save_white(alphas[name], ICONS / f"{name}.tga")
    logo = make_logo()
    logo.save(TEX / "logo.tga")
    make_preview(alphas, logo).save(ICONS / "preview.png")
    print("wrote", ", ".join(f"icons/{n}.tga" for n in ICON_DEFS), "logo.tga, icons/preview.png")
