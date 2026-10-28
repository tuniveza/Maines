#!/usr/bin/env python3
"""Rebuilds Maines' surface textures in textures/ (run from anywhere: python3 tools/make_textures.py).

grain.tga    - tileable paper grain laid over every parchment panel
brushed.tga  - tileable brushed-brass streaks for the title band
glow.tga     - soft round falloff; its quarters and centre lines build the window's outer glow

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


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    grain(); brushed(); glow()
    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.tga"))))
