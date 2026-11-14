#!/usr/bin/env python3
"""Generate the 1024x1024 Harvest Hollow app icon from a 32x32 pixel grid.

No third-party dependencies: PNGs are written with zlib + struct from the
Python standard library, which keeps the asset reproducible on any machine.
"""

import shutil
import struct
import zlib
from pathlib import Path

W = H = 32
SCALE = 32
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Apps/HarvestHollow/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
DOCS_ICON = ROOT / "docs/icon.png"

SKY_TOP = "#BEE4E8"
SKY_1 = "#CEE8DF"
SKY_2 = "#E7E7CE"
SKY_3 = "#F7E4C0"
SUN_HALO = "#F9DC93"
SUN = "#F6C453"
SUN_LIGHT = "#FFD97A"
CLOUD = "#FFFDF4"
HILL_FAR = "#A9C98D"
HILL_FAR_LIGHT = "#B8D49C"
HILL = "#7FA85F"
HILL_LIGHT = "#92B96D"
HILL_DARK = "#6F9852"
SOIL = "#8A5A3B"
SOIL_LIGHT = "#9F6C4A"
SOIL_DARK = "#734A33"
BARN = "#C9654F"
BARN_DARK = "#A94E3F"
BARN_LIGHT = "#D97B62"
ROOF = "#7D3A33"
ROOF_LIGHT = "#9C4A3E"
TRIM = "#F4DFC0"
WINDOW = "#F5C85C"
WINDOW_DARK = "#C99A3F"
DOOR = "#5A382A"
DOOR_LIGHT = "#6E4636"
PIG = "#E79AA8"
PIG_DARK = "#C97A88"
PIG_SNOUT = "#F2B6BE"
PIG_EYE = "#3B2A28"
LEAF = "#4F7D4A"
LEAF_LIGHT = "#6B9C5C"
WHEAT = "#E4B54E"
FLOWER_PINK = "#F2A7B5"
FLOWER_YELLOW = "#F6D05E"

grid = [[SKY_TOP for _ in range(W)] for _ in range(H)]


def px(x, y, color):
    if 0 <= x < W and 0 <= y < H:
        grid[y][x] = color


def rect(x0, y0, x1, y1, color):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(x, y, color)


def circle(cx, cy, radius, color):
    for y in range(H):
        for x in range(W):
            if (x - cx) ** 2 + (y - cy) ** 2 <= radius ** 2:
                px(x, y, color)


def ellipse(cx, cy, rx, ry, color):
    for y in range(H):
        for x in range(W):
            nx = (x - cx) / rx
            ny = (y - cy) / ry
            if nx * nx + ny * ny <= 1:
                px(x, y, color)


# Sky bands.
for y in range(0, 5):
    for x in range(W):
        px(x, y, SKY_TOP)
for y in range(5, 10):
    for x in range(W):
        px(x, y, SKY_1)
for y in range(10, 15):
    for x in range(W):
        px(x, y, SKY_2)
for y in range(15, 21):
    for x in range(W):
        px(x, y, SKY_3)

# Sun with a soft halo.
circle(25, 5, 4, SUN_HALO)
circle(25, 5, 3, SUN)
circle(24, 4, 1, SUN_LIGHT)
for x, y in [(20, 1), (21, 2), (29, 1), (28, 2), (20, 9), (21, 8), (30, 9), (29, 8), (25, 0), (25, 10), (18, 5), (31, 5)]:
    px(x, y, SUN)

# Clouds.
rect(3, 5, 8, 6, CLOUD)
px(4, 4, CLOUD)
px(5, 4, CLOUD)
px(7, 4, CLOUD)
px(8, 5, CLOUD)
rect(2, 6, 9, 6, CLOUD)

rect(14, 10, 18, 11, CLOUD)
px(15, 9, CLOUD)
px(16, 9, CLOUD)
px(17, 9, CLOUD)
px(14, 10, CLOUD)
px(18, 10, CLOUD)

# Rolling hills.
for x in range(W):
    top = 19 - int(2.2 * abs(((x + 5) % 20) - 10) / 10)
    for y in range(top, 24):
        px(x, y, HILL_FAR)
for x in range(W):
    if 4 <= x <= 12:
        px(x, 20, HILL_FAR_LIGHT)
    if 20 <= x <= 28:
        px(x, 19, HILL_FAR_LIGHT)

for x in range(W):
    top = 22 - int(1.6 * abs(((x + 2) % 18) - 9) / 9)
    for y in range(top, H):
        px(x, y, HILL)
for x in range(W):
    if x % 7 == 0:
        px(x, 24, HILL_LIGHT)
    if x % 9 == 3:
        px(x, 25, HILL_DARK)

# Barn shadow and walls.
rect(8, 26, 23, 27, HILL_DARK)
rect(9, 18, 22, 26, BARN)
rect(9, 18, 22, 18, BARN_LIGHT)
rect(21, 19, 22, 26, BARN_DARK)

# Roof: stepped triangle with a warm highlight.
roof_rows = [(15, 16), (14, 17), (13, 18), (12, 19), (11, 20), (9, 22)]
for index, (x0, x1) in enumerate(roof_rows):
    y = 12 + index
    rect(x0, y, x1, y, ROOF)
    px(x0, y, ROOF_LIGHT)
    px(x0 + 1, y, ROOF_LIGHT)
px(15, 11, ROOF_LIGHT)
px(16, 11, ROOF_LIGHT)

# White trim, loft window, side windows and big barn door.
rect(9, 18, 22, 18, TRIM)
rect(9, 18, 9, 26, TRIM)
rect(22, 18, 22, 26, TRIM)

rect(14, 19, 17, 20, DOOR)
rect(15, 19, 16, 20, WINDOW)
px(15, 20, WINDOW_DARK)

rect(10, 21, 11, 22, DOOR)
rect(10, 21, 11, 21, WINDOW)

rect(13, 21, 18, 26, TRIM)
rect(14, 21, 17, 26, DOOR)
rect(14, 21, 17, 21, DOOR_LIGHT)
px(15, 23, DOOR_LIGHT)
px(16, 23, DOOR_LIGHT)
px(15, 25, DOOR_LIGHT)
px(16, 25, DOOR_LIGHT)
px(15, 24, WINDOW_DARK)
px(16, 24, WINDOW_DARK)

# Little pig on the grass to the right of the barn.
rect(23, 25, 23, 26, PIG_SNOUT)
rect(23, 26, 23, 26, PIG_DARK)
px(24, 24, PIG_DARK)
px(27, 24, PIG_DARK)
ellipse(26.5, 25.5, 3.0, 1.8, PIG)
rect(24, 26, 28, 26, PIG)
px(24, 25, PIG_EYE)
px(23, 25, PIG_SNOUT)
px(23, 26, PIG_SNOUT)
px(25, 27, PIG_DARK)
px(28, 27, PIG_DARK)
px(29, 24, PIG_DARK)
px(30, 24, PIG_DARK)
rect(23, 27, 30, 27, HILL_DARK)

# Foreground field.
rect(0, 28, W - 1, 29, SOIL)
rect(0, 30, W - 1, 30, SOIL_LIGHT)
rect(0, 31, W - 1, 31, SOIL_DARK)
for x in range(0, W, 4):
    px(x, 29, SOIL_DARK)
    px(x + 1, 30, SOIL_DARK)
    px(x + 3, 28, SOIL_LIGHT)

# A row of little crops across the field.
for x in range(2, 23, 4):
    px(x, 28, LEAF)
    px(x, 27, LEAF_LIGHT)
    px(x - 1, 27, LEAF)
    px(x + 1, 27, LEAF)
    px(x, 26, WHEAT)
    px(x, 25, WHEAT)
    px(x, 29, LEAF_LIGHT)

# Flowers and grass tufts on the left bank.
for x, y, color in [
    (2, 26, FLOWER_PINK), (4, 26, FLOWER_YELLOW), (5, 27, FLOWER_PINK),
    (7, 26, FLOWER_YELLOW), (1, 27, FLOWER_PINK), (3, 27, LEAF_LIGHT),
    (6, 26, LEAF_LIGHT), (8, 27, LEAF_LIGHT), (19, 26, FLOWER_PINK),
    (20, 27, FLOWER_YELLOW), (21, 26, LEAF_LIGHT),
]:
    px(x, y, color)

# A little path to the barn door.
for y in range(27, 32):
    for x in range(14, 18):
        px(x, y, SOIL_LIGHT if (x + y) % 2 == 0 else SOIL)
    px(14, y, SOIL_DARK)
    px(17, y, SOIL_DARK)


def write_png(path, pixels, width, height):
    rows = []
    for y in range(height):
        row = b"\x00"
        for x in range(width):
            row += bytes(pixels[y][x])
        rows.append(row)
    raw = b"".join(rows)

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    idat = zlib.compress(raw, 9)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b""))


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


pixels = [[hex_rgb(grid[y][x]) for x in range(W)] for y in range(H)]
large = [[pixels[y // SCALE][x // SCALE] for x in range(W * SCALE)] for y in range(H * SCALE)]
write_png(OUT, large, W * SCALE, H * SCALE)
DOCS_ICON.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(OUT, DOCS_ICON)
print(f"wrote {OUT} ({W * SCALE}x{H * SCALE}) and {DOCS_ICON}")
