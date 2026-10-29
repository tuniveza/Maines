#!/usr/bin/env python3
"""Rebuilds Maines' icons (run from anywhere: python3 tools/make_icons.py).

textures/icons/<name>.tga  - 128x128 cut-out icons on transparent, painted in the manner of WoW
                             ability icons (original art): brass, parchment, wood, slate and
                             glowing gems, lit from the top left with a rim light and bloom, a
                             dark outline and a soft drop shadow so each reads on parchment and
                             on any tab-bar colour. The addon draws them untinted (an unselected
                             tab only desaturates and dims them a little).
textures/logo.tga          - 64x64 full-colour brass medallion with an ink "M" (minimap / addon list)
textures/icons/preview.png - contact sheet at 64/30/20 px on parchment, wood and a coloured bar
                             (dev only, not shipped)

Every shape is a signed distance field in 64-unit icon space, painted at 512x512: seeded
value-noise textures, normals from the shape's rounded edge for lighting, blurred shadows and
bloom, then LANCZOS down to 128 px with a light unsharp mask. All noise uses fixed seeds, so
the output is fully reproducible.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
TEX = ROOT / "textures"
ICONS = TEX / "icons"

SIZE = 64          # design space (and the logo's size); icons are written at ICON_OUT
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


ICON_OUT = 128     # icon textures are 128x128 (designed in 64-unit space, 4x supersampled)
OUTLINE = (20, 12, 7)
OL = 1.7           # dark outline round each icon's silhouette, in 64-unit px


class Painter:
    """Premultiplied RGBA on a transparent canvas; parts are painted back to front."""

    def __init__(self):
        self.rgb = np.zeros((N, N, 3))
        self.a = np.zeros((N, N))

    def fill(self, cov, col, k=1.0):
        cov = np.clip(cov * k, 0, 1)
        col = np.broadcast_to(np.asarray(col, float), (N, N, 3))
        self.rgb = self.rgb * (1 - cov[..., None]) + col * cov[..., None]
        self.a = self.a * (1 - cov) + cov

    def begin(self, *ds, halo=None):
        """Soft drop shadow, optional coloured halo (col, sigma, k), then the dark outline."""
        sil = union(*ds)
        m = shifted(blur(cover(sil - OL), 1.5), 1.2, 1.8)
        self.fill(np.clip(m, 0, 1), (0, 0, 0), 0.5)
        if halo:
            col, sigma, k = halo
            self.fill(np.clip(blur(cover(sil), sigma) * k, 0, 0.75), col)
        self.fill(cover(sil - OL), OUTLINE)
        return sil

    def shadow(self, d, dx=1.8, dy=2.6, sigma=2.2, k=0.7):
        """Darkens what is already painted (a part's shadow falling on the part below)."""
        m = shifted(blur(cover(d), sigma), dx, dy)
        self.rgb = self.rgb * (1 - k * np.clip(m, 0, 1))[..., None]

    def glow(self, d, col, sigma=4.0, k=0.9):
        """Additive light on what is already painted (emissive bloom spilling onto the object)."""
        m = np.clip(blur(cover(d), sigma), 0, 1) * k
        self.rgb = self.rgb + (m * self.a)[..., None] * np.asarray(col, float)

    def part(self, d, col, edge=0.8, edge_col=(14, 9, 6), edge_k=0.85):
        """A painted part with a soft dark contact edge round it."""
        if edge:
            self.fill(cover(d - edge), edge_col, edge_k)
        self.fill(cover(d), col)

    def image(self):
        a = self.a
        rgb = np.clip(self.rgb / np.maximum(a, 1e-6)[..., None], 0, 255)
        lum = rgb @ np.array([0.3, 0.59, 0.11])
        rgb = lerp(lum[..., None] * np.ones(3), rgb, 0.96)
        rgb = np.clip((rgb - 128) * 1.05 + 128, 0, 255)

        def down(ch):
            return np.asarray(Image.fromarray(ch.astype(np.float32), "F").resize((ICON_OUT, ICON_OUT), Image.LANCZOS))
        ad = np.clip(down(a), 0, 1)
        out = np.dstack([np.clip(down(rgb[..., i] * a) / np.maximum(ad, 1e-6), 0, 255) for i in range(3)])
        out[ad < 1 / 255] = OUTLINE
        img = Image.fromarray(out.round().astype(np.uint8), "RGB")
        img = img.filter(ImageFilter.UnsharpMask(radius=1.0, percent=40, threshold=0))
        img.putalpha(Image.fromarray((ad * 255).round().astype(np.uint8), "L"))
        return img


# ---------------------------------------------------------------- materials (rich, a little muted)

BRASS = (204, 154, 70)
GOLD = (236, 184, 72)
IRON = (104, 100, 104)
PARCH = (252, 220, 154)
WOOD = (196, 128, 66)
RED = (176, 36, 30)
SLATE = (112, 124, 146)


def brushed(seed):
    return fbm(seed, 3, 4, sy=6, sx=0.4)


def grain(seed, base=6):
    return fbm(seed, base, 4)


def gem(p, cx, cy, r, col, glow=0.0, edge=0.8):
    d = circle(cx, cy, r)
    p.part(d, lit(d, col, dome=(cx, cy, r), spec=0.9, shin=40, amb=0.35, rim=0.5,
                  rim_col=np.asarray(col) * 1.2), edge=edge)
    if glow:
        p.glow(d, col, sigma=r * 0.7, k=glow)
    p.fill(cover(circle(cx - 0.38 * r, cy - 0.42 * r, 0.26 * r)), (255, 255, 248), 0.85)


def rivet(p, cx, cy, r=1.7):
    gem(p, cx, cy, r, BRASS, edge=0.6)


# ---------------------------------------------------------------- the eight icons
# Cut-out objects on transparent, painted in the manner of WoW icons (original art): textured
# surfaces, key light from the top left, a rim light, bloom on glowing parts, a dark outline
# and a soft drop shadow so each reads on parchment and on any tab-bar colour. Designed in a
# 64-unit square, kept inside about [3, 61] with the outline and shadow.

def icon_main(p):
    # an aged parchment name tag on a red cord, brass-capped and grommeted
    with rotated(-12):
        body = poly([(7, 25), (19.5, 12), (58, 12), (58, 52), (19.5, 52), (7, 39)])
        lines = union(line(29, 25, 50, 25, 3.8), line(29, 32.8, 47, 32.8, 3.2), line(29, 40.6, 41, 40.6, 3.2))
        ring = np.abs(circle(20.5, 32, 5.0)) - 2.0
        hole = circle(20.5, 32, 3.0)
    cord_pts = bezier((19, 32.5), (5, 31), (10, 7), 40)
    cord = union(*[seg(*a, *b) for a, b in zip(cord_pts[:-1], cord_pts[1:])]) - 2.2
    p.begin(body, cord)
    fib = fbm(11, 5, 4, sy=3, sx=0.8)
    p.part(body, lit(body, PARCH, radius=3.0, tex=fib, tex_amp=0.22, spec=0.15, amb=0.5,
                     rim_col=(255, 120, 80), rim=0.25), edge=0)
    p.fill(cover(np.abs(body + 1.2) - 1.3), (130, 74, 30), 0.35)          # singed edge
    p.fill(cover(lines) * (0.75 + 0.25 * fbm(12, 8, 3)), (50, 26, 14))
    for cx, cy in ((52.5, 17.5), (52.5, 46.5)):
        with rotated(-12):
            c = circle(cx, cy, 2.1)
        p.part(c, lit(c, BRASS, radius=2.0, spec=0.8, shin=30), edge=0.6)
    p.part(ring, lit(ring, BRASS, radius=1.8, tex=brushed(13), tex_amp=0.2, spec=0.9, shin=30), edge=0.7)
    p.fill(cover(hole), (40, 22, 10))
    p.shadow(cord, 1.0, 1.4, 1.2, 0.5)
    p.part(cord, lit(cord, RED, radius=2.2, tex=fbm(14, 4, 3, sy=4, sx=4), tex_amp=0.35, spec=0.4,
                     rim_col=(255, 140, 90), rim=0.4), edge=0)


def icon_phrases(p):
    # a brass-rimmed parchment speech bubble with three glowing arcane gems
    bubble = union(rbox(32, 27, 28, 21, 13), poly([(13, 40), (29, 40), (8, 60)]))
    face = bubble + 3.4
    p.begin(bubble)
    p.part(bubble, lit(bubble, BRASS, radius=3.0, tex=brushed(21), tex_amp=0.25, spec=0.7, shin=26), edge=0)
    p.part(face, lit(face, PARCH, radius=5.0, tex=fbm(22, 5, 4, sy=2.5, sx=1), tex_amp=0.2, spec=0.12, amb=0.5,
                     rim=0.15), edge=0.7, edge_col=(70, 40, 14))
    for x in (19.5, 32, 44.5):
        gem(p, x, 27, 5.4, (40, 190, 200), glow=0.35)


def icon_animate(p):
    # arcane sparkles: a blazing four-point star, three small ones and a drift of motes
    rng = np.random.default_rng(31)
    stars = [(29, 35, 24, 3.0), (50, 14, 10.5, 3.0), (12, 13, 6.0, 2.8), (52, 50, 6.0, 2.8)]
    shapes = [sparkle(cx, cy, r, k) - 0.9 for cx, cy, r, k in stars]
    motes = []
    for _ in range(8):
        a = rng.uniform(0, 2 * np.pi)
        rr = rng.uniform(16, 26)
        motes.append(circle(29 + rr * np.cos(a), 35 + rr * np.sin(a) * 0.85, rng.uniform(0.9, 1.4)))
    p.begin(*shapes, halo=((150, 80, 255), 3.0, 0.55))
    for (cx, cy, r, k), s in zip(stars, shapes):
        core = np.clip(np.hypot(PX - cx, PY - cy) / (r * 0.8), 0, 1)
        p.fill(cover(s), lerp((255, 255, 255), (140, 70, 240), core ** 0.55))
    for d in motes:
        p.fill(np.clip(blur(cover(d), 1.0) * 1.5, 0, 0.8), (150, 80, 255))
        p.part(d, (250, 236, 255), edge=0.5, edge_col=(60, 20, 110), edge_k=0.9)
    p.glow(union(*shapes[:1]), (180, 120, 255), sigma=3, k=0.25)


def icon_badges(p):
    # a heraldic shield: riveted brass rim, red enamel field, a golden faceted star
    top, xl, xr, mid, bot = 5.5, 9, 55, 26, 60
    left = bezier((32, bot), (xl, 52), (xl, mid))
    right = bezier((xr, mid), (xr, 52), (32, bot))
    shield = poly([(xl, top), (xr, top)] + [tuple(q) for q in right] + [tuple(q) for q in left[1:]]) - 0.5
    field = shield + 4.6
    p.begin(shield)
    p.part(shield, lit(shield, BRASS, radius=3.0, tex=brushed(41), tex_amp=0.25, spec=0.7, shin=26), edge=0)
    p.part(field, lit(field, RED, radius=2.5, tex=grain(42, 5), tex_amp=0.25, spec=0.35, shin=16,
                      rim_col=(255, 120, 90), rim=0.3), edge=0.8)
    for x, y in ((12.5, 9), (51.5, 9), (11.5, 29), (52.5, 29), (32, 57)):
        rivet(p, x, y, 1.6)
    star = star5(32, 30, 15, 0.45) - 0.4
    ang = np.degrees(np.arctan2(PY - 30, PX - 32))
    mid_a = -90 + (np.floor(2 * (ang + 90) / 72) + 0.5) * 36
    face = 0.5 + 0.5 * np.cos(np.radians(mid_a - 225))
    p.part(star, lerp((140, 80, 20), (255, 236, 150), face) * (0.92 + 0.16 * grain(43, 8))[..., None], edge=0.9)
    p.glow(star, (255, 190, 80), sigma=2.0, k=0.2)


def icon_channels(p):
    # a glowing teal crystal in a brass claw, broadcasting rings of light
    teal = (60, 220, 210)
    waves = [union(arc(32, 29, r, -a, a) - 2.0, arc(32, 29, r, 180 - a, 180 + a) - 2.0)
             for r, a in ((14, 42), (23.5, 40))]
    crystal = poly([(32, 7), (40, 20), (38.5, 42), (32, 50), (25.5, 42), (24, 20)])
    base = union(rbox(32, 54, 12, 4.5, 2), poly([(22, 51), (27, 40), (29.5, 51)]),
                 poly([(42, 51), (37, 40), (34.5, 51)]))
    p.begin(*waves, crystal, base, halo=(teal, 2.6, 0.6))
    for w in waves:
        p.fill(cover(w), lerp((210, 255, 250), (40, 190, 185), np.clip(np.abs(PX - 32) / 30, 0, 1)))
    p.part(base, lit(base, BRASS, radius=2.5, tex=brushed(51), tex_amp=0.25, spec=0.8, shin=26), edge=0)
    face = np.where(PX < 32, 1.0, 0.45) * np.clip(1.15 - (PY - 7) / 60, 0.6, 1.2)
    col = lerp((10, 90, 100), (130, 250, 236), face)
    col = lerp(col, (235, 255, 250), np.exp(-((PX - 31) ** 2 / 18 + (PY - 28) ** 2 / 90)) * 0.7)
    p.part(crystal, col, edge=0.8)
    p.fill(cover(line(32, 8, 32, 49, 0.9)), (230, 255, 250), 0.7)
    p.fill(cover(union(line(24.3, 20.5, 32, 23.5, 0.7), line(39.7, 20.5, 32, 23.5, 0.7))), (220, 255, 250), 0.6)
    p.fill(cover(circle(28.5, 16, 1.6)), (255, 255, 255), 0.9)
    p.glow(crystal, teal, sigma=3, k=0.25)


def icon_behavior(p):
    # a gnomish lever on a riveted iron plate, red knob, green "on" lamp
    plate = rbox(32, 43, 27, 15, 4.5)
    slot = rbox(32, 43, 15, 2.8, 2.8)
    arm = line(33, 43, 47, 14, 5.0)
    knob = circle(47, 13, 8.0)
    p.begin(plate, arm, knob)
    p.part(plate, lit(plate, IRON, radius=2.5, tex=brushed(61), tex_amp=0.35, spec=0.5, shin=20), edge=0)
    for x, y in ((9.5, 32), (54.5, 32), (9.5, 54), (54.5, 54)):
        rivet(p, x, y, 1.9)
    p.fill(cover(slot), (12, 10, 10))
    p.fill(cover(np.abs(slot + 0.2) - 0.4) * (PY > 43), (160, 150, 140), 0.5)
    p.shadow(arm, 2.0, 2.2, 1.5, 0.55)
    p.part(arm, lit(arm, (196, 192, 186), radius=2.5, tex=brushed(62), tex_amp=0.2, spec=0.9, shin=30), edge=0.7)
    hub = circle(33, 43, 5.8)
    p.part(hub, lit(hub, BRASS, dome=(33, 43, 5.8), spec=0.9, shin=30), edge=0.8)
    gem(p, 47, 13, 8.0, RED, edge=0)
    gem(p, 15.5, 43, 3.2, (70, 230, 90), glow=0.6, edge=0.7)


def icon_cosmetic(p):
    # a painter's palette of grained wood with glossy paint, and a brush
    with rotated(-14, 32, 34):
        pal = poly(ellipse_poly(31, 34, 28, 22))
        pal = cut(pal, circle(54, 47, 8.5))
        thumb = circle(19, 42, 3.8)
        wood = fbm(71, 2, 4, sy=0.4, sx=5)
    pal = cut(pal, thumb)
    handle = line(59, 59, 46, 44, 4.4)
    ferrule = line(46, 44, 41.5, 38.5, 4.8)
    tip = union(line(41.5, 38.5, 38, 34.5, 4.0), circle(37, 33.3, 1.7))
    p.begin(pal, handle, ferrule, tip)
    p.part(pal, lit(pal, WOOD, radius=3.2, tex=wood, tex_amp=0.4, spec=0.3, shin=18, rim_col=(255, 150, 120)),
           edge=0)
    blobs = [((16.5, 30), (186, 32, 28)), ((26, 20.5), (240, 186, 52)), ((38.5, 18.5), (40, 112, 210)),
             ((46, 30), (60, 168, 72)), ((29, 42), (240, 234, 218))]
    for (x, y), c in blobs:
        d = circle(x, y, 5.0) + 0.8 * (fbm(72 + int(x), 6, 2) - 0.5)
        p.part(d, lit(d, c, radius=2.6, spec=0.9, shin=34, rim=0.3), edge=0.6, edge_k=0.6)
    p.shadow(union(handle, ferrule, tip), 1.4, 1.8, 1.2, 0.5)
    p.part(handle, lit(handle, (130, 32, 30), radius=2.2, spec=0.7, shin=30), edge=0.6)
    p.part(ferrule, lit(ferrule, BRASS, radius=2.4, spec=0.9, shin=30), edge=0.6)
    p.part(tip, lit(tip, (40, 112, 210), radius=1.9, spec=0.6, shin=30), edge=0.6)


def icon_help(p):
    # a slate rune stone with a carved question mark burning gold
    stone = circle(32, 32, 27) + 1.6 * (fbm(81, 2, 3) - 0.5) * 2
    q = union(arc(32, 24.5, 8.0, 180, 450) - 3.2, line(32, 32.5, 32, 37.5, 6.4), circle(32, 46.5, 4.0))
    p.begin(stone)
    p.part(stone, lit(stone, SLATE, radius=5.0, tex=fbm(82, 4, 5), tex_amp=0.5, spec=0.2, shin=12,
                      rim_col=(110, 150, 255), rim=0.45), edge=0)
    p.fill(cover(np.abs(circle(32, 32, 21.5)) - 0.55) * (0.5 + 0.5 * fbm(83, 4, 3)), (24, 24, 32), 0.6)
    p.fill(cover(shifted(q, -0.9, -0.9) - 0.9), (14, 12, 16), 0.9)               # carved groove
    p.glow(q, (255, 150, 40), sigma=3.0, k=0.7)
    p.fill(cover(q), lerp((255, 248, 200), (255, 150, 40), np.clip((PY - 17) / 34, 0, 1)))


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
# (own names: the icon code above reads PARCH / WOOD as materials)

BG_PARCH, FG_INK = (204, 173, 117), (36, 20, 8)
BG_WOOD, FG_CREAM = (61, 41, 23), (245, 232, 199)
BG_TEAL = (38, 70, 74)        # a palette-coloured tab bar


def dimmed(ic, desat=0.45, dim=0.85):
    """The unselected-tab look: partly desaturated, slightly darker."""
    a = ic.getchannel("A")
    rgb = np.asarray(ic.convert("RGB"), float)
    lum = rgb @ np.array([0.3, 0.59, 0.11])
    rgb = (rgb * (1 - desat) + lum[..., None] * desat) * dim
    out = Image.fromarray(np.clip(rgb, 0, 255).round().astype(np.uint8), "RGB")
    out.putalpha(a)
    return out


def make_preview(icons, logo):
    """Each icon on parchment (selected tab), dark wood and a palette-coloured bar, at 64, 30
    (tab), 20 px and 30 px blown up x3; the last row of the bar panels is the dimmed look."""
    names = list(icons) + ["logo"]
    icons = dict(icons, logo=logo)
    cell = 100
    rows = [(64, 76, False), (30, 40, False), (20, 30, False), ("zoom", 96, False)]
    panels = [(BG_PARCH, FG_INK, "parchment (selected tab)", rows),
              (BG_WOOD, FG_CREAM, "dark wood tab bar; last row = unselected tab (desaturated, dimmed)",
               rows + [(30, 40, True)]),
              (BG_TEAL, FG_CREAM, "palette-coloured tab bar; last row = unselected tab", [(30, 40, False), (30, 40, True)])]
    heights = [sum(r[1] for r in pr) + 38 for *_, pr in panels]
    sheet = Image.new("RGB", (len(names) * cell + 20, sum(heights)), (30, 30, 30))
    draw = ImageDraw.Draw(sheet)
    y0 = 0
    for (bg, fg, label, prows), panel_h in zip(panels, heights):
        draw.rectangle([0, y0, sheet.width, y0 + panel_h - 2], fill=bg)
        draw.text((8, y0 + 4), label, fill=fg)
        y = y0 + 20
        for size, h, dim in prows:
            for i, name in enumerate(names):
                x = 10 + i * cell
                s = 30 if size == "zoom" else size
                ic = icons[name].resize((s, s), Image.LANCZOS)
                if dim and name != "logo":
                    ic = dimmed(ic)
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
