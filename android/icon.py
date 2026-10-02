#!/usr/bin/env python3
"""Bakes the Android launcher icon out of the cool S.

The S is read straight out of `Sprites.COOLS` in src/sprites.lua rather than
copied here, so the icon follows the art if the art ever changes. It goes down
in ink on white, scaled by a whole number at every density for the same reason
nothing in the game is ever drawn at a fractional scale: a 9x17 drawing
resampled to fit a box comes out as a grey smear.

Two sets are written into a love-android checkout's res/ directory:

- drawable-*dpi/love.png, the square legacy icon (48dp), which is what the
  manifest's @drawable/love names and what launchers before Android 8 use;
- drawable-*dpi/love_fg.png plus drawable-anydpi-v26/love.xml, the adaptive
  icon (108dp, the S kept well inside the 66dp the launcher promises not to
  mask), which every launcher since then prefers over the legacy one.

Standard library only (zlib), so the workflow needs nothing installed.

    python3 android/icon.py <love-android>/app/src/main/res
"""

import os
import re
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

INK = (0x28, 0x07, 0x32)    # Palette.ink
WHITE = (0xFF, 0xFF, 0xFF)

# (density, legacy px, legacy scale, foreground px, foreground scale). The
# legacy S stands about 70% of its square; the adaptive one about half of its
# 108dp, which keeps the whole S inside the safe circle on every mask shape.
DENSITIES = [
    ("mdpi",    48, 2, 108, 3),
    ("hdpi",    72, 3, 162, 5),
    ("xhdpi",   96, 4, 216, 6),
    ("xxhdpi", 144, 6, 324, 9),
    ("xxxhdpi", 192, 8, 432, 12),
]


def read_cools():
    with open(os.path.join(ROOT, "src", "sprites.lua"), encoding="utf-8") as f:
        source = f.read()
    block = re.search(r"Sprites\.COOLS\s*=\s*\{(.*?)\n\}", source, re.S)
    if not block:
        sys.exit("icon.py: Sprites.COOLS not found in src/sprites.lua")
    rows = re.findall(r'"([^"]*)"', block.group(1))
    if not rows or len({len(r) for r in rows}) != 1:
        sys.exit("icon.py: Sprites.COOLS is not a grid of equal-length rows")
    return rows


def png(path, size, pixels):
    """pixels(x, y) -> (r, g, b, a). Writes an 8-bit RGBA PNG."""
    raw = bytearray()
    for y in range(size):
        raw.append(0)  # filter: none
        for x in range(size):
            raw.extend(pixels(x, y))

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


def stamp(rows, size, scale, background):
    w, h = len(rows[0]) * scale, len(rows) * scale
    ox, oy = (size - w) // 2, (size - h) // 2

    def pixel(x, y):
        gx, gy = x - ox, y - oy
        if 0 <= gx < w and 0 <= gy < h and rows[gy // scale][gx // scale] != ".":
            return INK + (255,)
        return background

    return pixel


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    res = sys.argv[1]
    rows = read_cools()

    for density, size, scale, fg_size, fg_scale in DENSITIES:
        folder = os.path.join(res, "drawable-" + density)
        png(os.path.join(folder, "love.png"), size, stamp(rows, size, scale, WHITE + (255,)))
        png(os.path.join(folder, "love_fg.png"), fg_size, stamp(rows, fg_size, fg_scale, (0, 0, 0, 0)))

    adaptive = os.path.join(res, "drawable-anydpi-v26")
    os.makedirs(adaptive, exist_ok=True)
    with open(os.path.join(adaptive, "love.xml"), "w", encoding="utf-8") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@android:color/white" />\n'
            '    <foreground android:drawable="@drawable/love_fg" />\n'
            '</adaptive-icon>\n'
        )


if __name__ == "__main__":
    main()
