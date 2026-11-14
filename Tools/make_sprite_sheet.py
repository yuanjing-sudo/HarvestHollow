#!/usr/bin/env python3
"""Render the in-game pixel sprites into docs/sprites.png.

The sheet is generated directly from Sources/HarvestHollowCore/PixelArt.swift
so it can never drift from the actual art. Dependencies: Python standard
library only.
"""

import re
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Sources/HarvestHollowCore/PixelArt.swift"
OUT = ROOT / "docs/sprites.png"

CREAM = "#F7F1E3"
PAPER = "#FFFBF1"
PANEL_BORDER = "#E6D8C3"
INK = "#3A2E28"
FOREST = "#3E6B4F"
TERRACOTTA = "#C96A4B"

FONT = {
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
    "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
    "H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
    "I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
    "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "W": ["10001", "10001", "10001", "10101", "10101", "11011", "10001"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
}


def parse_sprites():
    text = SOURCE.read_text()
    block = re.compile(
        r'PixelSprite\(\s*key:\s*"([^"]+)",\s*width:\s*(\d+),\s*'
        r'palette:\s*\[(.*?)\],\s*rows:\s*\[(.*?)\]\s*\)',
        re.S,
    )
    color = re.compile(r'"([^"]+)"\s*:\s*"([0-9A-Fa-f]{6})"')
    row = re.compile(r'"([^"]*)"')

    sprites = []
    for match in block.finditer(text):
        key, width, palette_text, rows_text = match.groups()
        palette = {char: "#" + hex_value for char, hex_value in color.findall(palette_text)}
        rows = [value for value in row.findall(rows_text)]
        sprites.append(
            {
                "key": key,
                "width": int(width),
                "height": len(rows),
                "palette": palette,
                "rows": rows,
            }
        )
    return sprites


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def blend(rgb, alpha, bg):
    return tuple(round(rgb[i] * alpha + bg[i] * (1 - alpha)) for i in range(3))


def draw_text(pixels, x, y, text, scale, color):
    rgb = hex_rgb(color)
    cursor = x
    for char in text:
        if char == " ":
            cursor += 6 * scale
            continue
        glyph = FONT[char]
        for row_index, row in enumerate(glyph):
            for col_index, bit in enumerate(row):
                if bit == "1":
                    for dy in range(scale):
                        for dx in range(scale):
                            px = cursor + col_index * scale + dx
                            py = y + row_index * scale + dy
                            if 0 <= py < len(pixels) and 0 <= px < len(pixels[0]):
                                pixels[py][px] = rgb
        cursor += 6 * scale


def draw_text_centered(pixels, y, text, scale, color):
    width = len(text) * 6 * scale - scale
    x = (len(pixels[0]) - width) // 2
    draw_text(pixels, x, y, text, scale, color)


def main():
    sprites = parse_sprites()
    if len(sprites) != 38:
        raise SystemExit(f"expected 38 sprites, found {len(sprites)}")

    groups = [
        ("ANIMALS", [s for s in sprites if s["key"].startswith("animal.")]),
        ("CROPS", [s for s in sprites if s["key"].startswith("crop.")]),
        ("FURNITURE", [s for s in sprites if s["key"].startswith("furniture.")]),
        ("ITEMS", [s for s in sprites if s["key"].startswith("item.")]),
    ]

    margin = 40
    cell_w = 92
    cell_h = 88
    columns = 9
    width = margin * 2 + columns * cell_w
    header = 124

    # Each group has a label and one or more rows.
    def row_count_for(name, items):
        per_row = 7 if name == "FURNITURE" else columns
        return max(1, (len(items) + per_row - 1) // per_row)

    height = header + sum(16 + row_count_for(name, items) * cell_h + 12 for name, items in groups) + 58

    pixels = [[hex_rgb(CREAM) for _ in range(width)] for _ in range(height)]

    # Header band.
    for y in range(96):
        for x in range(width):
            pixels[y][x] = hex_rgb("#FBEFD8")
    for x in range(width):
        pixels[96][x] = hex_rgb("#EADCC6")

    draw_text_centered(pixels, 24, "HARVEST HOLLOW", 5, INK)
    draw_text_centered(pixels, 66, "SPRITE LIBRARY", 2, TERRACOTTA)
    draw_text(pixels, width - margin - 64, 22, "38", 3, FOREST)

    y = header
    for name, items in groups:
        draw_text(pixels, margin, y, name, 2, FOREST)
        for x in range(margin + 12 * 6 * 2, width - margin):
            pixels[y + 7][x] = hex_rgb("#E6D8C3")
        y += 18

        per_row = 7 if name == "FURNITURE" else columns
        row_count = max(1, (len(items) + per_row - 1) // per_row)
        for row in range(row_count):
            row_items = items[row * per_row:(row + 1) * per_row]
            offset = (columns - len(row_items)) // 2 if row_count == 1 or name != "FURNITURE" else 1
            for col, sprite in enumerate(row_items):
                panel_x = margin + (col + offset) * cell_w + 4
                panel_y = y + 4
                panel_w = cell_w - 8
                panel_h = cell_h - 8
                for py in range(panel_y, panel_y + panel_h):
                    for px in range(panel_x, panel_x + panel_w):
                        pixels[py][px] = hex_rgb(PAPER)
                for px in range(panel_x, panel_x + panel_w):
                    pixels[panel_y][px] = hex_rgb(PANEL_BORDER)
                    pixels[panel_y + panel_h - 1][px] = hex_rgb(PANEL_BORDER)
                for py in range(panel_y, panel_y + panel_h):
                    pixels[py][panel_x] = hex_rgb(PANEL_BORDER)
                    pixels[py][panel_x + panel_w - 1] = hex_rgb(PANEL_BORDER)

                scale = min(
                    5,
                    (panel_w - 10) // max(1, sprite["width"]),
                    (panel_h - 10) // max(1, sprite["height"]),
                )
                scale = max(2, scale)
                art_w = sprite["width"] * scale
                art_h = sprite["height"] * scale
                origin_x = panel_x + (panel_w - art_w) // 2
                origin_y = panel_y + (panel_h - art_h) // 2

                for row_index, row_text in enumerate(sprite["rows"]):
                    for col_index, char in enumerate(row_text):
                        if char == "." or char not in sprite["palette"]:
                            continue
                        rgb = hex_rgb(sprite["palette"][char])
                        for dy in range(scale):
                            for dx in range(scale):
                                px = origin_x + col_index * scale + dx
                                py = origin_y + row_index * scale + dy
                                if 0 <= py < height and 0 <= px < width:
                                    pixels[py][px] = rgb
            y += cell_h
        y += 12

    draw_text_centered(pixels, height - 34, "MADE IN SWIFT", 2, FOREST)

    write_png(OUT, pixels, width, height)
    print(f"wrote {OUT} ({width}x{height}) with {len(sprites)} sprites")


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


if __name__ == "__main__":
    main()
