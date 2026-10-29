#!/usr/bin/env python3
"""Rebuilds Maines' icons (run from anywhere: python3 tools/make_icons.py).

textures/icons/<name>.tga  - 64x64 square icons in the style of WoW ability icons (original art):
                             painted brass, parchment, wood, slate and glowing gems over a dark
                             clouded background, lit from the top left with a rim light, inside
                             a dark bevelled iron frame with an inner vignette. The addon draws
                             them untinted (an unselected tab only darkens them to neutral grey).
textures/logo.tga          - 64x64 full-colour brass medallion with an ink "M" (minimap / addon list)
textures/icons/preview.png - contact sheet for judging them at 64/32/20 px (dev only, not shipped)

Every shape is a signed distance field in 64-px icon units, painted at 8x (512x512):
seeded value-noise textures, normals from the shape's rounded edge for lighting, blurred
shadows and bloom, then LANCZOS down to 64 px with a light unsharp mask. All noise uses fixed
seeds, so the output is fully reproducible.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

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




# ---------------------------------------------------------------- noise, blur, colour helpers
# Painted look: every surface gets seeded value-noise texture (metal grain, wood, parchment
# fibre, stone), light comes from the top left with a cool rim light from the bottom right,
# emissive parts bloom, and each icon sits in a dark bevelled square with an inner vignette.

def lerp(a, b, t):
    a, b = np.asarray(a, float), np.asarray(b, float)
    return a + (b - a) * np.asarray(t)[..., None]


def value_noise(seed, gy, gx):
    g = np.random.default_rng(seed).random((max(2, int(gy)), max(2, int(gx)))).astype(np.float32)
    return np.asarray(Image.fromarray(g, "F").resize((N, N), Image.BICUBIC), float)


def fbm(seed, base=4, octaves=5, sy=1.0, sx=1.0):
    """Fractal value noise, roughly 0..1. sy/sx > 1 squeeze the features along that axis
    (sy=6, sx=0.5 gives horizontal brushed streaks)."""
    tot, amp, norm = np.zeros((N, N)), 1.0, 0.0
    for o in range(octaves):
        c = base * 2 ** o
        tot += amp * value_noise(seed * 101 + o, c * sy, c * sx)
        norm += amp
        amp *= 0.55
    return tot / norm


def blur(a, sigma):
    """Gaussian blur, sigma in icon px (FFT, edge-padded)."""
    if a.ndim == 3:
        return np.dstack([blur(a[..., i], sigma) for i in range(a.shape[2])])
    s = sigma * SS
    pad = int(3 * s) + 1
    b = np.pad(a, pad, mode="edge")
    fy = np.fft.fftfreq(b.shape[0])[:, None]
    fx = np.fft.rfftfreq(b.shape[1])[None, :]
    k = np.exp(-2 * (np.pi * s) ** 2 * (fy ** 2 + fx ** 2))
    return np.fft.irfft2(np.fft.rfft2(b) * k, s=b.shape)[pad:-pad, pad:-pad]


def shifted(a, dx, dy):
    return np.roll(np.roll(a, int(round(dy * SS)), axis=0), int(round(dx * SS)), axis=1)


class rotated:
    """with rotated(deg, cx, cy): shapes drawn inside are turned by deg (clockwise on screen)."""

    def __init__(self, deg, cx=32, cy=32):
        self.t, self.c = np.radians(deg), (cx, cy)

    def __enter__(self):
        global PX, PY
        self.saved = PX, PY
        cx, cy = self.c
        c, s = np.cos(self.t), np.sin(self.t)
        dx, dy = PX - cx, PY - cy
        PX, PY = cx + c * dx + s * dy, cy - s * dx + c * dy

    def __exit__(self, *exc):
        global PX, PY
        PX, PY = self.saved


def _n3(*v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


LIGHT = _n3(-0.5, -0.75, 0.75)       # key light: top left, in front (x right, y down, z out)
HALF = _n3(*(LIGHT + (0, 0, 1)))
RIM = _n3(0.7, 0.6, 0.3)             # cool back light from the bottom right


def normals(d, radius):
    """Surface normals of a shape whose edge rounds over `radius` icon px (flat on top)."""
    t = np.clip(-d / radius, 0, 1)
    h = radius * np.sqrt(np.clip(1 - (1 - t) ** 2, 0, 1))
    gy, gx = np.gradient(h)
    n = np.dstack([-gx * SS, -gy * SS, np.ones_like(h)])
    return n / np.linalg.norm(n, axis=2, keepdims=True)


def lit(d, base, radius=4.0, tex=None, tex_amp=0.3, amb=0.3, diff=0.95, spec=0.35, shin=22,
        spec_col=(255, 246, 220), rim_col=(120, 170, 255), rim=0.35, dome=None):
    """Lit colour field for one part. dome=(cx, cy, r) uses a sphere normal instead (gems, knobs)."""
    if dome:
        cx, cy, r = dome
        dx, dy = (PX - cx) / r, (PY - cy) / r
        dz = np.sqrt(np.clip(1 - dx * dx - dy * dy, 0.02, 1))
        n = np.dstack([dx, dy, dz])
        n /= np.linalg.norm(n, axis=2, keepdims=True)
    else:
        n = normals(d, radius)
    base = np.broadcast_to(np.asarray(base, float), (N, N, 3))
    if tex is not None:
        base = base * (1 + tex_amp * (tex - 0.5) * 2)[..., None]
    ndl = np.clip(n @ LIGHT, 0, 1)
    fall = np.clip(1.22 - 0.4 * (PX + PY) / 64, 0.66, 1.25)      # whole-icon light falloff
    col = base * ((amb + diff * ndl) * fall)[..., None]
    col = col + (np.clip(n @ HALF, 0, 1) ** shin * spec)[..., None] * np.asarray(spec_col, float)
    rl = np.clip(n @ RIM, 0, 1) ** 2 * (1 - n[..., 2]) ** 0.5
    return col + (rl * rim)[..., None] * np.asarray(rim_col, float)


class Painter:
    """Straight RGB (0..255) over a full-bleed square; parts are painted back to front."""

    def __init__(self, bg_light, bg_dark, seed, centre=(26, 24)):
        r = np.hypot(PX - centre[0], PY - centre[1]) / 46
        clouds = fbm(seed, 2, 5)
        streaks = fbm(seed + 5, 3, 4, sy=0.6, sx=2.2)
        t = np.clip(r ** 1.15 + (clouds - 0.5) * 0.7, 0, 1)
        self.rgb = lerp(bg_light, bg_dark, t) * (0.88 + 0.3 * (streaks - 0.5))[..., None]
        self.a = cover(rbox(32, 32, 32, 32, 3.5))

    def fill(self, cov, col, k=1.0):
        cov = cov * k
        col = np.broadcast_to(np.asarray(col, float), (N, N, 3))
        self.rgb = self.rgb * (1 - cov[..., None]) + col * cov[..., None]

    def shadow(self, d, dx=1.8, dy=2.6, sigma=2.2, k=0.7):
        m = shifted(blur(cover(d), sigma), dx, dy)
        self.rgb = self.rgb * (1 - k * np.clip(m, 0, 1))[..., None]

    def glow(self, d, col, sigma=4.0, k=0.9):
        m = blur(cover(d), sigma)
        self.rgb = self.rgb + (np.clip(m, 0, 1) * k)[..., None] * np.asarray(col, float)

    def part(self, d, col, edge=0.9, edge_col=(14, 9, 6), edge_k=0.85):
        """A painted part with a soft dark contact edge round it."""
        if edge:
            self.fill(cover(d - edge), edge_col, edge_k)
        self.fill(cover(d), col)

    def frame(self):
        sq = rbox(32, 32, 32, 32, 3.5)
        depth = np.clip(-sq, 0, None)
        vig = np.exp(-np.clip(depth - 3.0, 0, None) / 6.5)
        self.rgb *= (1 - 0.5 * vig)[..., None]
        # bevelled iron edge: top/left lit, bottom/right in shade
        gy, gx = np.gradient(sq)
        nrm = np.hypot(gx, gy) + 1e-9
        litk = (gx * -0.6 + gy * -0.8) / nrm
        band = cover(np.maximum(sq, -sq - 3.0))
        iron = lerp((40, 34, 30), (120, 104, 84), np.clip(0.5 + 0.55 * litk, 0, 1))
        self.fill(band, iron)
        self.fill(cover(np.abs(sq + 3.0) - 0.45), (8, 6, 5), 0.9)          # inner dark seam
        self.fill(cover(np.abs(sq + 0.45) - 0.45), (6, 4, 3), 0.95)        # outer black line

    def image(self):
        rgb = np.clip(self.rgb, 0, 255)
        lum = rgb @ np.array([0.3, 0.59, 0.11])
        rgb = lerp(lum[..., None] * np.ones(3), rgb, 0.94)                # a touch desaturated
        rgb = np.clip((rgb - 128) * 1.06 + 128, 0, 255)                      # and a touch of contrast

        def down(ch):
            return np.asarray(Image.fromarray(ch.astype(np.float32), "F").resize((SIZE, SIZE), Image.LANCZOS))
        a = np.clip(down(self.a), 0, 1)
        out = np.dstack([np.clip(down(rgb[..., i] * self.a) / np.maximum(a, 1e-6), 0, 255) for i in range(3)])
        out[a < 1 / 512] = (6, 4, 3)
        img = Image.fromarray(np.dstack([out, a * 255]).round().astype(np.uint8), "RGBA")
        sharp = img.convert("RGB").filter(ImageFilter.UnsharpMask(radius=0.8, percent=45, threshold=0))
        sharp.putalpha(img.getchannel("A"))
        return sharp


# ---------------------------------------------------------------- materials (rich, a little muted)

BRASS = (200, 152, 70)
GOLD = (236, 184, 72)
COPPER = (178, 98, 54)
IRON = (96, 92, 96)
PARCH = (252, 216, 146)
WOOD = (196, 128, 66)
RED = (168, 34, 28)
SLATE = (104, 118, 140)


def brushed(seed):
    return fbm(seed, 3, 4, sy=6, sx=0.4)


def grain(seed, base=6):
    return fbm(seed, base, 4)


def gem(p, cx, cy, r, col, glow=0.0, edge=0.8):
    d = circle(cx, cy, r)
    if glow:
        p.glow(d, col, sigma=r * 0.9, k=glow)
    p.part(d, lit(d, col, dome=(cx, cy, r), spec=0.9, shin=40, amb=0.35, rim=0.5,
                  rim_col=np.asarray(col) * 1.2), edge=edge)
    p.fill(cover(circle(cx - 0.38 * r, cy - 0.42 * r, 0.26 * r)), (255, 255, 248), 0.85)


def rivet(p, cx, cy, r=1.7):
    gem(p, cx, cy, r, BRASS, edge=0.6)


# ---------------------------------------------------------------- the eight icons
# 64-px square icons, the subject painted large inside a 3-px iron frame.

def icon_main(p):
    # an aged parchment name tag on a red cord, brass-capped and grommeted
    with rotated(-12):
        body = poly([(8, 25), (20, 13), (57, 13), (57, 51), (20, 51), (8, 39)])
        caps = union(circle(51.5, 18.5, 2.0), circle(51.5, 45.5, 2.0))
        lines = union(line(29, 25.5, 49, 25.5, 3.6), line(29, 33, 46, 33, 3.0), line(29, 40.5, 40, 40.5, 3.0))
        ring = np.abs(circle(20.5, 32, 4.9)) - 1.9
        hole = circle(20.5, 32, 2.9)
    cord_pts = bezier((20.5 - 1.5, 32.5), (4, 30), (9, -2), 40)
    cord = union(*[seg(*a, *b) for a, b in zip(cord_pts[:-1], cord_pts[1:])]) - 2.1
    p.shadow(body)
    fib = fbm(11, 5, 4, sy=3, sx=0.8)
    p.part(body, lit(body, PARCH, radius=3.0, tex=fib, tex_amp=0.22, spec=0.15, amb=0.45, rim_col=(255, 120, 80), rim=0.25))
    # burnt edge: darken toward the rim
    p.fill(cover(np.abs(body + 1.2) - 1.3), (120, 70, 30), 0.35)
    ink = (50, 26, 14)
    p.fill(cover(lines) * (0.75 + 0.25 * fbm(12, 8, 3)), ink)
    for cx, cy in ((51.5, 18.5), (51.5, 45.5)):
        with rotated(-12):
            c = circle(cx, cy, 2.0)
            p.part(c, lit(c, BRASS, radius=2.0, spec=0.8, shin=30), edge=0.6)
    p.part(ring, lit(ring, BRASS, radius=1.8, tex=brushed(13), tex_amp=0.2, spec=0.9, shin=30), edge=0.7)
    p.fill(cover(hole), (18, 10, 6))
    p.shadow(cord, 1.2, 1.6, 1.4, 0.5)
    p.part(cord, lit(cord, RED, radius=2.1, tex=fbm(14, 4, 3, sy=4, sx=4), tex_amp=0.35, spec=0.4,
                     rim_col=(255, 140, 90), rim=0.4), edge=0.7)


def icon_phrases(p):
    # a brass-rimmed parchment speech bubble with three glowing arcane gems
    bubble = union(rbox(32, 27.5, 27, 20, 12.5), poly([(13, 40), (29, 40), (9, 59)]))
    face = bubble + 3.4
    p.shadow(bubble)
    p.part(bubble, lit(bubble, BRASS, radius=3.0, tex=brushed(21), tex_amp=0.25, spec=0.7, shin=26))
    p.part(face, lit(face, PARCH, radius=5.0, tex=fbm(22, 5, 4, sy=2.5, sx=1), tex_amp=0.2, spec=0.12, amb=0.45,
                     rim=0.15), edge=0.7, edge_col=(60, 34, 12))
    for x in (20, 32, 44):
        gem(p, x, 27.5, 5.0, (40, 190, 200), glow=0.55)


def icon_animate(p):
    # arcane sparkles: a blazing four-point star, two small ones and a drift of motes
    rng = np.random.default_rng(31)
    p.glow(circle(30, 34, 12), (130, 60, 230), sigma=8, k=0.4)
    ring = np.abs(circle(31, 33, 22)) - 0.45
    p.fill(cover(ring) * (0.3 + 0.7 * fbm(32, 3, 3)), (170, 120, 255), 0.35)
    stars = [(30, 34, 22, 3.0), (50, 14, 9.5, 3.0), (13, 15, 5.5, 2.8), (51, 50, 5.0, 2.8)]
    for cx, cy, r, k in stars:
        s = sparkle(cx, cy, r, k) - 0.8
        p.glow(s, (160, 90, 255), sigma=r * 0.12 + 0.8, k=0.55)
        p.fill(cover(s - 0.8), (40, 10, 70), 0.75)
        core = np.clip(np.hypot(PX - cx, PY - cy) / (r * 0.8), 0, 1)
        p.fill(cover(s), lerp((255, 255, 255), (150, 80, 250), core ** 0.55))
    for _ in range(18):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(14, 27)
        x, y = 31 + rr * np.cos(a), 33 + rr * np.sin(a) * 0.85
        s = rng.uniform(0.5, 1.2)
        d = circle(x, y, s)
        p.glow(d, (200, 160, 255), sigma=1.6, k=0.8)
        p.fill(cover(d), (255, 240, 255))


def icon_badges(p):
    # a heraldic shield: riveted brass rim, red enamel field, a golden faceted star
    top, xl, xr, mid, bot = 7.5, 10, 54, 27, 58.5
    left = bezier((32, bot), (xl, 51), (xl, mid))
    right = bezier((xr, mid), (xr, 51), (32, bot))
    shield = poly([(xl, top), (xr, top)] + [tuple(q) for q in right] + [tuple(q) for q in left[1:]]) - 0.5
    field = shield + 4.4
    p.shadow(shield)
    p.part(shield, lit(shield, BRASS, radius=3.0, tex=brushed(41), tex_amp=0.25, spec=0.7, shin=26))
    p.part(field, lit(field, RED, radius=2.5, tex=grain(42, 5), tex_amp=0.25, spec=0.35, shin=16,
                      rim_col=(255, 120, 90), rim=0.3), edge=0.8)
    for x, y in ((13.5, 11), (50.5, 11), (12.5, 30), (51.5, 30), (32, 55.5)):
        rivet(p, x, y, 1.5)
    star = star5(32, 30.5, 14, 0.45) - 0.4
    p.glow(star, (255, 190, 80), sigma=3.0, k=0.35)
    ang = np.degrees(np.arctan2(PY - 30.5, PX - 32))
    mid_a = -90 + (np.floor(2 * (ang + 90) / 72) + 0.5) * 36
    face = 0.5 + 0.5 * np.cos(np.radians(mid_a - 225))
    p.part(star, lerp((140, 80, 20), (255, 236, 150), face) * (0.92 + 0.16 * grain(43, 8))[..., None], edge=0.8)


def icon_channels(p):
    # a glowing teal crystal in a brass claw, broadcasting rings of light
    teal = (60, 220, 210)
    for r, a in ((13.5, 42), (22.5, 40)):
        w = union(arc(32, 30, r, -a, a) - 1.8, arc(32, 30, r, 180 - a, 180 + a) - 1.8)
        p.glow(w, teal, sigma=2.6, k=0.9)
        p.fill(cover(w), (190, 255, 245))
    crystal = poly([(32, 10), (39.5, 22), (38, 42), (32, 50), (26, 42), (24.5, 22)])
    base = union(rbox(32, 53, 11, 4, 2), poly([(23, 50), (27, 41), (29, 50)]), poly([(41, 50), (37, 41), (35, 50)]))
    p.glow(crystal, teal, sigma=6, k=0.6)
    p.shadow(base)
    p.part(base, lit(base, BRASS, radius=2.5, tex=brushed(51), tex_amp=0.25, spec=0.8, shin=26))
    # crystal facets: lit left face, dark right face, bright ridge, glowing core
    left = PX < 32 + (PY - 30) * 0.0
    face = np.where(left, 1.0, 0.45) * np.clip(1.15 - (PY - 10) / 60, 0.6, 1.2)
    col = lerp((10, 90, 100), (120, 250, 235), face)
    core = np.exp(-((PX - 31) ** 2 / 18 + (PY - 30) ** 2 / 90))
    col = lerp(col, (230, 255, 250), core * 0.7)
    p.part(crystal, col, edge=0.8)
    p.fill(cover(line(32, 11, 32, 49, 0.9)), (230, 255, 250), 0.7)
    p.fill(cover(union(line(24.8, 22.5, 32, 25, 0.7), line(39.2, 22.5, 32, 25, 0.7))), (220, 255, 250), 0.6)
    p.fill(cover(circle(28.5, 18, 1.5)), (255, 255, 255), 0.9)


def icon_behavior(p):
    # a gnomish lever on a riveted iron plate, red knob, green "on" lamp
    plate = rbox(32, 42, 24, 14, 4)
    slot = rbox(32, 42, 13, 2.6, 2.6)
    p.shadow(plate)
    p.part(plate, lit(plate, IRON, radius=2.5, tex=brushed(61), tex_amp=0.35, spec=0.5, shin=20))
    for x, y in ((12, 32), (52, 32), (12, 52), (52, 52)):
        rivet(p, x, y, 1.8)
    p.fill(cover(slot), (12, 10, 10))
    p.fill(cover(np.abs(slot + 0.2) - 0.4) * (PY > 42), (150, 140, 130), 0.5)
    arm = line(33, 42, 46, 15, 4.6)
    p.shadow(arm, 2.2, 2.4, 1.6, 0.6)
    p.part(arm, lit(arm, (190, 186, 180), radius=2.3, tex=brushed(62), tex_amp=0.2, spec=0.9, shin=30), edge=0.7)
    hub = circle(33, 42, 5.4)
    p.part(hub, lit(hub, BRASS, dome=(33, 42, 5.4), spec=0.9, shin=30), edge=0.8)
    gem(p, 46, 14, 7.2, RED)
    gem(p, 17, 41.5, 3.0, (70, 230, 90), glow=0.8, edge=0.7)


def icon_cosmetic(p):
    # a painter's palette of grained wood with glossy paint, and a brush
    with rotated(-14, 32, 34):
        pal = poly(ellipse_poly(31, 35, 26, 20.5))
        pal = cut(pal, circle(52, 47, 8))
        thumb = circle(20, 43, 3.6)
        wood = fbm(71, 2, 4, sy=0.4, sx=5)
    pal = cut(pal, thumb)
    p.shadow(pal)
    p.part(pal, lit(pal, WOOD, radius=3.2, tex=wood, tex_amp=0.4, spec=0.3, shin=18, rim_col=(255, 150, 120)))
    blobs = [((18, 31), (178, 30, 26)), ((27, 22.5), (236, 182, 52)), ((39, 20.5), (40, 110, 200)),
             ((45, 32), (60, 160, 70)), ((31, 42.5), (236, 230, 214))]
    for (x, y), c in blobs:
        d = circle(x, y, 4.6) + 0.8 * (fbm(72 + int(x), 6, 2) - 0.5)
        p.part(d, lit(d, c, radius=2.6, spec=0.9, shin=34, rim=0.3), edge=0.6, edge_k=0.6)
    handle = line(61, 61, 47, 45, 4.2)
    ferrule = line(47, 45, 42.5, 39.5, 4.6)
    tip = union(line(42.5, 39.5, 39, 35.5, 3.8), circle(38, 34.3, 1.6))
    p.shadow(union(handle, ferrule, tip), 1.6, 2.0, 1.4, 0.6)
    p.part(handle, lit(handle, (120, 30, 30), radius=2.1, spec=0.7, shin=30), edge=0.6)
    p.part(ferrule, lit(ferrule, BRASS, radius=2.3, spec=0.9, shin=30), edge=0.6)
    p.part(tip, lit(tip, (40, 110, 200), radius=1.8, spec=0.6, shin=30), edge=0.6)


def icon_help(p):
    # a slate rune stone with a carved question mark burning gold
    stone = circle(32, 33, 25) + 1.6 * (fbm(81, 2, 3) - 0.5) * 2
    q = union(arc(32, 25.5, 7.4, 180, 450) - 3.0, line(32, 32.8, 32, 37.5, 6.0), circle(32, 46.5, 3.7))
    p.shadow(stone)
    p.part(stone, lit(stone, SLATE, radius=5.0, tex=fbm(82, 4, 5), tex_amp=0.5, spec=0.2, shin=12,
                      rim_col=(110, 150, 255), rim=0.45))
    p.fill(cover(np.abs(circle(32, 33, 19.5)) - 0.5) * (0.5 + 0.5 * fbm(83, 4, 3)), (20, 20, 28), 0.6)
    p.fill(cover(shifted(q, -0.9, -0.9) - 0.9), (14, 12, 16), 0.9)               # carved groove
    p.glow(q, (255, 160, 40), sigma=3.5, k=0.95)
    heat = np.clip((PY - 18) / 32, 0, 1)
    p.fill(cover(q), lerp((255, 248, 200), (255, 150, 40), heat))


ICON_DEFS = {
    "main": (icon_main, (150, 46, 36), (24, 6, 6), 1),
    "phrases": (icon_phrases, (54, 104, 132), (8, 16, 26), 2),
    "animate": (icon_animate, (96, 50, 160), (12, 4, 28), 3),
    "badges": (icon_badges, (56, 78, 140), (8, 10, 28), 4),
    "channels": (icon_channels, (30, 96, 96), (4, 14, 18), 5),
    "behavior": (icon_behavior, (110, 92, 70), (16, 13, 10), 6),
    "cosmetic": (icon_cosmetic, (150, 66, 110), (22, 8, 18), 7),
    "help": (icon_help, (60, 58, 140), (6, 6, 22), 8),
}


def make_icon(spec):
    fn, light, dark, seed = spec
    p = Painter(light, dark, seed)
    fn(p)
    p.frame()
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
                if alpha < 1:      # dimmed like an unselected tab: neutral vertex colour
                    a = ic.getchannel("A")
                    ic = ic.convert("RGB").point(lambda v: int(v * alpha + 0.5))
                    ic.putalpha(a)
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
