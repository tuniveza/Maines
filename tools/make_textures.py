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
# /maincolor palette plus "brass" for the start look. Unlike the overlays above these are full
# colour and lit (a height field, shaded with a light from the top left), like carved or forged
# picture frames. Each style is eight files in frames/<key>/, laid out the way Maines draws them:
#   tl, tr, bl, br   32x32  the corners (16 UI units square)
#   top, bottom      128x32 edge strips that repeat along their length every 64 UI units
#   left, right      32x128
# 2 texels per UI unit. All eight come from the same two coordinates - d (texels in from the
# frame's outer edge) and a (texels along the edge, 0 at every corner join) - so the strips meet
# the corners without a step, and a strip repeats a whole number of times (the add-on rounds
# the repeat to fit) so it also lands on a join at the far end. Corners are mitred like a
# picture frame (or rounded for the neon, diner and Scream frames); a corner's two halves keep
# the two strips' own patterns and meet on the diagonal.
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


def moulding(d):
    # outer roll, a flat field, an inner bead, then a step down to the window
    return 2.2 * dome((d - 4) / 4) + 1.2 * band(d, 8, 25) + 2.0 * dome((d - 27.5) / 3)


def corner_r(c, cu=16.5, cv=16.5):
    return np.hypot(c["u"] - cu, c["v"] - cv)


def rivets(c, period, phase, dc, radius, height=1.6):
    r = np.hypot(nearest(c["a"], period, phase), c["d"] - dc)
    return np.where(c["corner"], 0, height * dome(r / radius))


def frame_brass(rng):
    # the start look: riveted, brushed brass, a boss in each corner
    streak = strip_field(rng, 20, 0)
    def piece(c):
        d = c["d"]
        h = moulding(d) + rivets(c, 32, 16, 16.5, 3.6)
        r = corner_r(c)
        h = np.maximum(h, 1.2 + 1.6 * dome(r / 7.5) + 1.2 * dome(r / 3))
        ao = 0.6 + 0.4 * np.clip(h / 2.2, 0, 1)
        col = rgb(0.72, 0.53, 0.24) * (0.82 + 0.3 * at(streak, c))[..., None] * ao[..., None]
        return {"height": h, "color": col, "spec": 0.8, "shine": 18}
    return piece


def frame_copper(rng):
    # Gnomeregan Copper: hammered, weathered copper, verdigris creeping into the low spots
    pts = [(rng.uniform(8, 25), rng.uniform(0, FL)) for _ in range(46)]
    dd, aa = np.mgrid[0:FT, 0:FL].astype(float) + 0.5
    f1 = np.full((FT, FL), 1e3)
    for pd, pa in pts:
        f1 = np.minimum(f1, np.hypot(dd - pd, wrapped(aa - pa, FL)))
    dents = -0.9 * dome(f1 / 5.5)
    spots = strip_field(rng, 4, 1)
    def piece(c):
        d = c["d"]
        h = moulding(d) + at(dents, c) * band(d, 8, 25) + rivets(c, 32, 16, 16.5, 3.4, 1.4)
        r = corner_r(c)
        h = np.maximum(h, 1.0 + 1.5 * dome(r / 7) + 1.0 * dome(r / 2.8))
        low = 1 - np.clip(h / 2.2, 0, 1)
        col = mix(rgb(0.74, 0.40, 0.20), rgb(0.34, 0.16, 0.08), 0.45 * low)
        green = np.clip((at(spots, c) - 0.55) * 3 + low * 0.9 - 0.4, 0, 1)
        col = mix(col, rgb(0.33, 0.58, 0.48), green)
        return {"height": h, "color": col, "spec": 0.7 * (1 - green), "shine": 14}
    return piece


def frame_ironforge(rng):
    # Ironforge: blued steel, two cut grooves, slotted bolts
    temper = strip_field(rng, 14, 3)
    streak = strip_field(rng, 26, 0)
    def piece(c):
        d, a = c["d"], c["a"]
        h = 2.0 * np.clip(d / 4, 0, 1) * np.clip((31 - d) / 4, 0, 1)
        h = h - 0.7 * (dome((d - 11) / 1.8) + dome((d - 21) / 1.8))
        da, dr = nearest(a, 64, 32), d - 16
        bolt = 1.5 * dome(np.hypot(da, dr) / 3.6) - 0.6 * band(da + dr, -0.6, 0.6) * (np.hypot(da, dr) < 3.2)
        h = h + np.where(c["corner"], 0, bolt)
        r = corner_r(c)
        cu, cv = c["u"] - 16.5, c["v"] - 16.5
        plate = (np.maximum(abs(cu), abs(cv)) < 8.5) * 1.6
        cbolt = 1.4 * dome(r / 4.2) - 0.6 * band(cu - cv, -0.6, 0.6) * (r < 3.8)
        h = np.maximum(h, plate + cbolt * (r < 4.2))
        t = at(temper, c)
        col = mix(rgb(0.25, 0.31, 0.48), rgb(0.47, 0.40, 0.60), np.clip(t * 1.4 - 0.5, 0, 1))
        col = mix(col, rgb(0.62, 0.66, 0.72), np.clip((h - 1.4) * 0.6, 0, 1))
        col = col * (0.86 + 0.24 * at(streak, c))[..., None]
        return {"height": h, "color": col, "spec": 1.0, "shine": 30}
    return piece


def frame_verdigris(rng):
    # Verdigris Goblin: cast bronze gone green, the patina thickest in the hollows
    patina = strip_field(rng, 6, 2)
    def piece(c):
        d = c["d"]
        h = 2.4 * dome((d - 16) / 13) + 0.9 * dome((d - 2.8) / 2.6) + 0.9 * dome((d - 29) / 2.6)
        r = corner_r(c)
        h = np.maximum(h, 1.4 + 1.4 * dome(r / 6.5))
        low = 1 - np.clip(h / 2.4, 0, 1)
        g = np.clip(at(patina, c) * 1.1 + low * 1.1 - 0.55, 0, 1) ** 0.8
        col = mix(rgb(0.58, 0.40, 0.21), mix(rgb(0.38, 0.62, 0.52), rgb(0.24, 0.44, 0.37), low), g)
        return {"height": h, "color": col, "spec": 0.8 * (1 - g) + 0.05, "shine": 16}
    return piece


def frame_kiss(rng):
    # The Kiss: gilt beads either side of a band of mosaic tesserae, a spiral boss at each corner
    choices = [rgb(0.86, 0.66, 0.24), rgb(0.80, 0.58, 0.18), rgb(0.93, 0.76, 0.34), rgb(0.70, 0.50, 0.16),
               rgb(0.55, 0.12, 0.20), rgb(0.10, 0.08, 0.06), rgb(0.88, 0.86, 0.80), rgb(0.26, 0.42, 0.36)]
    weights = np.array([0.24, 0.2, 0.16, 0.12, 0.1, 0.08, 0.06, 0.04])
    pick = rng.choice(len(choices), size=(3, FL // 8), p=weights / weights.sum())
    tilt = rng.normal(0, 0.10, size=(3, FL // 8, 2))
    def piece(c):
        d, a = c["d"], c["a"]
        gold = rgb(0.84, 0.64, 0.24)
        h = 1.8 * dome((d - 3) / 3) + 1.8 * dome((d - 29) / 3)
        inside = band(d, 6.5, 25.5, 0.5)
        row = np.clip(np.floor((d - 7) / 6), 0, 2).astype(int)
        colm = (np.floor(a / 8).astype(int)) % (FL // 8)
        fd, fa = (d - 7) % 6, a % 8
        grout = np.minimum(np.minimum(fd, 6 - fd), np.minimum(fa, 8 - fa)) < 0.5
        tile = np.stack(choices)[pick[row, colm]]
        tl = tilt[row, colm]
        th = 0.9 + tl[..., 0] * (fd - 3) + tl[..., 1] * (fa - 4)
        h = h + inside * np.where(grout, 0.3, th)
        col = mix(gold[None, None] * np.ones(d.shape + (3,)), np.where(grout[..., None], rgb(0.20, 0.14, 0.07), tile), inside)
        r = corner_r(c)
        theta = np.arctan2(c["v"] - 16.5, c["u"] - 16.5)
        boss = r < 9
        spiral = np.cos(r * 1.5 - theta * 1.0) > 0.7
        h = np.where(boss, 1.4 + 1.2 * dome(r / 9) - 0.4 * spiral, h)
        col = np.where(boss[..., None], np.where(spiral[..., None], rgb(0.55, 0.38, 0.10), rgb(0.93, 0.75, 0.32)), col)
        return {"height": h, "color": col, "spec": 0.9, "shine": 22}
    return piece


def frame_memory(rng):
    # The Persistence of Memory: a gilt frame gone soft - a wavering outline, drips hanging off the
    # bottom, and a melted watch in each corner
    wobble = strip_field(rng, 10, 0)[0]
    drops = [(rng.uniform(0, FL), rng.uniform(3.5, 6.0), rng.uniform(2.5, 4.5)) for _ in range(3)]
    smear = strip_field(rng, 16, 2)
    def piece(c):
        d, a = c["d"], c["a"]
        wob = sample(wobble[None, :].repeat(2, 0), np.zeros_like(a), a - 0.5) * 3.0
        drip = np.zeros_like(a)
        for pa, ln, wd in drops:
            drip = np.maximum(drip, ln * dome(wrapped(a - pa, FL) / wd))
        hang = np.where(c["side"] == "bottom", drip, 0) if np.ndim(c["side"]) else (drip if c["side"] == "bottom" else 0)
        de = d - 6 + wob * 0.6 + hang
        h = 2.6 * dome((de - 11) / 11.5) + 1.6 * dome((de - 24) / 2.5) + 0.6 * dome((de + 0.5 - hang) / 3) * (hang > 0)
        col = rgb(0.82, 0.62, 0.28) * (0.8 + 0.35 * at(smear, c, d=de + 6))[..., None]
        col = col * (0.62 + 0.38 * np.clip(h / 2.6, 0, 1))[..., None]
        # the melted watch: a cream face, sagging, with a gilt rim and two hands
        fu, fv = c["u"] - 15.5, (c["v"] - 15.0) * 1.35
        r = np.hypot(fu, fv)
        face, rim = r < 7.0, (r >= 7.0) & (r < 8.6)
        hands = ((band(fu, -0.5, 0.5, 0.4) > 0.5) & (fv < 0) & (fv > -5.5)) | ((band(fv, -0.5, 0.5, 0.4) > 0.5) & (fu > 0) & (fu < 4.0))
        h = np.where(face, 1.8, np.where(rim, 2.4, h))
        col = np.where(face[..., None], np.where(hands[..., None], rgb(0.18, 0.12, 0.08), rgb(0.92, 0.87, 0.72)), col)
        col = np.where(rim[..., None], rgb(0.88, 0.70, 0.34), col)
        alpha = np.clip(de + 0.5, 0, 1)
        alpha = np.where(face | rim, 1.0, alpha)
        return {"height": h, "color": col, "spec": 0.7, "shine": 18, "alpha": alpha}
    return piece


def frame_neon(rng):
    # Undermine Neon: two glass tubes, hot red and acid green, clipped to a dark backing board
    grit = strip_field(rng, 1, 1)
    def piece(c):
        d, a = c["d"], c["a"]
        h = 1.0 * band(d, 2, 31) + 0.8 * dome((d - 1.2) / 1.6)
        col = rgb(0.09, 0.08, 0.11) * (0.8 + 0.4 * at(grit, c))[..., None]
        col = np.where((d < 2.4)[..., None], rgb(0.42, 0.42, 0.46), col)
        emit = np.zeros(d.shape + (3,))
        for dc, hue, core in ((10.5, rgb(0.95, 0.18, 0.26), rgb(1.0, 0.80, 0.82)),
                              (21.5, rgb(0.20, 0.90, 0.50), rgb(0.85, 1.0, 0.90))):
            x = d - dc
            h = h + 1.3 * dome(x / 2.2)
            emit = emit + hue * (0.75 * np.exp(-(x / 4.0) ** 2))[..., None] + core * np.exp(-(x / 1.0) ** 2)[..., None]
        clip_ = (abs(nearest(a, 64, 32)) < 1.4) & (abs(d - 16) < 8) & ~np.asarray(c["corner"])
        h = np.where(clip_, 2.2, h)
        col = np.where(clip_[..., None], rgb(0.55, 0.55, 0.58), col)
        emit = np.where(clip_[..., None], emit * 0.25, emit)
        return {"height": h, "color": col, "spec": 0.5, "shine": 30, "emit": emit}
    return piece


def frame_blueprint(rng):
    # Blueprint Ink: a drafting border on blue paper - ruled lines, a scale of ticks along the
    # inside, a registration target in each corner
    paper = strip_field(rng, 3, 1)
    def piece(c):
        d, a = c["d"], c["a"]
        corner = np.asarray(c["corner"])
        ink = band(d, 1.0, 2.2) + band(d, 5.0, 5.9) + band(d, 7.0, 7.9) + band(d, 29.4, 30.6)
        ink = ink + 0.18 * (band(nearest(a, 8), -0.45, 0.45) + band(nearest(d, 8, 4), -0.45, 0.45)) * band(d, 9, 20)
        tick_len = np.where(abs(nearest(a, 64)) < 0.6, 9, np.where(abs(nearest(a, 16)) < 0.6, 5, 2.5))
        ticks = band(nearest(a, 4), -0.45, 0.45, 0.5) * band(d, 29.4 - tick_len, 29.6)
        ink = ink + np.where(corner, 0, ticks)
        r = corner_r(c, 15.5, 15.5)
        target = band(r, 5.6, 6.5) + (band(c["u"] - 15.5, -0.4, 0.4) + band(c["v"] - 15.5, -0.4, 0.4)) * (r < 9.5)
        ink = np.clip(ink + np.where(corner, target, 0), 0, 1)
        base = mix(rgb(0.10, 0.24, 0.44), rgb(0.14, 0.31, 0.53), at(paper, c))
        col = mix(base, rgb(0.86, 0.93, 1.0), ink * 0.9)
        return {"height": 0.4 * band(d, 0.5, 31.5) + 0.25 * ink, "color": col, "spec": 0.0}
    return piece


def frame_starry(rng):
    # The Starry Night: thick swirling paint, blue with streaks of yellow, a star at each corner
    psi = norm(roll_blur(roll_blur(roll_blur(rng.random((FT, FL)), 9, 1), 9, 1), 4, 0))
    fy = np.roll(psi, -1, 1) - np.roll(psi, 1, 1)
    fx = -(np.roll(psi, -1, 0) - np.roll(psi, 1, 0)) + 0.01
    mag = np.hypot(fy, fx) + 1e-9
    strokes = norm(lic(fy / mag, fx / mag, (rng.random((FT, FL)) > 0.78).astype(float), steps=10))
    def piece(c):
        d = c["d"]
        s = at(strokes, c)
        p = at(psi, c)
        col = mix(rgb(0.06, 0.12, 0.32), rgb(0.20, 0.36, 0.62), np.clip(p * 1.2, 0, 1))
        col = mix(col, rgb(0.70, 0.82, 0.92), np.clip((s - 0.55) * 2.5, 0, 1) * 0.6)
        col = mix(col, rgb(0.96, 0.82, 0.32), np.clip((s - 0.72) * 4, 0, 1) * (p > 0.55))
        gilt = (d < 2.0) | (d > 29.5)
        col = np.where(gilt[..., None], rgb(0.66, 0.52, 0.24), col)
        h = 1.6 * dome((d - 16) / 15) + 0.9 * s + 0.8 * gilt
        r = corner_r(c)
        star = r < 9.5
        ringc = mix(rgb(0.98, 0.86, 0.40), rgb(0.30, 0.45, 0.70), (np.cos(r * 1.4) * 0.5 + 0.5) * (r > 3))
        col = np.where(star[..., None], np.where((r < 3)[..., None], rgb(1.0, 0.96, 0.75), ringc), col)
        h = np.where(star, 1.6 + 0.4 * np.cos(r * 1.4), h)
        emit = np.where(star[..., None], rgb(0.25, 0.20, 0.05) * np.exp(-(r / 4) ** 2)[..., None], 0)
        return {"height": h, "color": col, "spec": 0.25, "shine": 10, "emit": emit}
    return piece


def frame_wave(rng):
    # The Great Wave: carved lacquer - rows of breaking crests with curling foam against a pale
    # sky, and a red artist's seal in each corner
    foam = strip_field(rng, 1, 0)
    def piece(c):
        d, a = c["d"], c["a"]
        p = (a % 32) / 32
        crest = 8 + 10 * p ** 2.2
        below = d - crest
        water = below > 0
        sky = rgb(0.88, 0.82, 0.68)
        sea = mix(rgb(0.30, 0.50, 0.68), rgb(0.08, 0.18, 0.34), np.clip(below / 12, 0, 1))
        col = np.where(water[..., None], sea, sky)
        froth = band(below, -0.2, 1.8, 0.5) + (p > 0.6) * (at(foam, c) > 0.6) * band(below, -4.5, 0, 0.5)
        col = mix(col, rgb(0.97, 0.95, 0.90), np.clip(froth, 0, 1))
        h = 0.5 + 0.8 * water + 0.6 * np.clip(froth, 0, 1)
        rim = (d < 1.6) | (d > 28.5)
        col = np.where(rim[..., None], rgb(0.18, 0.12, 0.09), col)
        h = np.where(rim, 1.6 + 0.4 * dome((d - 30.2) / 1.8), h)
        su, sv = c["u"] - 15.5, c["v"] - 15.5
        seal = np.maximum(abs(su), abs(sv)) < 5.5
        mark = seal & ((band(su, -3.5, -2.5, 0.4) + band(sv, 1.5, 2.5, 0.4) + band(su + sv, -0.5, 0.5, 0.4)) > 0.5) & (np.maximum(abs(su), abs(sv)) < 4)
        col = np.where(seal[..., None], np.where(mark[..., None], rgb(0.95, 0.88, 0.80), rgb(0.72, 0.16, 0.12)), col)
        h = np.where(seal, 1.2, h)
        return {"height": h, "color": col, "spec": 0.35, "shine": 26}
    return piece


def frame_lilies(rng):
    # Water Lilies: soft painted wood dabbed in pond colours, a lily pad at each corner
    base = np.zeros((FT, FL, 3)) + rgb(0.42, 0.57, 0.56)
    swell = strip_field(rng, 8, 3)
    base = mix(base, rgb(0.34, 0.46, 0.62), swell)
    dab_h = np.zeros((FT, FL))
    dd, aa = np.mgrid[0:FT, 0:FL].astype(float) + 0.5
    colours = [rgb(0.76, 0.62, 0.78), rgb(0.80, 0.84, 0.66), rgb(0.88, 0.67, 0.72), rgb(0.26, 0.38, 0.56), rgb(0.35, 0.55, 0.38)]
    for _ in range(150):
        pd, pa = rng.uniform(2, 30), rng.uniform(0, FL)
        m = np.clip(1 - np.hypot((dd - pd) / 1.3, wrapped(aa - pa, FL) / 3.2), 0, 1)
        m = np.clip(m * 3, 0, 1)
        base = mix(base, colours[rng.integers(len(colours))], m * 0.85)
        dab_h = np.maximum(dab_h, m)
    def piece(c):
        d = c["d"]
        col = np.stack([at(base[..., i], c) for i in range(3)], -1)
        h = 1.8 * dome((d - 16) / 15) + 0.7 * dome((d - 2.6) / 2.6) + 0.7 * dome((d - 29.4) / 2.6) + 0.5 * at(dab_h, c)
        gilt = (d < 1.4) | (d > 30.4)
        col = np.where(gilt[..., None], rgb(0.72, 0.62, 0.40), col)
        pu, pv = c["u"] - 15.5, c["v"] - 15.5
        r = np.hypot(pu, pv)
        ang = np.arctan2(pv, pu)
        pad = (r < 8.5) & ~((ang > 0.55) & (ang < 1.05))
        flower = np.hypot(pu + 3, pv + 3) < 2.6
        col = np.where(pad[..., None], mix(rgb(0.30, 0.52, 0.30), rgb(0.46, 0.66, 0.38), np.clip(1 - r / 8.5, 0, 1)), col)
        col = np.where(flower[..., None], rgb(0.95, 0.70, 0.78), col)
        h = np.where(pad | flower, 1.5 + 0.5 * flower, h)
        return {"height": h, "color": col, "spec": 0.2, "shine": 12}
    return piece


def frame_scream(rng):
    # The Scream: wavering bands of orange, yellow, blood red and blue running round a rounded frame
    streak = strip_field(rng, 12, 0)
    stops = [rgb(0.91, 0.42, 0.17), rgb(0.95, 0.68, 0.35), rgb(0.55, 0.13, 0.09), rgb(0.18, 0.23, 0.44), rgb(0.85, 0.50, 0.22)]
    def piece(c):
        d, a = c["d"], c["a"]
        ph = (d + 3.2 * np.cos(2 * np.pi * a / 64) + 1.4 * np.cos(2 * np.pi * a / 32)) / 5.5
        i = np.floor(ph).astype(int) % len(stops)
        f = ph - np.floor(ph)
        t = np.clip((f - 0.7) / 0.3, 0, 1)
        col = mix(np.stack(stops)[i], np.stack(stops)[(i + 1) % len(stops)], t)
        col = col * (0.85 + 0.25 * at(streak, c))[..., None]
        h = 1.4 * dome((d - 16) / 15.5) + 0.3 * np.sin(ph * 2 * np.pi)
        rim = (d < 1.3) | (d > 30.6)
        col = np.where(rim[..., None], rgb(0.16, 0.10, 0.08), col)
        return {"height": h, "color": col, "spec": 0.15, "shine": 10}
    return piece


def frame_mondrian(rng):
    # Composition II: flat white, black bars, and a block of primary colour in each corner and
    # along each side
    tooth = strip_field(rng, 1, 1)
    sides = {"top": rgb(0.83, 0.04, 0.12), "bottom": rgb(0.07, 0.34, 0.64), "left": rgb(0.97, 0.85, 0.26), "right": rgb(0.95, 0.95, 0.92)}
    corners = {"tl": rgb(0.07, 0.34, 0.64), "tr": rgb(0.97, 0.85, 0.26), "bl": rgb(0.83, 0.04, 0.12), "br": rgb(0.95, 0.95, 0.92)}
    def piece(c):
        d, a = c["d"], c["a"]
        white = rgb(0.95, 0.94, 0.89)
        col = np.zeros(d.shape + (3,)) + white
        if c["corner"]:
            col[:] = corners[c["piece"]]
        else:
            seg = band(nearest(a, 128, 63), -21, 21, 0.5)
            col = mix(col, sides[c["side"]], seg)
        black = band(d, -1, 2.6, 0.5) + band(d, 27, 40, 0.5)
        black = black + np.where(c["corner"], 0, band(nearest(a, 128), -1.6, 1.6, 0.5)
                                 + band(nearest(a, 128, 41), -1.6, 1.6, 0.5) + band(nearest(a, 128, 86), -1.6, 1.6, 0.5))
        black = black + (np.asarray(c["corner"]) * band(np.maximum(c["u"], c["v"]), 30.4, 40, 0.5))
        col = mix(col, rgb(0.08, 0.08, 0.08), np.clip(black, 0, 1))
        col = col * (0.95 + 0.08 * at(tooth, c))[..., None]
        return {"height": 0.2 * at(tooth, c), "color": col, "spec": 0.0}
    return piece


def frame_nighthawks(rng):
    # Nighthawks: diner trim - a chrome roll, green enamel, and a strip of warm light inside
    def piece(c):
        d = c["d"]
        chrome = d < 6
        h = 1.8 * dome((d - 3) / 3) + 1.0 * band(d, 6, 20.5) + 0.6 * dome((d - 31) / 1.2)
        col = np.zeros(d.shape + (3,)) + rgb(0.13, 0.30, 0.27)
        col = np.where(chrome[..., None], rgb(0.74, 0.76, 0.80), col)
        col = np.where((d > 25.5)[..., None], rgb(0.08, 0.07, 0.06), col)
        col = np.where((d > 30.2)[..., None], rgb(0.70, 0.72, 0.76), col)
        lamp = band(d, 21, 25, 0.6)
        col = mix(col, rgb(0.98, 0.90, 0.64), lamp)
        emit = rgb(0.45, 0.34, 0.14) * np.exp(-((d - 23) / 4.5) ** 2)[..., None]
        spec = np.where(chrome | (d > 30.2), 1.0, 0.45)
        return {"height": h, "color": col, "spec": spec, "shine": 28, "emit": emit}
    return piece


# key (the palette surface key, or "brass" for the start look), maker, seed, rounded corners
FRAME_STYLES = [
    ("brass", frame_brass, 201, False),
    ("starry", frame_starry, 202, False),
    ("wave", frame_wave, 203, False),
    ("kiss", frame_kiss, 204, False),
    ("lilies", frame_lilies, 205, False),
    ("scream", frame_scream, 206, True),
    ("mondrian", frame_mondrian, 207, False),
    ("nighthawks", frame_nighthawks, 208, True),
    ("memory", frame_memory, 209, False),
    ("copper", frame_copper, 210, False),
    ("neon", frame_neon, 211, True),
    ("ironforge", frame_ironforge, 212, False),
    ("verdigris", frame_verdigris, 213, False),
    ("blueprint", frame_blueprint, 214, False),
]


def frames():
    for key, make, seed, rounded in FRAME_STYLES:
        folder = OUT / "frames" / key
        folder.mkdir(parents=True, exist_ok=True)
        piece = make(np.random.default_rng(seed))
        for name in FRAME_PIECES:
            c = piece_coords(name, rounded)
            img = light(c, piece(c))
            Image.fromarray((img * 255).round().astype(np.uint8), "RGBA").save(folder / (name + ".tga"))


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    grain(); brushed(); glow(); palettes(); frames()
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.tga"))),
          "+", len(list((OUT / "palettes").glob("*.tga"))), "palette surfaces",
          "+", len(FRAME_STYLES), "frame styles")
