#!/usr/bin/env python3
"""Rebuilds Maines' icons (run from anywhere: python3 tools/make_icons.py).

textures/icons/<name>.tga  - 64x64 full-colour icons on transparent: brass, copper, parchment
                             and enamel gems, gnomish/goblin-engineered, each with a dark outline
                             so it reads on the light parchment tab AND the dark wood strip. The
                             addon draws them at white vertex colour (no tint).
textures/logo.tga          - 64x64 full-colour brass medallion with an ink "M" (minimap / addon list)
textures/icons/preview.png - contact sheet for judging them at 64/32/20 px (dev only, not shipped)

Every shape is a signed distance field in 64-px icon units, painted at 8x (512x512) in
layers (outline, metal or enamel fill, bevel light, facets, gloss) and downsampled with
LANCZOS on premultiplied colour, so edges are clean. No randomness: fully reproducible.
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




# ---------------------------------------------------------------- materials
# Each material is (light, dark): the colour on the lit top-left and on the shaded bottom-right.

OUTLINE = (38, 20, 7)          # the dark rim every icon (and every part) sits in
SEAM = (78, 44, 14)            # thinner, warmer line between parts on the same plate
INK_C = (52, 30, 12)
BRASS = ((255, 228, 146), (150, 94, 32))
GOLD = ((255, 240, 160), (200, 128, 24))
COPPER = ((246, 170, 112), (128, 56, 24))
PARCHMENT = ((255, 248, 222), (218, 186, 128))
WOODM = ((226, 170, 104), (122, 70, 30))
TEAL = ((128, 240, 222), (10, 104, 108))
RED = ((255, 128, 100), (138, 20, 20))
BLUE = ((136, 184, 255), (24, 50, 146))
GREEN = ((170, 238, 120), (36, 116, 40))
CREAM = ((255, 252, 236), (226, 204, 160))

LIGHT_DIR = np.array([-0.62, -0.78])     # towards the light: up and to the left (y grows down)
LIGHT_ANGLE = np.degrees(np.arctan2(LIGHT_DIR[1], LIGHT_DIR[0]))


def lerp(a, b, t):
    a, b = np.asarray(a, float), np.asarray(b, float)
    return a + (b - a) * np.asarray(t)[..., None]


def shade(d, mat, bevel=2.4, bevel_k=0.6, gloss=0.0, inset=False, facets=None, grain=0.0):
    """Colour field for one part: diagonal light-to-dark ramp over the part's own box, a bevel
    (raised, or recessed with inset=True) lit from the top left, optional star facets
    (cx, cy, points, first point angle), a soft gloss spot and faint wood grain."""
    light, dark = mat
    inside = d < 0.5
    xs, ys = PX[inside], PY[inside]
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    w, h = max(x1 - x0, 1e-3), max(y1 - y0, 1e-3)
    t = np.clip(0.38 * (PX - x0) / w + 0.62 * (PY - y0) / h, 0, 1)
    col = lerp(light, dark, t ** 1.1)

    if facets:
        cx, cy, n, a0 = facets
        step = 360.0 / n
        ang = np.degrees(np.arctan2(PY - cy, PX - cx))
        mid = a0 + (np.floor(2 * (ang - a0) / step) + 0.5) * step / 2
        lit = np.cos(np.radians(mid - LIGHT_ANGLE))
        col = lerp(col, lerp(dark, light, 0.5 + 0.5 * lit), 0.75)

    if grain:
        col *= (1 + grain * np.sin(PY * 1.9 + 1.6 * np.sin(PX * 0.21)))[..., None]

    hgt = np.clip(-d / bevel, 0, 1)
    hgt = hgt * (2 - hgt)
    gy, gx = np.gradient(hgt)
    k = SS * bevel / 2
    lit = -(gx * LIGHT_DIR[0] + gy * LIGHT_DIR[1]) * k
    if inset:
        lit = -lit
    col = lerp(col, (255, 250, 228), np.clip(lit, 0, 1) * bevel_k)
    col = lerp(col, np.asarray(dark) * 0.5, np.clip(-lit, 0, 1) * bevel_k)

    if gloss:
        gx0, gy0 = x0 + 0.32 * w, y0 + 0.27 * h
        sig = 0.2 * min(w, h)
        spot = np.exp(-((PX - gx0) ** 2 + (PY - gy0) ** 2) / (2 * sig ** 2))
        col = lerp(col, (255, 255, 245), spot * gloss)
    return col


def gem(cx, cy, r, mat):
    """A round cabochon: radial shading off-centre, a bright catch-light, a reflected glow."""
    light, dark = mat
    u = np.clip(np.hypot(PX - (cx - 0.3 * r), PY - (cy - 0.35 * r)) / (1.45 * r), 0, 1)
    col = lerp(light, dark, u ** 0.9)
    glow = np.exp(-((PX - (cx + 0.35 * r)) ** 2 + (PY - (cy + 0.45 * r)) ** 2) / (2 * (0.3 * r) ** 2))
    col = lerp(col, light, glow * 0.35)
    catch = cover(circle(cx - 0.36 * r, cy - 0.38 * r, 0.3 * r))
    return lerp(col, (255, 255, 250), catch * 0.85)


class Painter:
    """Premultiplied RGBA canvas at working resolution; parts are painted back to front."""

    def __init__(self):
        self.rgb = np.zeros((N, N, 3))
        self.a = np.zeros((N, N))

    def fill(self, cov, col):
        col = np.broadcast_to(np.asarray(col, float), (N, N, 3))
        self.rgb = self.rgb * (1 - cov[..., None]) + col * cov[..., None]
        self.a = self.a * (1 - cov) + cov

    def part(self, d, col, outline=1.2, outline_col=OUTLINE):
        if outline:
            self.fill(cover(d - outline), outline_col)
        self.fill(cover(d), col)

    def image(self):
        """Downsample to 64x64 straight-alpha RGBA (transparent pixels keep the outline colour)."""
        def down(ch):
            return np.asarray(Image.fromarray(ch.astype(np.float32), "F").resize((SIZE, SIZE), Image.LANCZOS))
        a = np.clip(down(self.a), 0, 1)
        rgb = np.dstack([down(self.rgb[..., i]) for i in range(3)])
        safe = np.maximum(a, 1e-6)[..., None]
        rgb = np.where(a[..., None] > 1 / 512, np.clip(rgb / safe, 0, 255), OUTLINE)
        out = np.dstack([rgb, a * 255]).round().astype(np.uint8)
        return Image.fromarray(out, "RGBA")


OL = 2.3   # outer outline width in icon px (~0.7 px at 20 px, ~1.15 px at 32 px)


def silhouette(p, *ds):
    p.fill(cover(union(*ds) - OL), OUTLINE)


# ---------------------------------------------------------------- the eight icons
# Shapes keep the old line-art silhouettes so the tabs stay recognisable; outer extents
# (outline included) stay inside [3.5, 60.5].

def icon_main(p):
    # brass luggage label with a parchment face, an eyelet grommet, a red cord, two ink lines
    body = poly([(7, 25.5), (19, 12.5), (57, 12.5), (57, 51.5), (19, 51.5), (7, 38.5)])
    cord = bezier((19.5, 32), (5.5, 32), (8, 54.5), 40)
    cord_d = union(*[seg(*a, *b) for a, b in zip(cord[:-1], cord[1:])]) - 1.8
    silhouette(p, body, cord_d)
    p.part(body, shade(body, BRASS, gloss=0.25), outline=0)
    face = body + 4.2
    p.part(face, shade(face, PARCHMENT, bevel=1.6, inset=True, bevel_k=0.5), outline=0.9, outline_col=SEAM)
    p.part(line(30, 26.5, 48.5, 26.5, 4.6), lerp(INK_C, INK_C, 0), outline=0)
    p.part(line(30, 37.5, 43, 37.5, 4.6), np.asarray(RED[1]) * 0.9, outline=0)
    ring = circle(19.5, 32, 6.6)
    p.part(ring, shade(ring, BRASS, bevel=2.2, gloss=0.3), outline=1.0)
    p.part(circle(19.5, 32, 3.0), (30, 16, 6), outline=0)
    p.part(cord_d, shade(cord_d, RED, bevel=1.4), outline=1.0)


def icon_phrases(p):
    # brass-rimmed parchment speech bubble holding three enamel gems
    bubble = union(rbox(32, 27.5, 25.5, 19, 11), poly([(15, 38), (28.5, 38), (12, 55.5)]))
    silhouette(p, bubble)
    p.part(bubble, shade(bubble, BRASS, gloss=0.2), outline=0)
    face = bubble + 3.8
    p.part(face, shade(face, PARCHMENT, bevel=1.8, inset=True, bevel_k=0.5), outline=0.9, outline_col=SEAM)
    for x, mat in ((20.5, TEAL), (32, RED), (43.5, BLUE)):
        p.part(circle(x, 27.5, 4.7), gem(x, 27.5, 4.7, mat), outline=1.1)


def icon_animate(p):
    # a faceted gold four-point star, a teal enamel one and a ruby spark
    big = sparkle(26, 35, 20, 3.2) - 1.1
    small = sparkle(47, 17, 10.5, 3.2) - 1.0
    dot = circle(50.5, 40, 3.8)
    silhouette(p, big, small, dot)
    p.part(big, shade(big, GOLD, bevel=1.4, bevel_k=0.3, facets=(26, 35, 4, 0)), outline=0)
    p.part(small, shade(small, TEAL, bevel=1.2, bevel_k=0.3, facets=(47, 17, 4, 0)), outline=0)
    p.part(dot, gem(50.5, 40, 3.8, RED), outline=0)
    p.fill(cover(circle(26, 35, 2.2)) * 0.9, (255, 255, 240))       # the glint in the middle


def icon_badges(p):
    # brass shield with a red enamel field and a faceted gold star
    top, xl, xr, mid = 7 + H, 10.5 + H, 53.5 - H, 26.5
    left = bezier((32, 57.5 - H), (xl, 50), (xl, mid))
    right = bezier((xr, mid), (xr, 50), (32, 57.5 - H))
    shield = poly([(xl, top), (xr, top)] + [tuple(q) for q in right] + [tuple(q) for q in left[1:]]) - H
    silhouette(p, shield)
    p.part(shield, shade(shield, BRASS, bevel=2.2, gloss=0.25), outline=0)
    field = shield + 4.6
    p.part(field, shade(field, RED, bevel=2.0, inset=True, gloss=0.35), outline=0.9, outline_col=SEAM)
    star = star5(32, 30.5, 13, 0.46) - 0.4
    p.part(star, shade(star, GOLD, bevel=1.2, bevel_k=0.3, facets=(32, 30.5, 5, -90)), outline=1.1)


def icon_channels(p):
    # a ruby in a brass socket sending brass (inner) and teal enamel (outer) waves
    w = 5.6
    inner = union(arc(32, 32, 13, -48, 48) - w / 2, arc(32, 32, 13, 132, 228) - w / 2)
    outer = union(arc(32, 32, 23, -45, 45) - w / 2, arc(32, 32, 23, 135, 225) - w / 2)
    socket = circle(32, 32, 6.6)
    silhouette(p, inner, outer, socket)
    p.part(outer, shade(outer, TEAL, bevel=1.8, gloss=0.2), outline=0)
    p.part(inner, shade(inner, BRASS, bevel=1.8, gloss=0.2), outline=0)
    p.part(socket, shade(socket, BRASS, bevel=1.8), outline=0)
    p.part(circle(32, 32, 4.0), gem(32, 32, 4.0, RED), outline=0.9)


def icon_behavior(p):
    # brass toggle switch: recessed green "on" track, a raised brass knob, a cream "on" mark
    pill = rbox(32, 32, 25.5, 16.5, 16.5)
    silhouette(p, pill)
    p.part(pill, shade(pill, BRASS, gloss=0.25), outline=0)
    track = pill + 3.6
    p.part(track, shade(track, GREEN, bevel=2.6, inset=True, bevel_k=0.7, gloss=0.2), outline=0.9, outline_col=SEAM)
    p.part(line(20, 26.5, 20, 37.5, 3.2), shade(line(20, 26.5, 20, 37.5, 3.2), CREAM, bevel=1), outline=0)
    knob = circle(41, 32, 10.2)
    p.part(knob, shade(knob, BRASS, bevel=3.4, bevel_k=0.7, gloss=0.45), outline=1.2)
    p.part(circle(41, 32, 3.4), shade(circle(41, 32, 3.4), BRASS, bevel=1.6, inset=True), outline=0.8,
           outline_col=SEAM)


def icon_cosmetic(p):
    # wooden painter's palette with four glossy paint blobs
    body = poly(ellipse_poly(32, 32, 26, 23))
    body = cut(body, circle(50.5, 46, 8.5))          # thumb notch on the lower right
    silhouette(p, body)
    p.part(body, shade(body, WOODM, bevel=2.6, gloss=0.2, grain=0.045), outline=0)
    for (x, y), mat in (((21, 32), RED), ((28.5, 22.5), GOLD), ((39.5, 22.5), TEAL), ((25.5, 42), BLUE)):
        p.part(circle(x, y, 4.8), gem(x, y, 4.8, mat), outline=1.1)


def icon_help(p):
    # brass coin with a blue enamel face and a cream question mark
    coin = circle(32, 32, 26)
    silhouette(p, coin)
    p.part(coin, shade(coin, BRASS, bevel=2.2, gloss=0.2), outline=0)
    face = circle(32, 32, 21.6)
    p.part(face, shade(face, BLUE, bevel=2.2, inset=True, gloss=0.35), outline=0.9, outline_col=SEAM)
    q = union(arc(32, 25, 6.6, 180, 450) - 3.0, line(32, 31.6, 32, 35.5, 6.0), circle(32, 44.4, 3.7))
    p.part(q, shade(q, CREAM, bevel=1.4, bevel_k=0.45), outline=1.2)


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


def make_icon(fn):
    p = Painter()
    fn(p)
    return p.image()


# ---------------------------------------------------------------- the logo

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
WOOD, CREAM_T = (61, 41, 23), (245, 232, 199)


def make_preview(icons, logo):
    """Each icon on the parchment (selected tab) and dark wood (other tabs) backgrounds, at 64,
    32 and 20 px, plus the 20 px size blown up x3. The wood panel's last row is the dimmed
    (unselected tab) look the addon uses."""
    names = list(icons) + ["logo"]
    icons = dict(icons, logo=logo)
    cell = 80
    rows = [(64, 76, 1.0), (32, 44, 1.0), (20, 32, 1.0), ("zoom", 72, 1.0)]
    panels = [(PARCH, INK, "parchment (selected tab)", rows),
              (WOOD, CREAM_T, "dark wood (other tabs); last row = dimmed unselected tab at 20 px",
               rows + [(20, 32, 0.72)])]
    heights = [sum(r[1] for r in pr) + 38 for *_, pr in panels]
    sheet = Image.new("RGB", (len(names) * cell + 20, sum(heights)), (30, 30, 30))
    draw = ImageDraw.Draw(sheet)
    y0 = 0
    for (bg, fg, label, prows), panel_h in zip(panels, heights):
        draw.rectangle([0, y0, sheet.width, y0 + panel_h - 2], fill=bg)
        draw.text((8, y0 + 4), label + "   (rows: 64, 32, 20 px, 20 px zoomed x3)", fill=fg)
        y = y0 + 20
        for size, h, alpha in prows:
            for i, name in enumerate(names):
                x = 10 + i * cell
                s = 20 if size == "zoom" else size
                ic = icons[name] if s == SIZE else icons[name].resize((s, s), Image.LANCZOS)
                if alpha < 1:
                    ic = ic.copy()
                    ic.putalpha(ic.getchannel("A").point(lambda v: int(v * alpha + 0.5)))
                if size == "zoom":
                    tile = Image.new("RGBA", (s, s), bg + (255,))
                    tile.alpha_composite(ic)
                    tile = tile.resize((s * 3, s * 3), Image.NEAREST)
                    sheet.paste(tile.convert("RGB"), (x + (cell - s * 3) // 2, y + (h - s * 3) // 2))
                else:
                    sheet.paste(ic, (x + (cell - s) // 2, y + (h - s) // 2), ic)
            y += h
        for i, name in enumerate(names):
            draw.text((10 + i * cell + (cell - draw.textlength(name)) // 2, y + 2), name, fill=fg)
        y0 += panel_h
    return sheet


if __name__ == "__main__":
    ICONS.mkdir(parents=True, exist_ok=True)
    icons = {}
    for name, fn in ICON_DEFS.items():
        icons[name] = make_icon(fn)
        icons[name].save(ICONS / f"{name}.tga")
    logo = make_logo()
    logo.save(TEX / "logo.tga")
    make_preview(icons, logo).save(ICONS / "preview.png")
    print("wrote", ", ".join(f"icons/{n}.tga" for n in ICON_DEFS), "logo.tga, icons/preview.png")
