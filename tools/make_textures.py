#!/usr/bin/env python3
"""Rebuilds Maines' surface textures in textures/ (run from anywhere: python3 tools/make_textures.py).

grain.tga    - tileable paper grain laid over every parchment panel
brushed.tga  - tileable brushed-brass streaks for the title band
glow.tga     - soft round falloff; its quarters and centre lines build the window's outer glow
palettes/    - one paper + one band surface per /maincolor palette (see palettes() below)

All are white with the pattern in the alpha channel, so the addon tints them in game.
Fixed seeds: running this again reproduces the same files.
"""
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "textures"
N = 256


def roll_blur(a, r, axis):
    # wrap-around box blur, so the result tiles seamlessly
    acc = np.zeros_like(a)
    for d in range(-r, r + 1):
        acc += np.roll(a, d, axis=axis)
    return acc / (2 * r + 1)


def blur(a, r):
    return roll_blur(roll_blur(a, r, 0), r, 1)


def norm(a):
    a = a - a.min()
    return a / a.max()


def save_alpha(alpha, name):
    img = np.zeros(alpha.shape + (4,), np.uint8)
    img[..., :3] = 255
    img[..., 3] = alpha
    Image.fromarray(img, "RGBA").save(OUT / name)


def grain():
    rng = np.random.default_rng(7)
    cloud = norm(blur(rng.random((N, N)), 12)) * 0.5 + norm(blur(rng.random((N, N)), 4)) * 0.3 + norm(rng.random((N, N))) * 0.2
    # a few faint horizontal fibres, like laid paper
    fib = np.zeros((N, N))
    for _ in range(220):
        y = rng.integers(N); x = rng.integers(N); length = rng.integers(8, 40)
        for i in range(length):
            fib[y, (x + i) % N] += rng.uniform(0.3, 1)
    fib = blur(fib, 1)
    a = norm(cloud) * 0.75 + norm(fib) * 0.25
    save_alpha((norm(a) ** 1.6 * 255).astype(np.uint8), "grain.tga")


def brushed():
    rng = np.random.default_rng(11)
    streak = norm(roll_blur(rng.random((N, N)), 40, 1))
    fine = norm(roll_blur(rng.random((N, N)), 3, 1))
    mottle = norm(roll_blur(roll_blur(rng.random((N, N)), 24, 1), 10, 0))
    a = norm(streak * 0.55 + fine * 0.25 + mottle * 0.20)
    save_alpha((a ** 1.3 * 255).astype(np.uint8), "brushed.tga")


def glow():
    size = 64
    y, x = np.mgrid[0:size, 0:size] + 0.5
    r = np.hypot(x - size / 2, y - size / 2) / (size / 2)
    a = np.clip(1 - r, 0, 1) ** 2.2  # bright at the centre, fading smoothly to nothing at the rim
    save_alpha((a * 255).astype(np.uint8), "glow.tga")


# ------------------------------------------------------------------ per-palette surfaces
# /maincolor swaps the grain and brushed overlays for a pair made for the rolled palette:
#   palettes/<key>.tga       128x128, laid over every parchment panel in place of grain.tga
#   palettes/<key>_band.tga  256x64,  laid over the title bands in place of brushed.tga
# Same recipe as the originals: white, pattern in the alpha channel, seamless when tiled, and
# levelled to the originals' mean/spread (finish) so no palette's surface is louder than the start look.
PAPER = (128, 128)   # (height, width)
BAND = (64, 256)


def gblur(a, r):
    # three box blurs ~ a gaussian, so soft blobs come out round rather than square
    k = max(1, int(round(r / 1.7)))
    for _ in range(3):
        a = blur(a, k)
    return a


def noise(rng, shape, r):
    a = rng.random(shape)
    return norm(gblur(a, r)) if r else a


def hblur(a, r):
    return roll_blur(a, r, 1)


def sample(a, y, x):
    # bilinear lookup with wrap-around, so warped patterns still tile
    h, w = a.shape
    y0, x0 = np.floor(y).astype(int), np.floor(x).astype(int)
    fy, fx = y - y0, x - x0
    y0, x0 = y0 % h, x0 % w
    y1, x1 = (y0 + 1) % h, (x0 + 1) % w
    top = a[y0, x0] * (1 - fx) + a[y0, x1] * fx
    bot = a[y1, x0] * (1 - fx) + a[y1, x1] * fx
    return top * (1 - fy) + bot * fy


def grid(shape):
    h, w = shape
    return np.mgrid[0:h, 0:w].astype(float)


def wrapped(d, n):
    # shortest signed distance on a ring of length n
    return (d + n / 2) % n - n / 2


def lic(field_y, field_x, src, steps=14, step=1.0):
    # line-integral convolution: smears src along the flow, like a brush following it
    yy, xx = grid(src.shape)
    acc = src.copy()
    for sign in (1, -1):
        y, x = yy.copy(), xx.copy()
        for _ in range(steps):
            vy, vx = sample(field_y, y, x), sample(field_x, y, x)
            y += sign * vy * step
            x += sign * vx * step
            acc += sample(src, y, x)
    return acc / (2 * steps + 1)


def stamp(canvas, cy, cx, half_h, half_w, value, angle=0.0, soft=1.0, ellipse=True):
    # adds one soft-edged ellipse (or rectangle) at (cy, cx), wrapping across the edges
    h, w = canvas.shape
    yy, xx = grid(canvas.shape)
    dy, dx = wrapped(yy - cy, h), wrapped(xx - cx, w)
    ca, sa = np.cos(angle), np.sin(angle)
    u, v = (dx * ca + dy * sa) / half_w, (-dx * sa + dy * ca) / half_h
    if ellipse:
        d = np.hypot(u, v)
    else:
        d = np.maximum(abs(u), abs(v))
    canvas += value * np.clip((1 - d) / max(soft, 1e-3) * 2, 0, 1)


def paper_noise(rng, shape):
    return noise(rng, shape, 6) * 0.5 + noise(rng, shape, 2) * 0.3 + rng.random(shape) * 0.2


def brush(rng, shape, long=30):
    return norm(hblur(rng.random(shape), long)) * 0.6 + norm(hblur(rng.random(shape), 3)) * 0.4


def starry(rng, shape):
    # swirls: noise smeared along the eddies of a smooth (tileable) stream function, the Van
    # Gogh brushwork
    h, w = shape
    psi = noise(rng, shape, 24) * 0.85 + noise(rng, shape, 9) * 0.15
    fy = (np.roll(psi, -1, 1) - np.roll(psi, 1, 1))
    fx = -(np.roll(psi, -1, 0) - np.roll(psi, 1, 0))
    fx += 0.004                                       # a slow drift to the right between eddies
    mag = np.hypot(fy, fx) + 1e-9
    dabs = (rng.random(shape) > 0.82).astype(float)  # sparse paint flecks, pulled into strokes
    strokes = lic(fy / mag, fx / mag, dabs, steps=16)
    return norm(strokes) * 0.8 + noise(rng, shape, 5) * 0.2


def great_wave(rng, shape):
    # faint wave crests: rows of uneven swells, each with a bright crest line and a spray of
    # foam just behind it, rows offset and bent so the repeat doesn't read as a pattern
    h, w = shape
    yy, xx = grid(shape)
    rows = 4 if h >= 128 else 2
    period = h / rows
    k = 1 if w == h else 2
    warp = (noise(rng, shape, 16) - 0.5) * period * 1.2
    swell = (np.sin(2 * np.pi * k * xx / w) * 0.25 +
             np.sin(2 * np.pi * (2 * k + 1) * xx / w + 1.1) * 0.12) * period + warp
    t = ((yy + swell) % period) / period              # 0 at a crest, rising to 1 before the next
    crest = np.exp(-t / 0.10) * 0.7 + np.exp(-(1 - t) / 0.03) * 0.3
    foam = (noise(rng, shape, 1) > 0.6) * np.exp(-t / 0.22)
    return crest * 0.55 + gblur(foam, 1.5) * 0.5 + noise(rng, shape, 3) * 0.35


def kiss(rng, shape):
    # gold mosaic flecks: small squares, slabs and rings scattered over a soft ground
    h, w = shape
    a = noise(rng, shape, 4) * 0.25
    for _ in range(int(h * w / 210)):
        cy, cx = rng.uniform(0, h), rng.uniform(0, w)
        kind = rng.random()
        if kind < 0.6:
            s = rng.uniform(1.5, 3.5)
            stamp(a, cy, cx, s, s * rng.uniform(0.8, 1.6), rng.uniform(0.35, 0.9), soft=0.4, ellipse=False)
        elif kind < 0.85:
            stamp(a, cy, cx, rng.uniform(1.2, 2.2), rng.uniform(4, 7), rng.uniform(0.3, 0.6),
                  angle=np.pi / 2 * rng.integers(2), soft=0.4, ellipse=False)
        else:
            r = rng.uniform(3, 5)
            stamp(a, cy, cx, r, r, 0.6, soft=0.5)
            stamp(a, cy, cx, r * 0.55, r * 0.55, -0.6, soft=0.5)
    return np.clip(a, 0, None) + rng.random(shape) * 0.08


def water_lilies(rng, shape):
    # dabbed brushstrokes: short soft dabs, mostly lying flat like reflections on water
    h, w = shape
    a = noise(rng, shape, 8) * 0.5
    for _ in range(int(h * w / 90)):
        stamp(a, rng.uniform(0, h), rng.uniform(0, w), rng.uniform(1.5, 2.8), rng.uniform(3.5, 8),
              rng.uniform(-0.2, 0.3), angle=rng.normal(0, 0.25), soft=1.2)
    return a + noise(rng, shape, 1) * 0.1


def scream(rng, shape):
    # wavy streaks: long parallel bands bending through the sky, smeared along their flow
    h, w = shape
    yy, xx = grid(shape)
    k = 1 if w == h else 2
    bend = np.sin(2 * np.pi * k * xx / w) * h * 0.12 + (noise(rng, shape, 10) - 0.5) * 14
    bands = np.sin(2 * np.pi * (yy + bend) / (h / (6 if h >= 128 else 3)))
    dbend = np.cos(2 * np.pi * k * xx / w) * 2 * np.pi * k / w * h * 0.12
    fy, fx = -dbend, np.ones(shape)
    mag = np.hypot(fy, fx)
    smear = lic(fy / mag, fx / mag, rng.random(shape), steps=10)
    return norm(bands) * 0.5 + norm(smear) * 0.5


def composition(rng, shape):
    # a faint Mondrian grid: uneven ruled lines, a few blocks tinted a shade deeper
    h, w = shape
    a = paper_noise(rng, shape) * 0.5
    ys = sorted(rng.choice(np.arange(4, h - 4), 2 if h >= 128 else 1, replace=False))
    xs = sorted(rng.choice(np.arange(6, w - 6), 3 if w <= 128 else 5, replace=False))
    edges_y, edges_x = [0] + list(ys) + [h], [0] + list(xs) + [w]
    for i in range(len(edges_y) - 1):
        for j in range(len(edges_x) - 1):
            if rng.random() < 0.3:
                a[edges_y[i]:edges_y[i + 1], edges_x[j]:edges_x[j + 1]] += 0.18
    for y in ys:
        a[y - 1:y + 2, :] += 0.55
    for x in xs:
        a[:, x - 1:x + 2] += 0.55
    return blur(a, 1)


def nighthawks(rng, shape):
    # soft street-light grain: a fine even grain under two broad pools of lamp light
    h, w = shape
    a = rng.random(shape) * 0.5 + noise(rng, shape, 1) * 0.3
    glow = np.zeros(shape)
    for _ in range(2):
        r = min(h, w) * rng.uniform(0.25, 0.4)
        stamp(glow, rng.uniform(0, h), rng.uniform(0, w), r, r * (1 if w == h else 2.5), -1, soft=2.0)
    return a + gblur(glow, 6) * 0.45 + noise(rng, shape, 12) * 0.3


def melted(rng, shape):
    # persistence of memory: paper grain that has slumped - warped, then dragged downward
    h, w = shape
    yy, xx = grid(shape)
    base = paper_noise(rng, shape)
    sag = noise(rng, shape, 10)
    warped = sample(base, yy - sag * h * 0.1, xx + (noise(rng, shape, 12) - 0.5) * 10)
    drip = np.zeros(shape)
    for d in range(12):
        drip += np.roll(warped, d, axis=0) * (1 - d / 12)
    drip = gblur(drip, 1)
    return drip / drip.max() + sag * 0.25


def hammered(rng, shape):
    # hammered metal: overlapping round peen marks, lit from the top left
    h, w = shape
    yy, xx = grid(shape)
    n = int(h * w / 150)
    f1 = np.full(shape, 1e9)
    for _ in range(n):
        cy, cx = rng.uniform(0, h), rng.uniform(0, w)
        f1 = np.minimum(f1, np.hypot(wrapped(yy - cy, h), wrapped(xx - cx, w)) * rng.uniform(0.85, 1.15))
    height = -np.sqrt(np.clip(36 - f1 ** 2, 0, None))
    gy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) / 2
    gx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) / 2
    lit = np.clip(-(gy + gx) / 6, -1, 1)
    return norm(blur(lit, 1)) * 0.75 + brush(rng, shape, 12) * 0.25


def neon(rng, shape):
    # fine scanlines, with the odd glitched run where a line slips sideways
    h, w = shape
    yy, xx = grid(shape)
    lines = (yy % 4 < 1.5).astype(float)
    flicker = noise(rng, (h, 1), 0)[:, :1] * 0.4
    glitch = np.zeros(shape)
    for _ in range(3):
        y, x, n = rng.integers(h), rng.integers(w), rng.integers(10, 40)
        glitch[y, (x + np.arange(n)) % w] = 0.6
    return lines * 0.6 + flicker + glitch + noise(rng, shape, 6) * 0.25 + rng.random(shape) * 0.1


def brushed_steel(rng, shape):
    # brushed steel: tight straight grain, with a faint second pass crossing it at a slant
    yy, xx = grid(shape)
    fine = norm(hblur(rng.random(shape), 18)) * 0.5 + norm(hblur(rng.random(shape), 2)) * 0.3
    cross = sample(hblur(rng.random(shape), 10), yy + xx * 0.25, xx)
    return fine + norm(cross) * 0.15 + noise(rng, shape, 10) * 0.12


def verdigris(rng, shape):
    # verdigris patina: crusty blooms with hard-ish edges, and a speckle of pitting
    h, w = shape
    f = noise(rng, shape, 10) * 0.55 + noise(rng, shape, 4) * 0.30 + noise(rng, shape, 1) * 0.15
    f = norm(f)
    blooms = 1 / (1 + np.exp(-(f - 0.55) * 18))
    pits = (rng.random(shape) > 0.985) * 0.8
    return blooms * 0.65 + f * 0.25 + blur(pits, 1) * 0.6


def blueprint(rng, shape):
    # a drafting grid: fine squares every 8, heavier rules every 32
    h, w = shape
    yy, xx = grid(shape)
    minor = ((yy % 8) < 1) | ((xx % 8) < 1)
    major = ((yy % 32) < 1.5) | ((xx % 32) < 1.5)
    return minor * 0.35 + major * 0.45 + paper_noise(rng, shape) * 0.35


# key, maker, seed, how much of the band's metal is the palette's own pattern (the rest is
# brushed streaks, so every band still reads as metal), and the finished contrast
PALETTE_SURFACES = [
    ("starry", starry, 101, 0.70, 1.0),
    ("wave", great_wave, 102, 0.65, 1.0),
    ("kiss", kiss, 103, 0.65, 1.0),
    ("lilies", water_lilies, 104, 0.65, 1.0),
    ("scream", scream, 105, 0.70, 1.0),
    ("mondrian", composition, 106, 0.55, 1.0),
    ("nighthawks", nighthawks, 107, 0.55, 1.0),
    ("memory", melted, 108, 0.65, 1.0),
    ("copper", hammered, 109, 0.80, 1.0),
    ("neon", neon, 110, 0.65, 1.0),
    ("ironforge", brushed_steel, 111, 1.00, 1.0),
    ("verdigris", verdigris, 112, 0.70, 1.0),
    ("blueprint", blueprint, 113, 0.55, 1.0),
]


def finish(a, mean, spread):
    # level a pattern to a given mean and standard deviation of alpha (the originals' look)
    a = (a - a.mean()) / (a.std() + 1e-9)
    return np.clip(a * spread + mean, 0, 1)


def palettes():
    (OUT / "palettes").mkdir(exist_ok=True)
    for key, make, seed, band_mix, contrast in PALETTE_SURFACES:
        rng = np.random.default_rng(seed)
        paper = finish(make(rng, PAPER), 0.295, 0.126 * contrast)
        save_alpha((paper * 255).round().astype(np.uint8), "palettes/%s.tga" % key)
        motif = norm(make(rng, BAND))
        metal = band_mix * motif + (1 - band_mix) * norm(brush(rng, BAND))
        save_alpha((finish(metal, 0.376, 0.126 * contrast) * 255).round().astype(np.uint8), "palettes/%s_band.tga" % key)


# ------------------------------------------------------------------ window frame borders
# The frame round the Maines window, the /mainhelp window and the /mainnote popup, one style per
# /maincolor palette plus "brass" for the start look. Every style is cut from the same moulding
# (rounded lip, flat field, inner bead, a dark step onto the window) and lit from the top left
# like the title band; only a shallow motif in the field (engraving, inlay, hammering, bolts) and
# the corner ornament differ. The textures are greyscale relief: Maines tints them with the same
# palette tone as the title band, so frame and window are always one material and one colour.
# Each style is eight files in frames/<key>/, laid out the way Maines draws them:
#   tl, tr, bl, br   32x32  the corners (16 UI units square)
#   top, bottom      128x32 edge strips that repeat along their length every 64 UI units
#   left, right      32x128
# 2 texels per UI unit. All eight come from the same two coordinates - d (texels in from the
# frame's outer edge) and a (texels along the edge, 0 at every corner join) - so the strips meet
# the corners without a step, and a strip repeats a whole number of times (the add-on rounds
# the repeat to fit) so it also lands on a join at the far end. Corners are mitred like a
# picture frame; a corner's two halves keep the two strips' own patterns and meet on the diagonal.
FT, FL, PAD = 32, 128, 2
LIGHT = np.array([-1.0, -1.0, 1.6]); LIGHT /= np.linalg.norm(LIGHT)
HALF = LIGHT + np.array([0.0, 0.0, 1.0]); HALF /= np.linalg.norm(HALF)
FRAME_PIECES = ["tl", "tr", "bl", "br", "top", "bottom", "left", "right"]


def rgb(*c):
    return np.array(c, float)


def dome(x):
    return np.sqrt(np.clip(1 - x * x, 0, None))


def band(d, lo, hi, soft=0.8):
    # 1 between lo and hi with anti-aliased edges
    return np.clip((d - lo) / soft + 0.5, 0, 1) * np.clip((hi - d) / soft + 0.5, 0, 1)


def nearest(a, period, phase=0.0):
    # signed distance along the edge to the nearest repeat of something every `period` texels
    return (a - phase + period / 2) % period - period / 2


def mix(a, b, t):
    t = np.asarray(t, float)
    if t.ndim and t.shape[-1] != 1:
        t = t[..., None]
    return a * (1 - t) + b * t


def piece_coords(piece, rounded):
    h, w = {"top": (FT, FL), "bottom": (FT, FL), "left": (FL, FT), "right": (FL, FT)}.get(piece, (FT, FT))
    yy, xx = np.mgrid[-PAD:h + PAD, -PAD:w + PAD].astype(float) + 0.5
    far = np.full(yy.shape, 1e3)
    corner = piece in ("tl", "tr", "bl", "br")
    if piece == "top":
        d, a, u, v, side = yy, xx, far, far, "top"
    elif piece == "bottom":
        d, a, u, v, side = FT - yy, xx, far, far, "bottom"
    elif piece == "left":
        d, a, u, v, side = xx, yy, far, far, "left"
    elif piece == "right":
        d, a, u, v, side = FT - xx, yy, far, far, "right"
    else:
        left, top = piece[1] == "l", piece[0] == "t"
        u = xx if left else FT - xx            # in from the corner's outer vertical edge
        v = yy if top else FT - yy             # in from its outer horizontal edge
        horiz = v < u                           # nearer the top/bottom strip than the side strip
        a = np.where(horiz, xx - FT if left else xx, yy - FT if top else yy)
        if rounded:
            d = FT - np.hypot(np.clip(FT - u, 0, None), np.clip(FT - v, 0, None))
        else:
            d = np.minimum(u, v)
        side = np.where(horiz, "top" if top else "bottom", "left" if left else "right")
    return {"d": d, "a": a, "u": u, "v": v, "corner": corner, "side": side, "piece": piece}


def strip_field(rng, ra, rd):
    # smooth noise over the (d, a) strip, repeating along a
    f = rng.random((FT, FL))
    f = roll_blur(roll_blur(roll_blur(f, ra, 1), ra, 1), ra, 1) if ra else f
    if rd:
        f = np.stack([np.convolve(np.pad(col, rd, mode="edge"), np.ones(2 * rd + 1) / (2 * rd + 1), "valid") for col in f.T], 1)
    return norm(f)


def at(field, c, d=None, a=None):
    # look a strip field up at each pixel's (d, a): bilinear, wrapping along a
    d = c["d"] if d is None else d
    a = c["a"] if a is None else a
    return sample(field, np.clip(d - 0.5, 0, FT - 1.001), a - 0.5)


def light(c, out):
    hgt = out["height"]
    gy = (np.roll(hgt, -1, 0) - np.roll(hgt, 1, 0)) / 2
    gx = (np.roll(hgt, -1, 1) - np.roll(hgt, 1, 1)) / 2
    n = np.stack([-gx, -gy, np.ones_like(hgt)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    dif = np.clip(n @ LIGHT, 0, 1)
    spec = np.clip(n @ HALF, 0, 1) ** out.get("shine", 24) * out.get("spec", 0.0)
    col = out["color"]
    if np.ndim(spec):
        spec = spec[..., None]
    out_rgb = col * (0.30 + 0.85 * dif)[..., None] + spec * mix(col, rgb(1, 1, 1), 0.55)
    if "emit" in out:
        out_rgb = out_rgb + out["emit"]
    alpha = out.get("alpha", np.clip(c["d"] + 0.5, 0, 1))
    img = np.concatenate([np.clip(out_rgb, 0, 1), alpha[..., None]], -1)
    return img[PAD:-PAD, PAD:-PAD]


def frame_profile(d):
    # the shared moulding every frame is cut from: a rounded outer lip, a flat field, an inner
    # bead, then a crisp dark step down onto the window (so frame and window meet in one line)
    return 1.5 * dome((d - 3.5) / 3.5) + 0.9 * band(d, 7, 25.5) + 1.3 * dome((d - 27.8) / 2.4)


FIELD = (8.0, 24.5)    # the flat field between lip and bead, where each palette's motif sits


def field_mask(d):
    return band(d, FIELD[0], FIELD[1], 0.8)


def corner_r(c, cu=16.5, cv=16.5):
    return np.hypot(c["u"] - cu, c["v"] - cv)


def make_frame(motif, ornament="boss"):
    """One frame style: the shared moulding and lighting, plus `motif(c, field) -> (dh, dalb)`, a
    shallow height and brightness change inside the field, and a corner ornament."""
    def piece(c):
        d = c["d"]
        field = field_mask(d)
        h = frame_profile(d)
        alb = np.full(d.shape, 0.74)
        dh, dalb = motif(c, field)
        h = h + dh * field
        alb = alb + dalb * field
        corner = np.asarray(c["corner"])
        r = corner_r(c)
        cu, cv = c["u"] - 16.5, c["v"] - 16.5
        if ornament == "boss":
            orn = dome(r / 4.4) * 0.9
            h = np.where(corner & (r < 4.4), 0.9 + orn, h)
        elif ornament == "bolt":
            slot = band(cu + cv, -0.5, 0.5, 0.4) * (r < 3.4)
            h = np.where(corner & (r < 4.4), 0.9 + dome(r / 4.4) * 0.8 - 0.5 * slot, h)
        elif ornament == "ring":
            ring = band(r, 3.0, 4.4, 0.5)
            h = np.where(corner & (r < 5.0), 0.9 + 0.45 * ring - 0.25 * (r < 1.2), h)
        elif ornament == "star":
            ang = np.arctan2(cv, cu)
            star = (r < 5.0) & (r < 2.2 + 2.8 * np.abs(np.cos(ang * 2)) ** 3)
            h = np.where(corner & (r < 5.5), 0.9 + 0.5 * star, h)
        elif ornament == "spiral":
            ang = np.arctan2(cv, cu)
            groove = np.cos(r * 1.6 - ang) > 0.6
            h = np.where(corner & (r < 5.0), 0.9 + 0.6 * dome(r / 5.0) - 0.3 * groove, h)
        elif ornament == "square":
            sq = np.maximum(abs(cu), abs(cv))
            h = np.where(corner & (sq < 4.5), 0.9 + 0.5 * band(sq, -1, 3.2, 0.6), h)
        elif ornament == "target":
            mark = band(r, 3.4, 4.2, 0.4) + (band(cu, -0.35, 0.35, 0.4) + band(cv, -0.35, 0.35, 0.4)) * (r < 5.2)
            h = np.where(corner & (r < 5.5), 0.9 - 0.35 * np.clip(mark, 0, 1), h)
        step = d > 30.6
        h = np.where(step, 0.0, h)
        alb = np.where(step, 0.30, alb)
        return {"height": h, "color": np.clip(alb, 0, 1)[..., None] * np.ones(3), "spec": 0.35, "shine": 18}
    return piece


def frame_brass(rng):
    # the start look: plain brushed brass, a boss at each corner
    streak = strip_field(rng, 20, 0)
    return make_frame(lambda c, f: (0, 0.10 * (at(streak, c) - 0.5)), "boss")


def frame_copper(rng):
    # Gnomeregan Copper: a softly hammered field, small rivets
    pts = [(rng.uniform(FIELD[0], FIELD[1]), rng.uniform(0, FL)) for _ in range(44)]
    dd, aa = np.mgrid[0:FT, 0:FL].astype(float) + 0.5
    f1 = np.full((FT, FL), 1e3)
    for pd, pa in pts:
        f1 = np.minimum(f1, np.hypot(dd - pd, wrapped(aa - pa, FL)))
    dents = -0.45 * dome(f1 / 5.0)
    return make_frame(lambda c, f: (at(dents, c), 0.0), "boss")


def frame_ironforge(rng):
    # Ironforge: brushed steel, two cut grooves, slotted bolts every 64 units
    streak = strip_field(rng, 26, 0)
    def motif(c, f):
        d, a = c["d"], c["a"]
        grooves = -0.45 * (dome((d - 10.5) / 1.2) + dome((d - 22) / 1.2))
        da, dr = nearest(a, 64, 32), d - 16.2
        r = np.hypot(da, dr)
        bolt = np.where(np.asarray(c["corner"]), 0, 0.7 * dome(r / 3.0) - 0.35 * band(da + dr, -0.5, 0.5, 0.4) * (r < 2.6))
        return grooves + bolt, 0.12 * (at(streak, c) - 0.5)
    return make_frame(motif, "bolt")


def frame_verdigris(rng):
    # Verdigris Goblin: cast bronze, pitted and mottled where the patina sat
    mottle = strip_field(rng, 5, 2)
    pits = (rng.random((FT, FL)) > 0.96).astype(float)
    def motif(c, f):
        m = at(mottle, c)
        return -0.25 * at(pits, c), 0.16 * (m - 0.5)
    return make_frame(motif, "boss")


def frame_kiss(rng):
    # The Kiss: a field of small inlaid tesserae, each catching the light a little differently
    shade = rng.normal(0, 0.06, size=(3, FL // 8))
    tilt = rng.normal(0, 0.07, size=(3, FL // 8, 2))
    def motif(c, f):
        d, a = c["d"], c["a"]
        row = np.clip(np.floor((d - FIELD[0]) / 5.5), 0, 2).astype(int)
        col = (np.floor(a / 8).astype(int)) % (FL // 8)
        fd, fa = (d - FIELD[0]) % 5.5, a % 8
        grout = np.minimum(np.minimum(fd, 5.5 - fd), np.minimum(fa, 8 - fa)) < 0.5
        tl = tilt[row, col]
        dh = np.where(grout, -0.3, tl[..., 0] * (fd - 2.75) + tl[..., 1] * (fa - 4))
        return dh, np.where(grout, -0.12, shade[row, col])
    return make_frame(motif, "spiral")


def frame_memory(rng):
    # The Persistence of Memory: the moulding gone soft - the field sags and smears
    wob = strip_field(rng, 10, 0)
    smear = strip_field(rng, 16, 2)
    def motif(c, f):
        w = at(wob, c, d=np.full(c["d"].shape, 16.0))
        dh = 0.45 * np.sin((c["d"] - FIELD[0]) / (FIELD[1] - FIELD[0]) * np.pi * (1.2 + w)) - 0.2
        return dh, 0.12 * (at(smear, c, d=c["d"] + 4 * w) - 0.5)
    return make_frame(motif, "ring")


def frame_neon(rng):
    # Undermine Neon: two rounded tubes laid in the field
    def motif(c, f):
        d = c["d"]
        return -0.4 + 0.8 * (dome((d - 12) / 2.2) + dome((d - 20.5) / 2.2)), 0.04 * (dome((d - 12) / 2.2) + dome((d - 20.5) / 2.2))
    return make_frame(motif, "ring")


def frame_blueprint(rng):
    # Blueprint Ink: an engraved double rule and a ruler scale along the inside
    def motif(c, f):
        d, a = c["d"], c["a"]
        rule = band(d, 9.5, 10.3, 0.4) + band(d, 11.6, 12.4, 0.4)
        tick_len = np.where(abs(nearest(a, 64)) < 0.6, 8, np.where(abs(nearest(a, 16)) < 0.6, 5, 2.5))
        ticks = band(nearest(a, 4), -0.45, 0.45, 0.4) * band(d, 24.5 - tick_len, 24.5, 0.4)
        ticks = np.where(np.asarray(c["corner"]), 0, ticks)
        cut = np.clip(rule + ticks, 0, 1)
        return -0.35 * cut, -0.18 * cut
    return make_frame(motif, "target")


def frame_starry(rng):
    # The Starry Night: swirling lines engraved in the field, a star at each corner
    psi = norm(roll_blur(roll_blur(roll_blur(rng.random((FT, FL)), 9, 1), 9, 1), 4, 0))
    def motif(c, f):
        p = at(psi, c)
        line = np.abs(np.sin(p * np.pi * 9)) < 0.22
        return -0.3 * line, -0.08 * line
    return make_frame(motif, "star")


def frame_wave(rng):
    # The Great Wave: rows of breaking crests engraved along the field
    def motif(c, f):
        d, a = c["d"], c["a"]
        p = (a % 32) / 32
        crest = FIELD[0] + 2 + 11 * p ** 2.2
        line = band(d - crest, -0.5, 0.5, 0.4) * (d > crest - 1)
        curl = band(d - crest - 3, -0.4, 0.4, 0.4) * (p > 0.35)
        cut = np.clip(line + 0.7 * curl, 0, 1)
        return -0.35 * cut, -0.1 * cut
    return make_frame(motif, "ring")


def frame_lilies(rng):
    # Water Lilies: a field of soft dabs, like brushwork pressed into gesso
    dabs = np.zeros((FT, FL))
    dd, aa = np.mgrid[0:FT, 0:FL].astype(float) + 0.5
    for _ in range(110):
        pd, pa = rng.uniform(FIELD[0], FIELD[1]), rng.uniform(0, FL)
        m = np.clip(1 - np.hypot((dd - pd) / 1.4, wrapped(aa - pa, FL) / 3.4), 0, 1)
        dabs += rng.uniform(-1, 1) * np.clip(m * 2.5, 0, 1)
    def motif(c, f):
        v = at(dabs, c)
        return 0.25 * v, 0.06 * v
    return make_frame(motif, "ring")


def frame_scream(rng):
    # The Scream: wavering lines engraved along the field
    def motif(c, f):
        d, a = c["d"], c["a"]
        ph = (d + 2.4 * np.cos(2 * np.pi * a / 64) + 1.0 * np.cos(2 * np.pi * a / 32)) / 4.0
        line = np.abs(ph - np.round(ph)) < 0.12
        return -0.3 * line, -0.08 * line
    return make_frame(motif, "ring")


def frame_mondrian(rng):
    # Composition II: the field divided into panels by cut lines, some panels a shade deeper
    tones = rng.uniform(-0.07, 0.07, size=6)
    def motif(c, f):
        d, a = c["d"], c["a"]
        cuts = band(nearest(a, 128), -0.6, 0.6, 0.4) + band(nearest(a, 128, 41), -0.6, 0.6, 0.4) \
            + band(nearest(a, 128, 86), -0.6, 0.6, 0.4)
        cuts = np.where(np.asarray(c["corner"]), 0, cuts) + band(d, 15.8, 16.6, 0.4) * (np.floor((a % 128) / 41) == 1)
        seg = (np.floor((a % 128) / 43).astype(int) + 3 * (d > 16.2)) % 6
        cut = np.clip(cuts, 0, 1)
        return -0.35 * cut, tones[seg] - 0.12 * cut
    return make_frame(motif, "square")


def frame_nighthawks(rng):
    # Nighthawks: smooth diner trim with a polished inlaid strip down the middle
    def motif(c, f):
        d = c["d"]
        strip = band(d, 14.6, 18.0, 0.5)
        grooves = band(d, 13.6, 14.4, 0.4) + band(d, 18.2, 19.0, 0.4)
        return 0.2 * strip - 0.3 * grooves, 0.10 * strip - 0.1 * grooves
    return make_frame(motif, "ring")


# key (the palette surface key, or "brass" for the start look), maker, seed
FRAME_STYLES = [
    ("brass", frame_brass, 201),
    ("starry", frame_starry, 202),
    ("wave", frame_wave, 203),
    ("kiss", frame_kiss, 204),
    ("lilies", frame_lilies, 205),
    ("scream", frame_scream, 206),
    ("mondrian", frame_mondrian, 207),
    ("nighthawks", frame_nighthawks, 208),
    ("memory", frame_memory, 209),
    ("copper", frame_copper, 210),
    ("neon", frame_neon, 211),
    ("ironforge", frame_ironforge, 212),
    ("verdigris", frame_verdigris, 213),
    ("blueprint", frame_blueprint, 214),
]


def frames():
    for key, make, seed in FRAME_STYLES:
        folder = OUT / "frames" / key
        folder.mkdir(parents=True, exist_ok=True)
        piece = make(np.random.default_rng(seed))
        for name in FRAME_PIECES:
            c = piece_coords(name, False)
            img = light(c, piece(c))
            Image.fromarray((img * 255).round().astype(np.uint8), "RGBA").save(folder / (name + ".tga"))


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    grain(); brushed(); glow(); palettes(); frames()
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.tga"))),
          "+", len(list((OUT / "palettes").glob("*.tga"))), "palette surfaces",
          "+", len(FRAME_STYLES), "frame styles")
