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


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    grain(); brushed(); glow(); palettes()
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.tga"))),
          "+", len(list((OUT / "palettes").glob("*.tga"))), "palette surfaces")
