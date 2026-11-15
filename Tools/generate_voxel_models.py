#!/usr/bin/env python3
"""Procedurally sculpts the Harvest Hollow voxel model library.

The output is deliberately data-heavy: every voxel is a line of source, so the
3D tab is a real miniature model kit rather than a handful of stretched cubes.
Run from the repository root: python3 Tools/generate_voxel_models.py
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Sources" / "HarvestHollowCore"


@dataclass
class Sculpt:
    voxels: dict[tuple[int, int, int], tuple[str, str]] = field(default_factory=dict)

    def add(self, x: int, y: int, z: int, color: str, material: str) -> None:
        self.voxels[(int(x), int(y), int(z))] = (color.replace("#", "").upper(), material)

    def box(self, x0: int, x1: int, y0: int, y1: int, z0: int, z1: int,
            color: str | list[str], material: str, hollow: bool = False,
            checker: int = 0) -> None:
        colors = color if isinstance(color, list) else [color]
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for z in range(min(z0, z1), max(z0, z1) + 1):
                for x in range(min(x0, x1), max(x0, x1) + 1):
                    if hollow and not (x in (x0, x1) or y in (y0, y1) or z in (z0, z1)):
                        continue
                    idx = 0
                    if checker:
                        idx = ((x // checker) + (y // checker) + (z // checker)) % len(colors)
                    self.add(x, y, z, colors[idx], material)

    def ellipsoid(self, cx: float, cy: float, cz: float, rx: float, ry: float, rz: float,
                  color: str | list[str], material: str, hollow: bool = False,
                  shell: float = 0.62, checker: int = 0) -> None:
        colors = color if isinstance(color, list) else [color]
        for y in range(math.floor(cy - ry), math.ceil(cy + ry) + 1):
            for z in range(math.floor(cz - rz), math.ceil(cz + rz) + 1):
                for x in range(math.floor(cx - rx), math.ceil(cx + rx) + 1):
                    dx = (x - cx) / max(0.1, rx)
                    dy = (y - cy) / max(0.1, ry)
                    dz = (z - cz) / max(0.1, rz)
                    d = dx * dx + dy * dy + dz * dz
                    if d > 1:
                        continue
                    if hollow and d < shell:
                        continue
                    idx = 0
                    if checker:
                        idx = ((x // checker) + (y // checker) + (z // checker)) % len(colors)
                    self.add(x, y, z, colors[idx], material)

    def cylinder(self, cx: int, cz: int, y0: int, y1: int, radius: float,
                 color: str | list[str], material: str, hollow: bool = False) -> None:
        colors = color if isinstance(color, list) else [color]
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for z in range(math.floor(cz - radius), math.ceil(cz + radius) + 1):
                for x in range(math.floor(cx - radius), math.ceil(cx + radius) + 1):
                    d = math.hypot(x - cx, z - cz)
                    if d > radius:
                        continue
                    if hollow and d < radius - 1:
                        continue
                    idx = (x + z + y) % len(colors)
                    self.add(x, y, z, colors[idx], material)

    def line(self, a: tuple[int, int, int], b: tuple[int, int, int],
             color: str, material: str, thickness: int = 1) -> None:
        steps = max(abs(b[0] - a[0]), abs(b[1] - a[1]), abs(b[2] - a[2]), 1)
        for i in range(steps + 1):
            t = i / steps
            x = round(a[0] + (b[0] - a[0]) * t)
            y = round(a[1] + (b[1] - a[1]) * t)
            z = round(a[2] + (b[2] - a[2]) * t)
            if thickness <= 1:
                self.add(x, y, z, color, material)
            else:
                self.box(x - thickness // 2, x + thickness // 2,
                         y - thickness // 2, y + thickness // 2,
                         z - thickness // 2, z + thickness // 2,
                         color, material)

    def gable(self, x0: int, x1: int, y0: int, z0: int, z1: int,
              color: str, material: str, trim: str | None = None) -> None:
        width = x1 - x0
        height = max(2, width // 2 + 2)
        for step in range(height):
            half = max(0, (width - step * 2) // 2)
            self.box(-half, half, y0 + step, y0 + step, z0, z1, color, material)
            if trim and step == height - 1:
                self.box(-half, half, y0 + step + 1, y0 + step + 1, z0, z1, trim, material)

    def roof(self, x0: int, x1: int, y0: int, z0: int, z1: int,
             color: str, material: str) -> None:
        width = x1 - x0
        rows = max(2, width // 2 + 2)
        for step in range(rows):
            inset = step
            self.box(x0 + inset, x1 - inset, y0 + step, y0 + step, z0, z1, color, material)

    def tree_crown(self, cx: float, cy: float, cz: float, radius: float,
                   colors: list[str], material: str = "leaf") -> None:
        self.ellipsoid(cx, cy, cz, radius, radius * 0.9, radius,
                       colors, material, hollow=True, shell=0.48, checker=2)
        self.ellipsoid(cx + radius * 0.5, cy + radius * 0.3, cz - radius * 0.2,
                       radius * 0.62, radius * 0.6, radius * 0.62,
                       colors, material, hollow=True, shell=0.48, checker=2)
        self.ellipsoid(cx - radius * 0.55, cy + radius * 0.15, cz + radius * 0.26,
                       radius * 0.58, radius * 0.6, radius * 0.58,
                       colors, material, hollow=True, shell=0.48, checker=2)

    def rows(self) -> list[str]:
        return [f"{x},{y},{z},{color},{material}"
                for (x, y, z), (color, material) in sorted(self.voxels.items(), key=lambda item: (item[0][1], item[0][2], item[0][0]))]


MODELS: list[tuple[str, str, str, str, Sculpt]] = []


def model(mid: str, name: str, category: str, notes: str):
    def register(fn):
        s = Sculpt()
        fn(s)
        MODELS.append((mid, name, category, notes, s))
        return fn
    return register


PINK = ["F3A6B8", "F7B7C7", "EC98AD", "FFC3D0"]
DARK_PINK = "D97B92"
CREAM = "FFF6E4"
WHITE = ["F8F3E7", "FFF9F0", "EDE4D2"]
BLACK = "2D2622"
BROWN = ["8A5A3A", "9B6B47", "74482E"]
DARK_WOOD = "5C3A24"
RED = ["B64B3F", "C85A4E", "A74238"]
ROOF = ["8B4A3D", "9D5849"]
GREEN = ["4F8A5A", "5E9C68", "42784D"]
LEAF = ["4F8A5A", "65A469", "3F7350", "7AB774"]
STONE = ["A7A397", "B8B4A7", "8F8C82"]
GOLD = ["B8892E", "D0A347", "9C7425"]
BLUE = ["4F7FA8", "6D9BC2", "3F6D92"]

# ---------------------------------------------------------------------------
# Animals
# ---------------------------------------------------------------------------

@model("animal.pig", "Pig", "animal", "A round, curious pig with 700+ voxels, curly tail and tiny hooves.")
def pig(s: Sculpt):
    s.ellipsoid(0, 12, 0, 7, 6, 10, PINK, "fur", hollow=True, shell=0.5, checker=3)
    s.ellipsoid(0, 15, 9, 5.2, 4.8, 4.6, PINK, "skin", checker=2)
    s.box(-2, 2, 13, 15, 13, 16, DARK_PINK, "skin")
    s.add(-1, 14, 16, "7A3F51", "eye"); s.add(1, 14, 16, "7A3F51", "eye")
    s.box(-4, -3, 17, 18, 14, 14, "2D2622", "eye")
    s.box(3, 4, 17, 18, 14, 14, "2D2622", "eye")
    s.box(-5, -3, 19, 21, 8, 10, PINK, "skin")
    s.box(3, 5, 19, 21, 8, 10, PINK, "skin")
    for x in (-4, 4):
        for z in (-6, 6):
            s.cylinder(x, z, 0, 6, 2.4, PINK, "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "6B3A45", "skin")
    s.line((0, 13, -9), (2, 16, -12), DARK_PINK, "fur", 1)
    s.line((2, 16, -12), (0, 18, -11), DARK_PINK, "fur", 1)
    s.line((0, 18, -11), (1, 19, -9), DARK_PINK, "fur", 1)

@model("animal.cow", "Cow", "animal", "A black-and-white dairy cow with horns, udder and a patient expression.")
def cow(s: Sculpt):
    s.ellipsoid(0, 15, 0, 8, 7, 12, WHITE, "fur", hollow=True, shell=0.48, checker=3)
    s.ellipsoid(-3, 15, 2, 3.2, 3.5, 4, "2D2A26", "fur", hollow=True, shell=0.45)
    s.ellipsoid(4, 14, -4, 2.8, 3.2, 3.6, "2D2A26", "fur", hollow=True, shell=0.45)
    s.ellipsoid(0, 19, 11, 5.4, 5, 4.5, WHITE, "fur", checker=2)
    s.box(-2, 2, 15, 19, 14, 17, "F2A7B0", "skin")
    s.add(-3, 20, 14, BLACK, "eye"); s.add(3, 20, 14, BLACK, "eye")
    s.line((-4, 23, 10), (-6, 26, 9), "E4C27B", "metal", 1)
    s.line((4, 23, 10), (6, 26, 9), "E4C27B", "metal", 1)
    s.box(-6, -3, 19, 22, 8, 9, WHITE, "fur")
    s.box(3, 6, 19, 22, 8, 9, WHITE, "fur")
    for x in (-5, 5):
        for z in (-8, 8):
            s.cylinder(x, z, 0, 8, 2.7, WHITE, "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "4C4039", "skin")
    s.ellipsoid(0, 9, -6, 2.7, 2.1, 2, "F2A7B0", "skin")
    s.line((0, 20, -12), (0, 14, -15), BLACK, "fur", 1)
    s.box(-1, 1, 10, 13, -16, -15, BLACK, "fur")

@model("animal.chicken", "Chicken", "animal", "A speckled hen with a bright comb, folded wings and quick feet.")
def chicken(s: Sculpt):
    s.ellipsoid(0, 10, 0, 5, 5, 6.5, WHITE, "feather", checker=2)
    s.ellipsoid(0, 16, 4, 3.4, 3.4, 3.2, WHITE, "feather", checker=2)
    s.box(-2, 2, 17, 18, 7, 8, "F2B544", "ceramic")
    s.add(-3, 18, 6, BLACK, "eye"); s.add(3, 18, 6, BLACK, "eye")
    s.box(-1, 1, 19, 21, 3, 5, "D3523F", "feather")
    s.box(-2, 2, 15, 16, 7, 8, "D3523F", "skin")
    s.box(-6, -5, 8, 13, -2, 2, "E7DAC2", "feather")
    s.box(5, 6, 8, 13, -2, 2, "E7DAC2", "feather")
    s.line((0, 6, -4), (0, 5, -8), "E7DAC2", "feather", 2)
    s.line((0, 6, -7), (0, 4, -10), "B95242", "feather", 2)
    for x in (-2, 2):
        s.line((x, 5, 0), (x, 0, 1), "E4A63D", "metal", 1)
        s.line((x, 0, 1), (x + 2, 0, 2), "E4A63D", "metal", 1)

@model("animal.sheep", "Sheep", "animal", "A cloud-soft sheep with a dark face and curly wool cap.")
def sheep(s: Sculpt):
    s.ellipsoid(0, 13, 0, 8, 7, 10, ["F7F0DE", "FFF9EC", "E9DFC9"], "wool", hollow=True, shell=0.4, checker=2)
    s.ellipsoid(0, 20, 5, 4.4, 3.4, 4.6, ["F7F0DE", "FFF9EC"], "wool", checker=2)
    s.ellipsoid(0, 17, 10, 4, 4.4, 3.6, "5D4A3E", "fur")
    s.add(-2, 18, 13, "F6E6C6", "eye"); s.add(2, 18, 13, "F6E6C6", "eye")
    s.box(-2, 2, 14, 15, 13, 14, "3B2E29", "skin")
    s.box(-5, -3, 20, 22, 3, 6, "E9DFC9", "wool")
    s.box(3, 5, 20, 22, 3, 6, "E9DFC9", "wool")
    for x in (-5, 5):
        for z in (-6, 6):
            s.cylinder(x, z, 0, 7, 2.2, "5D4A3E", "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "2D2622", "skin")
    s.ellipsoid(0, 12, -9, 3.2, 3, 2.4, "E9DFC9", "wool")

@model("animal.goat", "Goat", "animal", "A nimble goat with swept horns, a beard and mischievous eyes.")
def goat(s: Sculpt):
    s.ellipsoid(0, 13, 0, 6.4, 5.6, 9.5, ["D8C6A4", "E7D9BC", "C8B391"], "fur", hollow=True, shell=0.46, checker=2)
    s.box(-1, 1, 15, 18, 8, 14, "D8C6A4", "fur")
    s.ellipsoid(0, 19, 14, 3.8, 4.1, 3.5, "D8C6A4", "fur")
    s.add(-2, 20, 17, "2D2622", "eye"); s.add(2, 20, 17, "2D2622", "eye")
    s.box(-1, 1, 17, 18, 17, 18, "5D4A3E", "skin")
    s.box(-1, 1, 13, 15, 16, 17, "C8B391", "fur")
    s.line((-3, 22, 14), (-6, 26, 12), "7A6248", "metal", 2)
    s.line((-6, 26, 12), (-8, 25, 10), "7A6248", "metal", 2)
    s.line((3, 22, 14), (6, 26, 12), "7A6248", "metal", 2)
    s.line((6, 26, 12), (8, 25, 10), "7A6248", "metal", 2)
    s.box(-4, -3, 20, 22, 11, 13, "D8C6A4", "fur")
    s.box(3, 4, 20, 22, 11, 13, "D8C6A4", "fur")
    for x in (-4, 4):
        for z in (-6, 6):
            s.cylinder(x, z, 0, 7, 2.1, "C8B391", "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "4C4039", "skin")
    s.line((0, 15, -9), (0, 17, -12), "8B7354", "fur", 1)
    s.box(-1, 1, 12, 14, -13, -12, "8B7354", "fur")

@model("animal.horse", "Horse", "animal", "A chestnut horse with a flowing mane, long legs and polished hooves.")
def horse(s: Sculpt):
    s.ellipsoid(0, 18, 0, 7, 7, 13, ["8E5A3C", "A46B49", "7A4A31"], "fur", hollow=True, shell=0.46, checker=3)
    s.box(-2, 2, 23, 29, 7, 13, "8E5A3C", "fur")
    s.ellipsoid(0, 30, 15, 4.2, 4.8, 5.2, "8E5A3C", "fur")
    s.box(-2, 2, 27, 29, 19, 20, "D8B58E", "skin")
    s.add(-3, 31, 18, "211A18", "eye"); s.add(3, 31, 18, "211A18", "eye")
    s.box(-4, -3, 32, 35, 11, 14, "8E5A3C", "fur")
    s.box(3, 4, 32, 35, 11, 14, "8E5A3C", "fur")
    for x in (-5, 5):
        for z in (-9, 8):
            s.cylinder(x, z, 0, 9, 2.2, "7A4A31", "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "2D2622", "skin")
    s.box(-3, 3, 23, 28, 5, 7, "3D2A22", "fur")
    s.box(-3, 3, 24, 29, 6, 7, "5B3B29", "fur")
    s.line((0, 22, -13), (0, 16, -17), "3D2A22", "fur", 3)
    s.line((0, 16, -17), (0, 12, -18), "3D2A22", "fur", 2)

@model("animal.duck", "Duck", "animal", "A bright mallard drake with a green head and orange bill.")
def duck(s: Sculpt):
    s.ellipsoid(0, 9, 0, 5.4, 4.4, 6.6, ["E8D9B8", "F3E7C9", "D8C59D"], "feather", checker=2)
    s.ellipsoid(0, 15, 4, 3.5, 3.6, 3.4, ["4E8A5A", "5E9C68", "3F7350"], "feather", checker=2)
    s.box(-2, 2, 14, 15, 7, 9, "F0A93B", "ceramic")
    s.add(-2, 16, 6, "211A18", "eye"); s.add(2, 16, 6, "211A18", "eye")
    s.box(-1, 1, 16, 17, 4, 6, "4E8A5A", "feather")
    s.box(-5, -4, 8, 12, -1, 3, "8E5A3C", "feather")
    s.box(5, 5, 8, 12, -1, 3, "8E5A3C", "feather")
    s.box(-2, 2, 5, 7, -7, -4, "E8D9B8", "feather")
    for x in (-2, 2):
        s.line((x, 5, 0), (x, 0, 1), "E4A63D", "metal", 1)
        s.box(x - 1, x + 1, 0, 0, 1, 3, "E4A63D", "metal")

@model("animal.cat", "Cat", "animal", "A ginger barn cat with cream chest, whiskers and a question-mark tail.")
def cat(s: Sculpt):
    s.ellipsoid(0, 9, 0, 4.2, 4.4, 7.2, ["D98745", "E79B58", "C16F36"], "fur", hollow=True, shell=0.45, checker=2)
    s.ellipsoid(0, 16, 5, 3.6, 3.2, 3.2, "D98745", "fur")
    s.ellipsoid(0, 12, 5, 2.2, 2.8, 1.2, "F3DFC0", "fur")
    s.add(-2, 17, 8, "2D2622", "eye"); s.add(2, 17, 8, "2D2622", "eye")
    s.box(-1, 1, 15, 15, 9, 9, DARK_PINK, "skin")
    s.box(-4, -3, 19, 22, 4, 6, "C16F36", "fur")
    s.box(3, 4, 19, 22, 4, 6, "C16F36", "fur")
    s.box(-3, -3, 16, 16, 9, 10, "F3DFC0", "fur")
    s.box(3, 3, 16, 16, 9, 10, "F3DFC0", "fur")
    for x in (-3, 3):
        for z in (-3, 3):
            s.cylinder(x, z, 0, 5, 1.5, "D98745", "fur", hollow=True)
    s.line((0, 9, -7), (2, 12, -10), "C16F36", "fur", 2)
    s.line((2, 12, -10), (-1, 15, -11), "C16F36", "fur", 2)
    s.line((-1, 15, -11), (1, 17, -10), "C16F36", "fur", 2)

@model("animal.dog", "Dog", "animal", "A friendly farm dog with floppy ears, a red collar and a wagging tail.")
def dog(s: Sculpt):
    s.ellipsoid(0, 11, 0, 5, 5, 8, ["B87A45", "C98B55", "A56639"], "fur", hollow=True, shell=0.45, checker=2)
    s.ellipsoid(0, 18, 6, 4.2, 4, 4.2, "B87A45", "fur")
    s.box(-2, 2, 15, 17, 9, 11, "E6C99C", "fur")
    s.add(-2, 19, 10, "211A18", "eye"); s.add(2, 19, 10, "211A18", "eye")
    s.box(-1, 1, 17, 17, 11, 11, "2D2622", "skin")
    s.box(-5, -3, 19, 23, 4, 7, "8E5A3C", "fur")
    s.box(3, 5, 19, 23, 4, 7, "8E5A3C", "fur")
    s.box(-4, 4, 13, 14, 7, 9, "B64B3F", "fabric")
    s.box(-1, 1, 13, 14, 10, 10, GOLD[0], "metal")
    for x in (-3, 3):
        for z in (-5, 5):
            s.cylinder(x, z, 0, 6, 1.9, "B87A45", "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "4C4039", "skin")
    s.line((0, 13, -8), (1, 18, -11), "B87A45", "fur", 2)

@model("animal.rabbit", "Rabbit", "animal", "A soft rabbit with tall ears, a cotton tail and a pocketful of clover.")
def rabbit(s: Sculpt):
    s.ellipsoid(0, 8, 0, 4.4, 5.4, 6.4, ["C9B8A0", "DCCDB8", "B5A28A"], "fur", hollow=True, shell=0.45, checker=2)
    s.ellipsoid(0, 14, 5, 3.4, 3.6, 3.2, "C9B8A0", "fur")
    s.add(-2, 15, 8, "2D2622", "eye"); s.add(2, 15, 8, "2D2622", "eye")
    s.box(-1, 1, 13, 13, 9, 9, DARK_PINK, "skin")
    s.box(-3, -2, 17, 24, 4, 6, "C9B8A0", "fur")
    s.box(2, 3, 17, 24, 4, 6, "C9B8A0", "fur")
    s.box(-3, -2, 18, 23, 5, 5, DARK_PINK, "skin")
    s.box(2, 3, 18, 23, 5, 5, DARK_PINK, "skin")
    for x in (-2, 2):
        s.cylinder(x, 0, 0, 4, 1.6, "C9B8A0", "fur")
    s.sphere = None
    s.ellipsoid(0, 8, -7, 2.2, 2.2, 2.2, "FFF9EC", "wool")
    s.box(-2, 2, 9, 11, 7, 8, "6FA84F", "leaf")

@model("animal.goose", "Goose", "animal", "A proud white goose with a long neck and a loud opinion.")
def goose(s: Sculpt):
    s.ellipsoid(0, 11, 0, 5, 4.5, 7, WHITE, "feather", checker=2)
    s.line((0, 14, 4), (0, 24, 8), WHITE[0], "feather", 4)
    s.ellipsoid(0, 26, 10, 2.8, 3.2, 3.4, WHITE[0], "feather")
    s.box(-2, 2, 25, 26, 13, 15, "E4A63D", "ceramic")
    s.add(-2, 27, 12, "211A18", "eye"); s.add(2, 27, 12, "211A18", "eye")
    s.box(-6, -5, 10, 15, -2, 2, WHITE[1], "feather")
    s.box(5, 5, 10, 15, -2, 2, WHITE[1], "feather")
    for x in (-2, 2):
        s.line((x, 6, 0), (x, 0, 1), "E4A63D", "metal", 1)
        s.box(x - 1, x + 1, 0, 0, 1, 3, "E4A63D", "metal")
    s.ellipsoid(0, 12, -7, 3.2, 2.8, 2.2, WHITE[0], "feather")

@model("animal.alpaca", "Alpaca", "animal", "A fluffy alpaca with a long neck, tasselled ears and gentle eyes.")
def alpaca(s: Sculpt):
    s.ellipsoid(0, 16, 0, 6, 7, 9, ["E7D7BB", "F3E6CC", "D6C3A3"], "wool", hollow=True, shell=0.4, checker=2)
    s.line((0, 21, 5), (0, 30, 7), "E7D7BB", "wool", 5)
    s.ellipsoid(0, 32, 9, 3.6, 3.8, 4.2, "E7D7BB", "wool", checker=2)
    s.add(-2, 33, 12, "2D2622", "eye"); s.add(2, 33, 12, "2D2622", "eye")
    s.box(-1, 1, 31, 31, 13, 14, DARK_PINK, "skin")
    s.box(-3, -2, 36, 39, 7, 9, "E7D7BB", "wool")
    s.box(2, 3, 36, 39, 7, 9, "E7D7BB", "wool")
    for x in (-4, 4):
        for z in (-6, 6):
            s.cylinder(x, z, 0, 9, 2.2, "D6C3A3", "wool", hollow=True)
    s.ellipsoid(0, 16, -9, 3.4, 3.8, 2.5, "F3E6CC", "wool")
    s.box(-2, 2, 10, 12, -11, -10, "E7D7BB", "wool")

@model("animal.bee", "Bee", "animal", "A plump honeybee with translucent wings and a happy buzz.")
def bee(s: Sculpt):
    s.ellipsoid(0, 13, 0, 4.2, 4.2, 6.8, ["E7B93F", "2D2622"], "fur", checker=2)
    s.ellipsoid(0, 15, 6, 3.4, 3.4, 3, "E7B93F", "fur")
    s.add(-2, 16, 8, "211A18", "eye"); s.add(2, 16, 8, "211A18", "eye")
    s.line((-3, 16, 3), (-9, 21, -3), "D8EDF5", "glass", 2)
    s.line((3, 16, 3), (9, 21, -3), "D8EDF5", "glass", 2)
    s.line((-3, 14, -2), (-9, 18, -8), "D8EDF5", "glass", 1)
    s.line((3, 14, -2), (9, 18, -8), "D8EDF5", "glass", 1)
    s.line((0, 12, -7), (0, 11, -10), "2D2622", "fur", 2)
    for x in (-2, 2):
        s.line((x, 9, 0), (x, 6, 1), "2D2622", "metal", 1)

@model("animal.butterfly", "Butterfly", "animal", "A sky-blue butterfly, small enough to land on a clover.")
def butterfly(s: Sculpt):
    s.ellipsoid(0, 14, 0, 1, 4, 1, "4F5D75", "fur")
    for side in (-1, 1):
        s.ellipsoid(side * 5, 16, 3, 5, 4, 3, ["8FC3DD", "A9D9EE", "6D9BC2"], "glass", hollow=True, shell=0.3)
        s.ellipsoid(side * 4, 11, -2, 3.5, 3, 2.5, ["8FC3DD", "A9D9EE"], "glass", hollow=True, shell=0.3)
    s.line((0, 18, 0), (-2, 21, 2), "4F5D75", "fur", 1)
    s.line((0, 18, 0), (2, 21, 2), "4F5D75", "fur", 1)

# ---------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------

@model("build.barn", "Red Barn", "building", "The Hollow's big red barn: white trim, hayloft, weather vane and two sliding doors.")
def barn(s: Sculpt):
    s.box(-22, 22, 0, 24, -17, 17, RED, "wood", hollow=True)
    s.box(-22, 22, 0, 1, -17, 17, STONE, "stone")
    s.box(-22, -21, 0, 27, -17, 17, WHITE[0], "wood")
    s.box(21, 22, 0, 27, -17, 17, WHITE[0], "wood")
    s.box(-22, 22, 0, 2, 17, 17, WHITE[0], "wood")
    s.box(-22, 22, 20, 21, 17, 17, WHITE[0], "wood")
    s.box(-7, 7, 0, 18, 17, 18, "7A382F", "wood")
    s.box(-7, 7, 9, 18, 18, 18, "5C2B24", "wood")
    s.box(-1, 1, 0, 17, 18, 18, CREAM, "wood")
    s.box(-7, -5, 20, 23, 18, 18, "E9D9B7", "wood")
    s.box(5, 7, 20, 23, 18, 18, "E9D9B7", "wood")
    s.box(-3, 3, 21, 22, 18, 18, BLACK, "glass")
    s.roof(-24, 24, 24, -18, 18, ROOF, "roof")
    s.box(-2, 2, 0, 1, 18, 18, BLACK, "metal")
    s.line((0, 46, 0), (0, 52, 0), "4C4039", "metal", 1)
    s.box(-7, 7, 52, 52, -1, 1, "4C4039", "metal")
    s.box(-1, 1, 52, 52, -7, 7, "4C4039", "metal")
    s.box(-3, 3, 4, 8, 18, 18, "4F7FA8", "glass")
    s.box(-3, 3, 4, 8, 19, 19, "D8EDF5", "glass")
    for x in (-16, 16):
        s.box(x - 3, x + 3, 3, 8, 18, 18, "4F7FA8", "glass")
        s.box(x - 3, x + 3, 3, 8, 19, 19, "D8EDF5", "glass")
    s.box(-18, -14, 2, 3, 17, 19, "C9B391", "hay")
    s.box(14, 18, 2, 3, 17, 19, "C9B391", "hay")

@model("build.farmhouse", "Farmhouse", "building", "A cream cottage with a warm red roof, porch, chimney and flower boxes.")
def farmhouse(s: Sculpt):
    s.box(-20, 20, 0, 20, -14, 14, ["F4E3C1", "EAD6AE", "FFF0D0"], "wood", hollow=True, checker=2)
    s.box(-20, 20, 0, 1, -14, 14, STONE, "stone")
    s.box(-20, 20, 0, 4, -14, 14, ["C8B391", "B8A17D"], "stone", checker=2)
    s.roof(-22, 22, 21, -16, 16, ROOF, "roof")
    s.box(8, 12, 27, 38, -6, -2, "9A7D6A", "brick")
    s.box(8, 12, 38, 39, -6, -2, "4C4039", "stone")
    s.box(-4, 4, 0, 12, 14, 15, "8A5A3A", "wood")
    s.box(-4, 4, 0, 12, 15, 15, "5C3A24", "darkWood")
    s.box(-1, 1, 5, 6, 15, 15, GOLD[0], "metal")
    for x in (-14, -10, 10, 14):
        s.box(x - 2, x + 2, 7, 13, 14, 15, "4F7FA8", "glass")
        s.box(x - 2, x + 2, 7, 13, 15, 15, "D8EDF5", "glass")
        s.box(x - 3, x + 3, 5, 6, 14, 16, "8A5A3A", "wood")
    s.box(-8, 8, 0, 1, 14, 20, "8A5A3A", "wood")
    s.box(-8, -7, 0, 7, 19, 20, "5C3A24", "wood")
    s.box(7, 8, 0, 7, 19, 20, "5C3A24", "wood")
    s.box(-9, 9, 7, 8, 13, 20, "8B4A3D", "roof")
    s.box(-3, 3, 13, 18, 15, 15, "E9D9B7", "wood")
    s.box(-15, -11, 4, 5, 16, 16, "A85C4B", "flower")
    s.box(11, 15, 4, 5, 16, 16, "A85C4B", "flower")
    s.box(-13, -9, 24, 25, -10, -6, "4C4039", "stone")
    s.box(-1, 1, 32, 39, -4, -2, "B8B4A7", "stone")

@model("build.coop", "Chicken Coop", "building", "A pocket-sized coop with a ramp, nest boxes and a little red door.")
def coop(s: Sculpt):
    s.box(-13, 13, 0, 13, -10, 10, ["E7D9BC", "F3E6CC"], "wood", hollow=True, checker=2)
    s.box(-13, 13, 0, 1, -10, 10, STONE, "stone")
    s.roof(-15, 15, 14, -12, 12, ["8B4A3D", "9D5849"], "roof")
    s.box(-4, 4, 0, 8, 10, 11, "B64B3F", "wood")
    s.box(-1, 1, 2, 5, 11, 11, "F2B544", "ceramic")
    s.box(-8, -6, 7, 10, 10, 11, "4F7FA8", "glass")
    s.box(6, 8, 7, 10, 10, 11, "4F7FA8", "glass")
    s.box(-10, 10, 0, 1, 11, 23, "8A5A3A", "wood")
    for x in (-8, 0, 8):
        s.box(x - 1, x + 1, 1, 2, 12, 22, "5C3A24", "wood")
    s.box(-13, 13, 5, 6, -11, -10, "C9B391", "hay")
    s.box(-12, -8, 0, 2, -12, -10, "C9B391", "hay")
    s.box(8, 12, 0, 2, -12, -10, "C9B391", "hay")
    s.line((-11, 16, 0), (-11, 20, 0), "4C4039", "metal", 1)
    s.box(-14, -8, 20, 20, -1, 1, "4C4039", "metal")

@model("build.silo", "Grain Silo", "building", "A tall stone-and-metal silo with a domed cap and a tiny inspection door.")
def silo(s: Sculpt):
    s.cylinder(0, 0, 0, 38, 11, STONE, "stone", hollow=True)
    s.cylinder(0, 0, 0, 2, 11, STONE, "stone")
    for y in (8, 16, 24, 32):
        s.cylinder(0, 0, y, y, 11.2, ["9A968A", "B8B4A7"], "metal", hollow=True)
    s.ellipsoid(0, 39, 0, 11.5, 5, 11.5, ["8F8C82", "A7A397"], "metal", hollow=True, shell=0.55)
    s.box(-2, 2, 0, 6, 11, 12, "5C3A24", "wood")
    s.box(-3, 3, 6, 7, 10, 12, "4C4039", "metal")
    s.line((0, 44, 0), (0, 50, 0), "4C4039", "metal", 1)
    s.box(-4, 4, 50, 50, -1, 1, "4C4039", "metal")

@model("build.windmill", "Windmill", "building", "A working windmill with a stone base, wooden tower and four turning sails.")
def windmill(s: Sculpt):
    s.cylinder(0, 0, 0, 7, 18, STONE, "stone", hollow=True)
    s.box(-8, 8, 7, 34, -8, 8, ["D8C6A4", "C8B391"], "wood", hollow=True, checker=3)
    s.box(-9, 9, 34, 36, -9, 9, "8A5A3A", "wood")
    s.roof(-10, 10, 37, -10, 10, ROOF, "roof")
    s.box(-2, 2, 0, 8, 8, 9, "5C3A24", "wood")
    s.box(-1, 1, 4, 6, 9, 9, GOLD[0], "metal")
    for x in (-6, 6):
        s.box(x - 1, x + 1, 9, 33, 8, 9, "5C3A24", "wood")
    s.ellipsoid(0, 30, 11, 2.5, 2.5, 2.5, "4C4039", "metal")
    for angle in (0, 90, 180, 270):
        rad = math.radians(angle)
        dx = round(math.cos(rad) * 13)
        dy = round(math.sin(rad) * 13)
        s.line((0, 30, 11), (dx, 30 + dy, 11), "5C3A24", "wood", 1)
        s.box(dx - 1, dx + 1, 28 + dy, 34 + dy, 11, 11, "E9D9B7", "fabric")
        s.box(-1, 1, 28 + dy, 34 + dy, 11, 11, "E9D9B7", "fabric")

@model("build.well", "Stone Well", "building", "A mossy well with a shingled roof, bucket and coil of rope.")
def well(s: Sculpt):
    s.cylinder(0, 0, 0, 9, 9, ["A7A397", "8F8C82", "B8B4A7"], "stone", hollow=True)
    s.cylinder(0, 0, 0, 1, 9, ["A7A397", "8F8C82"], "stone")
    s.ring = None
    s.cylinder(0, 0, 9, 10, 9, ["B8B4A7", "A7A397"], "stone", hollow=True)
    s.box(-9, -8, 0, 21, -9, -8, "5C3A24", "wood")
    s.box(8, 9, 0, 21, -9, -8, "5C3A24", "wood")
    s.box(-10, 10, 20, 21, -10, 10, "8B4A3D", "roof")
    s.roof(-10, 10, 22, -10, 10, "8B4A3D", "roof")
    s.line((0, 19, 0), (0, 13, 0), "C9B391", "fabric", 1)
    s.box(-2, 2, 8, 12, -1, 1, "8A5A3A", "wood")
    s.box(-1, 1, 6, 7, 0, 0, "4C4039", "metal")

@model("build.greenhouse", "Greenhouse", "building", "A glass greenhouse full of seedlings, terracotta pots and warm light.")
def greenhouse(s: Sculpt):
    s.box(-15, 15, 0, 14, -10, 10, "D8EDF5", "glass", hollow=True)
    s.box(-15, 15, 0, 1, -10, 10, STONE, "stone")
    for x in (-15, -10, -5, 0, 5, 10, 15):
        s.box(x, x, 0, 20, -10, -10, "6B8F73", "metal")
        s.box(x, x, 0, 20, 10, 10, "6B8F73", "metal")
    for z in (-10, -5, 0, 5, 10):
        s.box(-15, -15, 0, 20, z, z, "6B8F73", "metal")
        s.box(15, 15, 0, 20, z, z, "6B8F73", "metal")
    s.box(-16, 16, 15, 16, -11, 11, "6B8F73", "metal")
    s.roof(-16, 16, 17, -11, 11, "D8EDF5", "glass")
    s.box(-4, 4, 0, 10, 10, 11, "6B8F73", "metal")
    s.box(-3, 3, 0, 9, 11, 11, "D8EDF5", "glass")
    s.box(-12, -9, 0, 2, -7, -4, "B86B4B", "ceramic")
    s.box(-7, -4, 0, 2, -7, -4, "B86B4B", "ceramic")
    s.box(5, 8, 0, 2, -7, -4, "B86B4B", "ceramic")
    s.box(9, 12, 0, 2, -7, -4, "B86B4B", "ceramic")
    for x in (-11, -6, 7, 11):
        s.ellipsoid(x, 4, -5, 2, 2, 2, LEAF, "leaf", hollow=True, shell=0.3)
    s.box(-12, 12, 0, 0, -2, 2, "8A5A3A", "wood")

@model("build.market", "Market Stall", "building", "A striped market stall with a counter, scale and baskets of produce.")
def market(s: Sculpt):
    for x in (-13, 13):
        for z in (-8, 8):
            s.box(x, x, 0, 16, z, z, "8A5A3A", "wood")
    s.box(-14, 14, 12, 13, -9, 9, "C9B391", "wood")
    s.box(-14, 14, 0, 9, -8, -7, "8A5A3A", "wood")
    s.box(-14, 14, 9, 10, -8, 8, "A46B49", "wood")
    for i, x in enumerate(range(-14, 15, 4)):
        color = "B64B3F" if i % 2 == 0 else "F3E6CC"
        s.box(x, x + 3, 13, 15, -9, 9, color, "fabric")
    s.box(-4, 4, 10, 12, -2, 2, "4C4039", "metal")
    s.box(-1, 1, 12, 13, -1, 1, GOLD[0], "metal")
    s.box(-11, -7, 10, 11, -5, -2, "E7B93F", "crop")
    s.box(6, 10, 10, 11, -5, -2, "B64B3F", "crop")
    s.box(1, 4, 10, 11, 3, 6, "4F8A5A", "crop")

@model("build.shed", "Tool Shed", "building", "A weathered tool shed with a workbench, tool rack and a crooked door.")
def shed(s: Sculpt):
    s.box(-11, 11, 0, 12, -8, 8, ["8A7358", "9B8468"], "wood", hollow=True, checker=2)
    s.box(-11, 11, 0, 1, -8, 8, STONE, "stone")
    s.roof(-13, 13, 13, -10, 10, ["6B5A48", "7C6B58"], "roof")
    s.box(-3, 3, 0, 8, 8, 9, "5C3A24", "wood")
    s.box(-1, 1, 4, 5, 9, 9, GOLD[0], "metal")
    s.box(-8, -4, 4, 8, 8, 8, "4F7FA8", "glass")
    s.box(-9, 9, 6, 7, -8, -7, "A46B49", "wood")
    s.box(-7, -6, 7, 11, -8, -7, "4C4039", "metal")
    s.box(5, 6, 7, 11, -8, -7, "4C4039", "metal")
    s.box(-2, 3, 8, 8, -8, -7, "8A5A3A", "wood")

@model("build.beehive", "Beehive", "building", "A stack of golden hive boxes with a landing board and buzzing residents.")
def beehive(s: Sculpt):
    s.box(-8, 8, 0, 2, -7, 7, "8A5A3A", "wood")
    for y in (3, 9, 15):
        s.box(-7, 7, y, y + 5, -6, 6, ["E7B93F", "F0C95C", "D8A62C"], "wood", hollow=True, checker=2)
        s.box(-8, 8, y + 5, y + 6, -7, 7, "8A5A3A", "wood")
    s.box(-10, 10, 21, 22, -8, 8, "8A5A3A", "wood")
    s.roof(-10, 10, 23, -8, 8, ["6B5A48", "7C6B58"], "roof")
    s.box(-3, 3, 4, 5, 7, 7, "4C4039", "wood")
    s.box(-1, 1, 10, 11, 7, 7, "4C4039", "wood")
    s.box(-9, -8, 2, 3, -3, 3, "8A5A3A", "wood")
    for x, y, z in [(-4, 12, 8), (2, 17, 7), (5, 7, 8), (-6, 19, 8)]:
        s.add(x, y, z, "E7B93F", "metal")
        s.add(x + 1, y, z, "2D2622", "fur")

@model("build.watertower", "Water Tower", "building", "A wooden water tower on four legs, with a copper roof and ladder.")
def watertower(s: Sculpt):
    for x in (-7, 7):
        for z in (-7, 7):
            s.box(x, x, 0, 26, z, z, "6B5A48", "wood")
            s.line((x, 0, z), (0 if x > 0 else -2, 18, 0 if z > 0 else -2), "8A7358", "wood", 1)
    s.cylinder(0, 0, 26, 39, 10, ["8A5A3A", "9B6B47"], "wood", hollow=True)
    for y in (28, 32, 36):
        s.cylinder(0, 0, y, y, 10.2, "4C4039", "metal", hollow=True)
    s.ellipsoid(0, 40, 0, 10, 5, 10, ["4F8A5A", "5E9C68"], "metal", hollow=True, shell=0.5)
    s.box(-2, 2, 27, 28, 10, 11, "4C4039", "metal")
    s.line((-10, 0, 0), (-10, 26, 0), "4C4039", "metal", 1)
    for y in range(2, 26, 3):
        s.box(-11, -9, y, y, -1, 1, "4C4039", "metal")

@model("build.windpump", "Wind Pump", "building", "A slender farm wind pump with a lattice tower and silver fan.")
def windpump(s: Sculpt):
    for x in (-4, 4):
        for z in (-4, 4):
            s.box(x, x, 0, 30, z, z, "A7A397", "metal")
    for y in range(4, 30, 4):
        s.box(-4, 4, y, y, -4, -4, "A7A397", "metal")
        s.box(-4, 4, y, y, 4, 4, "A7A397", "metal")
        s.box(-4, -4, y, y, -4, 4, "A7A397", "metal")
        s.box(4, 4, y, y, -4, 4, "A7A397", "metal")
    s.box(-6, 6, 30, 32, -1, 1, "4C4039", "metal")
    s.ellipsoid(0, 32, 3, 2, 2, 2, "4C4039", "metal")
    for angle in (0, 72, 144, 216, 288):
        rad = math.radians(angle)
        dx = round(math.cos(rad) * 8)
        dy = round(math.sin(rad) * 8)
        s.line((0, 32, 4), (dx, 32 + dy, 4), "B8B4A7", "metal", 1)
        s.add(dx, 32 + dy, 4, "D8EDF5", "metal")
    s.line((0, 0, 0), (0, 30, 0), "4F7FA8", "metal", 1)
    s.box(-2, 2, 0, 0, -2, 2, "4C4039", "metal")

# ---------------------------------------------------------------------------
# Nature
# ---------------------------------------------------------------------------

@model("nature.oak", "Old Oak", "nature", "A broad oak with a deep trunk, layered crown and a rope swing.")
def oak(s: Sculpt):
    s.cylinder(0, 0, 0, 24, 5, BROWN, "darkWood", hollow=True)
    s.box(-8, -5, 0, 1, -7, 7, BROWN[2], "darkWood")
    s.box(5, 8, 0, 1, -5, 8, BROWN[2], "darkWood")
    s.line((0, 20, 0), (-10, 29, 2), BROWN[1], "wood", 3)
    s.line((0, 21, 0), (10, 31, -1), BROWN[1], "wood", 3)
    s.tree_crown(0, 34, 0, 13, LEAF)
    s.tree_crown(-11, 31, 2, 8, LEAF)
    s.tree_crown(11, 32, -2, 8, LEAF)
    s.line((5, 20, 0), (5, 8, 0), "C9B391", "fabric", 1)
    s.box(2, 8, 7, 8, -1, 1, "8A5A3A", "wood")

@model("nature.pine", "Pine", "nature", "A tall pine with a straight trunk and five tiers of dark needles.")
def pine(s: Sculpt):
    s.cylinder(0, 0, 0, 30, 3, BROWN, "darkWood", hollow=True)
    for index, y in enumerate((9, 15, 21, 27, 33)):
        radius = 11 - index * 1.7
        s.ellipsoid(0, y, 0, radius, 4.5, radius, ["2F5D43", "3F7350", "4F8A5A"], "leaf", hollow=True, shell=0.38, checker=2)
    s.box(-6, 6, 0, 1, -5, 5, BROWN[2], "darkWood")

@model("nature.birch", "Silver Birch", "nature", "A pale birch trunk with dark flecks and a light, airy crown.")
def birch(s: Sculpt):
    s.cylinder(0, 0, 0, 26, 3, ["E8E1D2", "F3EEE3", "D8D0BE"], "wood", hollow=True)
    for y in range(3, 26, 4):
        s.box(-3, -2, y, y, 1, 3, "4C4039", "wood")
        s.box(2, 3, y + 1, y + 1, -3, -1, "4C4039", "wood")
    s.tree_crown(0, 32, 0, 9, ["7AB774", "8FC77D", "65A469"])
    s.tree_crown(-7, 29, 2, 5, ["7AB774", "8FC77D"])
    s.tree_crown(7, 31, -2, 5, ["7AB774", "65A469"])

@model("nature.appletree", "Apple Tree", "nature", "A rounded apple tree with red fruit tucked among the leaves.")
def appletree(s: Sculpt):
    s.cylinder(0, 0, 0, 17, 3, BROWN, "darkWood", hollow=True)
    s.line((0, 13, 0), (-8, 21, 2), BROWN[1], "wood", 2)
    s.line((0, 14, 0), (8, 22, -2), BROWN[1], "wood", 2)
    s.tree_crown(0, 25, 0, 11, LEAF)
    for x, y, z in [(-7, 25, 6), (4, 29, 7), (8, 24, 2), (-2, 21, 9), (-9, 28, -3), (1, 31, -6), (7, 30, -5)]:
        s.box(x, x + 1, y, y + 1, z, z + 1, "C94F45", "crop")
        s.add(x, y + 2, z, "4F8A5A", "leaf")
    s.box(-5, 5, 0, 1, -4, 4, BROWN[2], "darkWood")

@model("nature.bush", "Berry Bush", "nature", "A low berry bush with glossy leaves and tiny blue fruit.")
def bush(s: Sculpt):
    s.ellipsoid(0, 9, 0, 8, 6, 7, ["4F8A5A", "5E9C68", "3F7350"], "leaf", hollow=True, shell=0.44, checker=2)
    s.ellipsoid(-5, 8, 2, 4, 3.5, 4, ["5E9C68", "4F8A5A"], "leaf", hollow=True, shell=0.44)
    s.ellipsoid(5, 8, -2, 4, 3.5, 4, ["4F8A5A", "3F7350"], "leaf", hollow=True, shell=0.44)
    for x, y, z in [(-4, 8, 6), (2, 10, 7), (5, 7, 4), (-6, 7, -1), (4, 9, -5)]:
        s.add(x, y, z, "4F5D8A", "crop")

@model("nature.flowers", "Flower Patch", "nature", "A cheerful patch of poppies, daisies and lavender.")
def flowers(s: Sculpt):
    s.box(-9, 9, 0, 0, -7, 7, "5A7D4F", "leaf")
    for i, x in enumerate(range(-8, 9, 2)):
        for z in (-5, 0, 5):
            height = 3 + (i % 3)
            color = ["D95D4F", "F3E6CC", "8E6BC4", "F0C95C"][i % 4]
            s.line((x, 1, z), (x, height, z), "4F8A5A", "crop", 1)
            s.box(x - 1, x + 1, height, height + 1, z - 1, z + 1, color, "flower")
            s.add(x, height + 2, z, "F0C95C", "flower")

@model("nature.rocks", "Rock Cluster", "nature", "Three weather-worn boulders with moss in the cracks.")
def rocks(s: Sculpt):
    s.ellipsoid(-5, 5, 0, 6, 5, 5, STONE, "stone", hollow=True, shell=0.58, checker=2)
    s.ellipsoid(5, 4, -2, 4.5, 4, 4, ["8F8C82", "A7A397"], "stone", hollow=True, shell=0.58)
    s.ellipsoid(1, 2, 5, 3.5, 2.5, 3, ["B8B4A7", "A7A397"], "stone", hollow=True, shell=0.58)
    s.box(-10, -8, 4, 5, -1, 1, "4F8A5A", "leaf")
    s.box(6, 8, 3, 4, -5, -3, "5E9C68", "leaf")

@model("nature.mushrooms", "Mushroom Ring", "nature", "A fairy ring of toadstools and tiny white mushrooms.")
def mushrooms(s: Sculpt):
    spots = [(-7, 0, 3), (-2, 0, -5), (4, 0, -3), (7, 0, 4), (1, 0, 7)]
    for index, (x, _, z) in enumerate(spots):
        height = 3 + index % 3
        s.cylinder(x, z, 0, height, 1.6, "F3E6CC", "ceramic")
        s.ellipsoid(x, height + 1, z, 3.1, 2.1, 3.1, ["C94F45", "B64B3F"], "fabric", hollow=True, shell=0.48)
        s.add(x - 1, height + 1, z + 2, "FFF6E4", "ceramic")
        s.add(x + 1, height + 1, z - 2, "FFF6E4", "ceramic")
    s.box(-9, 9, 0, 0, -7, 7, "4F8A5A", "leaf")

@model("nature.stump", "Tree Stump", "nature", "An old stump with growth rings and a family of mushrooms.")
def stump(s: Sculpt):
    s.cylinder(0, 0, 0, 6, 7, ["8A5A3A", "74482E"], "darkWood", hollow=True)
    s.cylinder(0, 0, 7, 7, 7, ["C9A876", "B8955F"], "wood")
    for radius in (2, 4, 6):
        s.ring = None
        s.cylinder(0, 0, 7, 7, radius, ["8A5A3A", "A46B49"], "wood")
    s.cylinder(-4, 5, 0, 3, 1.5, "F3E6CC", "ceramic")
    s.ellipsoid(-4, 4, 5, 2.5, 1.5, 2.5, "C94F45", "fabric", hollow=True)
    s.box(-8, 8, 0, 0, -6, 6, "5A7D4F", "leaf")

@model("nature.hedge", "Hedge", "nature", "A clipped hedgerow with a gap for the path.")
def hedge(s: Sculpt):
    s.box(-20, 20, 0, 10, -4, 4, ["4F8A5A", "5E9C68", "3F7350"], "leaf", checker=2)
    s.box(-20, 20, 11, 12, -3, 3, ["65A469", "7AB774"], "leaf", checker=2)
    for x in range(-18, 19, 5):
        s.box(x, x + 2, 12, 13, -2, 2, "D95D4F", "flower")
    s.box(-2, 2, 0, 11, -5, 5, "8A5A3A", "wood")

@model("nature.reeds", "Pond Reeds", "nature", "Tall reeds and cattails at the water's edge.")
def reeds(s: Sculpt):
    s.box(-9, 9, 0, 0, -3, 3, "A7A397", "stone")
    for x, z in [(-7, 0), (-4, 2), (0, -1), (3, 1), (7, -2)]:
        height = 12 + abs(x) % 5
        s.line((x, 0, z), (x + 1, height, z - 1), "5A7D4F", "leaf", 1)
        s.box(x, x, height - 3, height - 1, z, z, "8A5A3A", "crop")
    s.line((-8, 0, 2), (-8, 9, 2), "6FA84F", "leaf", 1)
    s.line((-8, 9, 2), (-10, 13, 1), "6FA84F", "leaf", 1)

@model("nature.lilypad", "Lily Pads", "nature", "A cluster of lily pads with two pale pink blossoms.")
def lilypad(s: Sculpt):
    for cx, cz, radius in [(-5, 0, 4), (3, -4, 3), (5, 3, 4), (-1, 5, 2)]:
        s.ellipsoid(cx, 0, cz, radius, 0.8, radius, ["4F8A5A", "65A469"], "leaf")
    s.box(-6, -5, 1, 2, 0, 1, "F7B7C7", "flower")
    s.box(-5, -4, 2, 3, 0, 0, "FFF6E4", "flower")
    s.box(4, 5, 1, 2, 3, 4, "F7B7C7", "flower")
    s.box(4, 4, 2, 3, 4, 4, "FFF6E4", "flower")

@model("nature.log", "Fallen Log", "nature", "A mossy fallen log with a hollow and a tiny snail.")
def log(s: Sculpt):
    s.cylinder(-8, 0, 0, 5, 6, ["8A5A3A", "74482E"], "darkWood", hollow=True)
    s.cylinder(8, 0, 0, 5, 5.5, ["9B6B47", "8A5A3A"], "wood", hollow=True)
    s.box(-4, 4, 0, 5, -6, 6, "8A5A3A", "darkWood", hollow=True)
    s.box(-8, 8, 5, 6, -5, 5, ["5E9C68", "4F8A5A"], "leaf", checker=2)
    s.box(8, 9, 0, 5, -6, 6, "C9A876", "wood")
    s.ellipsoid(2, 7, 0, 2, 2, 2, "D8C6A4", "ceramic")

@model("nature.boulder", "Mossy Boulder", "nature", "A big grey boulder wearing a green moss cap.")
def boulder(s: Sculpt):
    s.ellipsoid(0, 9, 0, 12, 9, 10, STONE, "stone", hollow=True, shell=0.56, checker=2)
    s.ellipsoid(0, 15, 0, 10, 4, 8, ["4F8A5A", "5E9C68"], "leaf", hollow=True, shell=0.42, checker=2)
    s.ellipsoid(-5, 10, 7, 3, 3, 2, ["8F8C82", "A7A397"], "stone", hollow=True, shell=0.5)

@model("nature.pumpkinpatch", "Pumpkin Patch", "nature", "A tangle of vines, broad leaves and five fat pumpkins.")
def pumpkinpatch(s: Sculpt):
    for x, z, r in [(-7, -2, 4), (-2, 4, 5), (4, -4, 4.5), (8, 3, 3.5), (0, -6, 3.5)]:
        s.ellipsoid(x, int(r), z, r, r * 0.72, r, ["E08A32", "F0A34A", "C97726"], "crop", hollow=True, shell=0.45, checker=2)
        s.line((x, int(r * 1.4), z), (x + 1, int(r * 1.4) + 3, z), "4F8A5A", "crop", 1)
    for x, z in [(-8, 2), (-3, -3), (2, 0), (7, -3), (10, 0)]:
        s.box(x, x + 3, 0, 0, z, z + 2, ["4F8A5A", "5E9C68"], "leaf")

@model("nature.clover", "Clover Patch", "nature", "A carpet of clover with one lucky four-leaf sprig.")
def clover(s: Sculpt):
    for x in range(-10, 11, 2):
        for z in range(-6, 7, 2):
            s.box(x, x, 0, 0, z, z, "5A7D4F", "leaf")
            if (x + z) % 4 == 0:
                s.add(x, 1, z, "6FA84F", "leaf")
    for dx, dz in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        s.add(1 + dx, 2, 1 + dz, "7AB774", "leaf")
    s.add(1, 1, 1, "4F8A5A", "leaf")

# ---------------------------------------------------------------------------
# Farm props
# ---------------------------------------------------------------------------

@model("prop.fence", "Fence Section", "prop", "A whitewashed fence section with two rails and a sturdy post.")
def fence(s: Sculpt):
    for x in (-12, 12):
        s.box(x - 1, x + 1, 0, 9, -1, 1, "E9D9B7", "wood")
        s.box(x - 2, x + 2, 9, 10, -1, 1, "C9B391", "wood")
    s.box(-12, 12, 3, 4, -1, 1, WHITE[0], "wood")
    s.box(-12, 12, 6, 7, -1, 1, WHITE[0], "wood")
    s.box(-12, 12, 2, 2, -1, 1, "C9B391", "wood")
    s.box(-12, 12, 5, 5, -1, 1, "C9B391", "wood")

@model("prop.gate", "Farm Gate", "prop", "A five-bar wooden gate with a brass latch.")
def gate(s: Sculpt):
    s.box(-14, -12, 0, 15, -1, 1, "8A5A3A", "wood")
    s.box(12, 14, 0, 15, -1, 1, "8A5A3A", "wood")
    for y in (2, 5, 8, 11, 14):
        s.box(-12, 12, y, y, -1, 1, "C9B391", "wood")
    s.line((-12, 2, 0), (0, 14, 0), "C9B391", "wood", 1)
    s.line((0, 14, 0), (12, 2, 0), "C9B391", "wood", 1)
    s.box(-1, 1, 7, 9, 1, 2, GOLD[0], "metal")

@model("prop.haybale", "Hay Bale", "prop", "A golden hay bale tied with two lengths of twine.")
def haybale(s: Sculpt):
    s.box(-9, 9, 0, 8, -6, 6, ["D8B65C", "E7C76B", "C9A24A"], "hay", checker=2)
    s.box(-9, 9, 8, 9, -5, 5, "D8B65C", "hay")
    for x in (-4, 4):
        s.box(x, x, 0, 9, -6, -6, "8A5A3A", "fabric")
        s.box(x, x, 0, 9, 6, 6, "8A5A3A", "fabric")
    s.box(-2, 2, 9, 9, -3, 3, "B8892E", "hay")

@model("prop.crate", "Crate", "prop", "A slatted wooden crate with apples peeking out.")
def crate(s: Sculpt):
    s.box(-7, 7, 0, 8, -6, 6, "8A5A3A", "wood", hollow=True)
    for y in (0, 4, 8):
        s.box(-8, 8, y, y, -6, 6, "A46B49", "wood")
    for x in (-7, 7):
        s.box(x, x, 0, 8, -7, 7, "5C3A24", "wood")
    for x, z in [(-4, -2), (0, 1), (4, -1)]:
        s.ellipsoid(x, 8, z, 2, 2, 2, "C94F45", "crop", hollow=True, shell=0.4)

@model("prop.barrel", "Barrel", "prop", "A coopered barrel with iron hoops and a wooden lid.")
def barrel(s: Sculpt):
    s.cylinder(0, 0, 0, 11, 6, ["8A5A3A", "9B6B47"], "wood", hollow=True)
    for y in (2, 5, 8, 11):
        s.cylinder(0, 0, y, y, 6.2, "4C4039", "metal", hollow=True)
    s.cylinder(0, 0, 12, 12, 5, "A46B49", "wood")
    s.box(-2, 2, 13, 13, -1, 1, GOLD[0], "metal")

@model("prop.milkcan", "Milk Can", "prop", "A polished milk can with a lid and carry handle.")
def milkcan(s: Sculpt):
    s.cylinder(0, 0, 0, 10, 4.5, ["B8B4A7", "D8D4C8"], "metal", hollow=True)
    s.cylinder(0, 0, 10, 13, 3, ["B8B4A7", "D8D4C8"], "metal", hollow=True)
    s.cylinder(0, 0, 14, 15, 2, "4C4039", "metal")
    s.box(-1, 1, 15, 16, -1, 1, "4C4039", "metal")
    s.box(-5, -4, 8, 12, -1, 1, "4C4039", "metal")
    s.box(4, 5, 8, 12, -1, 1, "4C4039", "metal")
    s.box(-5, 5, 12, 12, -1, 1, "4C4039", "metal")

@model("prop.wateringcan", "Watering Can", "prop", "A sage-green watering can with a long spout and sprinkler rose.")
def wateringcan(s: Sculpt):
    s.cylinder(0, 0, 0, 8, 5, ["6B8F73", "7FA087"], "metal", hollow=True)
    s.cylinder(0, 0, 9, 11, 2, "6B8F73", "metal")
    s.line((-4, 7, 0), (-12, 11, 0), "6B8F73", "metal", 2)
    s.box(-14, -11, 11, 13, -2, 2, "7FA087", "metal")
    for z in (-2, 0, 2):
        s.add(-15, 12, z, "4C4039", "metal")
    s.box(-3, 3, 9, 9, -1, 1, "4C4039", "metal")
    s.box(-4, 4, 12, 12, -1, 1, "4C4039", "metal")

@model("prop.bucket", "Bucket", "prop", "A wooden bucket full of fresh water.")
def bucket(s: Sculpt):
    s.cylinder(0, 0, 0, 6, 5, "8A5A3A", "wood", hollow=True)
    s.cylinder(0, 0, 7, 7, 5, "4F7FA8", "water")
    s.cylinder(0, 0, 0, 0, 5, "5C3A24", "wood")
    s.cylinder(0, 0, 7, 7, 4.8, "4F7FA8", "water")
    s.line((-5, 7, 0), (0, 11, 0), "4C4039", "metal", 1)
    s.line((0, 11, 0), (5, 7, 0), "4C4039", "metal", 1)

@model("prop.wheelbarrow", "Wheelbarrow", "prop", "A red wheelbarrow with a wooden tray and one trusty wheel.")
def wheelbarrow(s: Sculpt):
    s.box(-10, 10, 4, 8, -6, 6, "B64B3F", "metal", hollow=True)
    s.box(-10, 10, 4, 4, -7, 7, "A74238", "metal")
    s.cylinder(0, -7, 0, 2, 3.5, "2D2622", "metal", hollow=True)
    s.line((-6, 4, 0), (-16, 4, 0), "8A5A3A", "wood", 2)
    s.line((6, 4, 0), (16, 4, 0), "8A5A3A", "wood", 2)
    s.line((-16, 4, 0), (-16, 9, 0), "8A5A3A", "wood", 2)
    s.line((16, 4, 0), (16, 9, 0), "8A5A3A", "wood", 2)
    s.box(-12, 12, 8, 9, -7, 7, "8A5A3A", "wood")
    s.box(-8, 8, 9, 9, -4, 4, "C9B391", "hay")

@model("prop.lamppost", "Lamp Post", "prop", "A wrought-iron lamp post with a warm lantern and climbing ivy.")
def lamppost(s: Sculpt):
    s.cylinder(0, 0, 0, 2, 3, "4C4039", "metal", hollow=True)
    s.line((0, 2, 0), (0, 24, 0), "4C4039", "metal", 2)
    s.box(-3, 3, 24, 25, -1, 1, "4C4039", "metal")
    s.box(-4, 4, 26, 34, -3, 3, "F0C95C", "light", hollow=True)
    s.box(-5, 5, 35, 36, -4, 4, "4C4039", "metal")
    s.box(-1, 1, 36, 37, -1, 1, "4C4039", "metal")
    s.line((2, 2, 0), (3, 7, 0), "4F8A5A", "leaf", 1)
    s.line((3, 7, 0), (2, 12, 2), "4F8A5A", "leaf", 1)

@model("prop.mailbox", "Mailbox", "prop", "A little red mailbox on a white post, flag raised.")
def mailbox(s: Sculpt):
    s.box(-2, 2, 0, 12, -2, 2, "E9D9B7", "wood")
    s.box(-5, 5, 12, 18, -4, 4, "B64B3F", "metal", hollow=True)
    s.box(-6, 6, 18, 19, -5, 5, "A74238", "metal")
    s.box(-1, 1, 13, 16, 5, 5, "2D2622", "metal")
    s.line((6, 15, 0), (6, 21, 0), "B8892E", "metal", 1)
    s.box(5, 7, 20, 22, -1, 1, "B8892E", "metal")
    s.line((2, 0, 0), (3, 5, 0), "4F8A5A", "leaf", 1)

@model("prop.bench", "Garden Bench", "prop", "A painted bench with a curved back and flower-pattern cushions.")
def bench(s: Sculpt):
    for x in (-10, 10):
        for z in (-4, 4):
            s.box(x - 1, x + 1, 0, 6, z, z, "4C4039", "metal")
    s.box(-12, 12, 6, 7, -5, 5, "8A5A3A", "wood")
    s.box(-12, 12, 7, 8, -5, -3, "C9B391", "fabric")
    s.box(-12, 12, 8, 8, -5, -3, "D95D4F", "fabric")
    s.box(-12, 12, 11, 12, -5, -4, "8A5A3A", "wood")
    for x in (-10, 0, 10):
        s.box(x, x, 8, 11, -5, -4, "C9B391", "wood")

@model("prop.picnic", "Picnic Table", "prop", "A sunny picnic table with a checked cloth and a basket.")
def picnic(s: Sculpt):
    for x in (-10, 10):
        for z in (-6, 6):
            s.box(x, x, 0, 5, z, z, "8A5A3A", "wood")
    s.box(-13, 13, 5, 6, -7, 7, "C9B391", "wood")
    s.box(-13, 13, 6, 6, -7, 7, ["B64B3F", "FFF6E4"], "fabric", checker=3)
    s.box(-16, -12, 4, 5, -6, 6, "8A5A3A", "wood")
    s.box(12, 16, 4, 5, -6, 6, "8A5A3A", "wood")
    s.box(-3, 3, 7, 12, -2, 2, "A46B49", "wood", hollow=True)
    s.line((-2, 12, 0), (2, 17, 0), "C9B391", "metal", 1)

@model("prop.scarecrow", "Scarecrow", "prop", "A straw-stuffed scarecrow with a patched coat and a crooked hat.")
def scarecrow(s: Sculpt):
    s.line((0, 0, 0), (0, 26, 0), "8A5A3A", "wood", 2)
    s.box(-12, 12, 18, 19, 0, 0, "8A5A3A", "wood")
    s.box(-8, 8, 10, 21, -2, 2, ["8B4A3D", "9D5849"], "fabric", checker=3)
    s.box(-8, 8, 11, 12, -3, 3, "C9B391", "hay")
    s.ellipsoid(0, 25, 0, 5, 5, 4, "D8C6A4", "fabric")
    s.add(-2, 26, 4, "2D2622", "eye"); s.add(2, 26, 4, "2D2622", "eye")
    s.box(-1, 1, 23, 23, 4, 4, "4C4039", "metal")
    s.box(-7, 7, 29, 30, -5, 5, "8A5A3A", "wood")
    s.box(-5, 5, 31, 33, -3, 3, "8A5A3A", "wood")
    s.line((-12, 18, 0), (-16, 12, 0), "C9B391", "hay", 2)
    s.line((12, 18, 0), (16, 12, 0), "C9B391", "hay", 2)

@model("prop.tractor", "Little Tractor", "prop", "A pea-green tractor with big rear wheels, a red seat and a smoke stack.")
def tractor(s: Sculpt):
    s.box(-12, 10, 6, 18, -8, 8, ["6B8F73", "7FA087"], "metal", hollow=True)
    s.box(-12, 12, 18, 20, -9, 9, "4F8A5A", "metal")
    s.box(-12, 2, 20, 27, -8, 8, "6B8F73", "metal", hollow=True)
    s.box(-13, 3, 27, 28, -9, 9, "4F8A5A", "metal")
    s.box(-9, 1, 28, 29, -6, 6, "4F7FA8", "glass")
    s.cylinder(-8, 0, 0, 10, 7, "2D2622", "metal", hollow=True)
    s.cylinder(10, 0, 0, 8, 5, "2D2622", "metal", hollow=True)
    s.cylinder(-8, 0, 0, 10, 2, "4C4039", "metal", hollow=True)
    s.cylinder(10, 0, 0, 8, 1.5, "4C4039", "metal", hollow=True)
    s.box(-7, -3, 19, 23, -3, 3, "B64B3F", "fabric")
    s.line((8, 18, 0), (8, 29, 0), "4C4039", "metal", 2)
    s.box(7, 9, 30, 31, -1, 1, "4C4039", "metal")
    s.box(-12, -11, 18, 19, -6, 6, "F0C95C", "light")

@model("prop.wagon", "Farm Wagon", "prop", "A wooden wagon loaded with sacks and pumpkins.")
def wagon(s: Sculpt):
    s.box(-16, 16, 5, 12, -8, 8, "8A5A3A", "wood", hollow=True)
    s.box(-17, 17, 12, 12, -9, 9, "A46B49", "wood")
    for x in (-12, -4, 4, 12):
        for z in (-8, 8):
            s.cylinder(x, z, 0, 1, 3, "2D2622", "metal", hollow=True)
    s.line((-16, 5, 0), (-23, 5, 0), "8A5A3A", "wood", 2)
    s.line((16, 5, 0), (23, 5, 0), "8A5A3A", "wood", 2)
    s.box(-9, -3, 12, 17, -4, 3, "C9B391", "hay")
    s.box(3, 9, 12, 17, -3, 4, "C9B391", "hay")
    s.ellipsoid(-3, 15, 0, 3, 3, 3, "E08A32", "crop", hollow=True, shell=0.4)
    s.ellipsoid(7, 14, 2, 2.5, 2.5, 2.5, "C94F45", "crop", hollow=True, shell=0.4)

@model("prop.bridge", "Pond Bridge", "prop", "A humped wooden bridge with handrails and mossy stone footings.")
def bridge(s: Sculpt):
    for x in range(-18, 19, 3):
        y = 2 + (18 - abs(x)) // 6
        s.box(x, x + 2, y, y + 1, -5, 5, "8A5A3A", "wood")
    for x in (-18, -6, 6, 18):
        s.box(x, x, 0, 12, -5, -5, "5C3A24", "wood")
        s.box(x, x, 0, 12, 5, 5, "5C3A24", "wood")
    for x in (-17, 0, 17):
        s.box(x - 2, x + 2, 0, 2, -7, 7, STONE, "stone")
    s.box(-18, 18, 10, 11, -5, -4, "A46B49", "wood")
    s.box(-18, 18, 10, 11, 4, 5, "A46B49", "wood")
    s.box(-18, 18, 11, 12, -5, 5, "C9B391", "fabric", hollow=True)

@model("prop.signpost", "Signpost", "prop", "A weathered signpost pointing to the pond, market and barn.")
def signpost(s: Sculpt):
    s.box(-1, 1, 0, 18, -1, 1, "8A5A3A", "wood")
    s.box(-9, 9, 15, 18, -1, 1, "C9B391", "wood")
    s.box(-8, 8, 10, 13, -1, 1, "A46B49", "wood")
    s.box(-7, 7, 5, 8, -1, 1, "C9B391", "wood")
    s.line((-9, 16, 1), (-13, 16, 1), "C9B391", "wood", 1)
    s.line((8, 11, 1), (12, 11, 1), "A46B49", "wood", 1)
    s.box(-4, 4, 19, 20, -2, 2, "4C4039", "metal")

@model("prop.birdhouse", "Birdhouse", "prop", "A tiny blue birdhouse on a post with a round door and a perch.")
def birdhouse(s: Sculpt):
    s.box(-1, 1, 0, 16, -1, 1, "8A5A3A", "wood")
    s.box(-5, 5, 16, 24, -4, 4, "4F7FA8", "wood", hollow=True)
    s.box(-6, 6, 24, 25, -5, 5, "B64B3F", "roof")
    s.box(-2, 2, 19, 22, 4, 4, "2D2622", "wood")
    s.box(-1, 1, 18, 18, 5, 6, "8A5A3A", "wood")
    s.box(-1, 1, 26, 27, -1, 1, "4C4039", "metal")

@model("prop.sundial", "Garden Sundial", "prop", "A brass sundial on a stone pedestal, surrounded by lavender.")
def sundial(s: Sculpt):
    s.cylinder(0, 0, 0, 8, 4, STONE, "stone", hollow=True)
    s.cylinder(0, 0, 9, 9, 6, ["B8892E", "D0A347"], "gold", hollow=True)
    s.box(-1, 1, 10, 14, -1, 1, "B8892E", "metal")
    s.line((0, 10, 0), (5, 12, 0), "B8892E", "metal", 1)
    for x, z in [(-6, 3), (5, 5), (6, -4)]:
        s.box(x - 2, x + 2, 0, 0, z - 1, z + 1, "8E6BC4", "flower")
        s.add(x, 1, z, "8E6BC4", "flower")

# ---------------------------------------------------------------------------
# Crops
# ---------------------------------------------------------------------------

@model("crop.wheat", "Wheat", "crop", "A golden sheaf of wheat with drooping grain heads.")
def crop_wheat(s: Sculpt):
    for x in (-5, 0, 5):
        for z in (-4, 0, 4):
            h = 18 + (x + z) % 4
            s.line((x, 0, z), (x, h, z), "B8892E", "crop", 1)
            for y in range(h - 5, h + 1, 2):
                s.box(x - 1, x + 1, y, y, z, z, "D8B65C", "crop")
    s.box(-7, 7, 0, 1, -5, 5, "8A5A3A", "soil")

@model("crop.carrot", "Carrot", "crop", "A bright carrot top with feathery leaves above the soil.")
def crop_carrot(s: Sculpt):
    s.box(-3, 3, 0, 3, -3, 3, "E08A32", "crop")
    s.line((0, 3, 0), (0, 15, 0), "4F8A5A", "leaf", 1)
    for x, z in [(-5, 0), (5, 0), (0, -5), (0, 5), (-3, -3), (3, 3)]:
        s.line((0, 6, 0), (x, 13, z), "6FA84F", "leaf", 1)
    s.box(-6, 6, 0, 0, -4, 4, "8A5A3A", "soil")

@model("crop.corn", "Corn", "crop", "A tall corn stalk with broad leaves and two golden cobs.")
def crop_corn(s: Sculpt):
    s.line((0, 0, 0), (0, 30, 0), "5A7D4F", "crop", 2)
    for y in (6, 12, 18, 24):
        s.line((0, y, 0), (-7, y + 4, 2), "6FA84F", "leaf", 2)
        s.line((0, y + 2, 0), (7, y + 6, -2), "6FA84F", "leaf", 2)
    s.ellipsoid(3, 17, 2, 2.4, 5, 2.4, "E7B93F", "crop")
    s.ellipsoid(-3, 23, -2, 2.2, 4.5, 2.2, "E7B93F", "crop")
    s.box(-5, 5, 0, 0, -4, 4, "8A5A3A", "soil")

@model("crop.tomato", "Tomato", "crop", "A bushy tomato plant with red fruit and yellow blossoms.")
def crop_tomato(s: Sculpt):
    s.line((0, 0, 0), (0, 20, 0), "4F8A5A", "crop", 2)
    for y in (5, 10, 15):
        s.line((0, y, 0), (-7, y + 3, 1), "6FA84F", "leaf", 2)
        s.line((0, y + 2, 0), (7, y + 5, -1), "6FA84F", "leaf", 2)
    for x, y, z in [(-4, 8, 3), (4, 12, -2), (0, 16, 2), (-3, 18, -3)]:
        s.ellipsoid(x, y, z, 2, 2, 2, "C94F45", "crop")
        s.add(x, y + 2, z, "4F8A5A", "leaf")
    s.add(5, 17, 3, "F0C95C", "flower")
    s.box(-5, 5, 0, 0, -4, 4, "8A5A3A", "soil")

@model("crop.strawberry", "Strawberry", "crop", "A low strawberry patch with white flowers and ruby berries.")
def crop_strawberry(s: Sculpt):
    for x, z in [(-5, -2), (0, 2), (5, -1)]:
        s.ellipsoid(x, 4, z, 4, 2.5, 4, "4F8A5A", "leaf")
        s.ellipsoid(x, 2, z + 2, 1.8, 2, 1.8, "C94F45", "crop")
        s.add(x, 5, z, "FFF6E4", "flower")
    s.box(-8, 8, 0, 0, -5, 5, "8A5A3A", "soil")

@model("crop.pumpkin", "Pumpkin", "crop", "A fat orange pumpkin on a bed of broad green leaves.")
def crop_pumpkin(s: Sculpt):
    for x, z in [(-5, 1), (4, -2), (2, 4)]:
        s.box(x, x + 3, 0, 0, z, z + 2, "4F8A5A", "leaf")
    s.ellipsoid(0, 6, 0, 7, 5, 7, ["E08A32", "F0A34A", "C97726"], "crop", hollow=True, shell=0.44, checker=2)
    s.line((0, 11, 0), (1, 15, 0), "4F8A5A", "crop", 1)
    s.box(-2, 2, 15, 15, -1, 1, "4F8A5A", "leaf")
    s.box(-8, 8, 0, 0, -6, 6, "8A5A3A", "soil")

@model("crop.sunflower", "Sunflower", "crop", "A tall sunflower with a broad golden face and dark seeds.")
def crop_sunflower(s: Sculpt):
    s.line((0, 0, 0), (0, 30, 0), "4F8A5A", "crop", 2)
    s.line((0, 12, 0), (-7, 17, 1), "6FA84F", "leaf", 2)
    s.line((0, 18, 0), (7, 23, -1), "6FA84F", "leaf", 2)
    s.ellipsoid(0, 31, 0, 6, 6, 2.5, ["F0C95C", "E7B93F"], "flower")
    s.ellipsoid(0, 31, 2, 4, 4, 1.5, "5C3A24", "crop")
    s.box(-2, 2, 31, 31, 3, 3, "2D2622", "eye")
    s.box(-1, 1, 34, 34, 3, 3, "2D2622", "eye")
    s.box(-4, 4, 0, 0, -4, 4, "8A5A3A", "soil")

@model("crop.cabbage", "Cabbage", "crop", "A tight green cabbage with ruffled outer leaves.")
def crop_cabbage(s: Sculpt):
    s.ellipsoid(0, 5, 0, 7, 5, 7, ["7AB774", "65A469", "4F8A5A"], "leaf", hollow=True, shell=0.45, checker=2)
    s.ellipsoid(0, 8, 0, 4, 3, 4, ["8FC77D", "7AB774"], "leaf", hollow=True, shell=0.45)
    for x, z in [(-6, 0), (6, 0), (0, -6), (0, 6)]:
        s.ellipsoid(x, 3, z, 3, 2, 3, "65A469", "leaf")
    s.box(-8, 8, 0, 0, -6, 6, "8A5A3A", "soil")

@model("crop.potato", "Potato", "crop", "Leafy potato tops above a mound of soft soil.")
def crop_potato(s: Sculpt):
    s.ellipsoid(0, 6, 0, 6, 4, 6, "8A5A3A", "soil")
    for x, z in [(-3, 0), (3, 0), (0, -3), (0, 3)]:
        s.line((x, 5, z), (x, 14, z), "4F8A5A", "crop", 1)
        s.ellipsoid(x, 14, z, 2.5, 2, 2.5, "6FA84F", "leaf")
    s.add(2, 2, 2, "C9A876", "crop")

# ---------------------------------------------------------------------------
# Characters
# ---------------------------------------------------------------------------

@model("character.farmer", "Farmer Wren", "character", "Farmer Wren in a straw hat, green overalls and muddy boots.")
def farmer(s: Sculpt):
    s.cylinder(0, 0, 0, 3, 4.5, "6B5A48", "fabric", hollow=True)
    s.box(-5, 5, 3, 12, -3, 3, ["4F8A5A", "5E9C68"], "fabric", hollow=True, checker=2)
    s.box(-7, 7, 12, 14, -4, 4, "8A5A3A", "fabric")
    for x in (-2, 2):
        s.add(x, 8, 3, "2D2622", "eye")
    s.ellipsoid(0, 17, 0, 5, 4.5, 4.5, "E8B78D", "skin")
    s.box(-2, 2, 15, 15, 4, 4, DARK_PINK, "skin")
    s.box(-6, 6, 20, 21, -5, 5, "E7C76B", "hay")
    s.box(-4, 4, 22, 24, -3, 3, "D8B65C", "hay")
    s.box(-5, 5, 19, 19, -5, 5, "B8892E", "hay")
    for x in (-3, 3):
        for z in (-3, 3):
            s.box(x - 1, x + 1, 0, 2, z - 1, z + 1, "5C3A24", "wood")
    s.box(-3, 3, 9, 10, 4, 4, "4F7FA8", "fabric")
    s.box(-3, 3, 9, 10, -4, -4, "4F7FA8", "fabric")

@model("character.pighero", "Pig Hero", "character", "A brave little pig with a red cape and a wooden practice sword.")
def pighero(s: Sculpt):
    s.ellipsoid(0, 12, 0, 7, 6, 10, PINK, "fur", hollow=True, shell=0.5, checker=2)
    s.ellipsoid(0, 15, 9, 5.2, 4.8, 4.6, PINK, "skin")
    s.box(-2, 2, 13, 15, 13, 16, DARK_PINK, "skin")
    s.add(-1, 14, 16, "7A3F51", "eye"); s.add(1, 14, 16, "7A3F51", "eye")
    s.box(-4, -3, 17, 18, 14, 14, "2D2622", "eye")
    s.box(3, 4, 17, 18, 14, 14, "2D2622", "eye")
    s.box(-5, -3, 19, 21, 8, 10, PINK, "skin")
    s.box(3, 5, 19, 21, 8, 10, PINK, "skin")
    for x in (-4, 4):
        for z in (-6, 6):
            s.cylinder(x, z, 0, 6, 2.4, PINK, "fur", hollow=True)
            s.box(x - 2, x + 2, 0, 1, z - 2, z + 2, "6B3A45", "skin")
    s.box(-8, 8, 10, 19, -11, -9, ["B64B3F", "C85A4E"], "fabric", checker=3)
    s.box(-2, 2, 18, 20, -8, -7, "B8892E", "metal")
    s.line((0, 13, -9), (2, 16, -12), DARK_PINK, "fur", 1)
    s.line((2, 16, -12), (0, 18, -11), DARK_PINK, "fur", 1)
    s.line((6, 12, 0), (12, 20, 4), "8A5A3A", "wood", 2)
    s.box(10, 14, 20, 21, 3, 5, "B8B4A7", "metal")

@model("character.shepherd", "Shepherd Pip", "character", "Shepherd Pip with a crook, a wool shawl and a knowing smile.")
def shepherd(s: Sculpt):
    s.cylinder(0, 0, 0, 6, 4, "6B5A48", "fabric", hollow=True)
    s.box(-5, 5, 6, 15, -3, 3, ["8E6BC4", "A17ED4"], "fabric", hollow=True, checker=2)
    s.ellipsoid(0, 20, 0, 4.5, 4.5, 4.5, "D9A97D", "skin")
    s.box(-2, 2, 18, 18, 4, 4, DARK_PINK, "skin")
    s.add(-2, 20, 4, "2D2622", "eye"); s.add(2, 20, 4, "2D2622", "eye")
    s.box(-6, 6, 24, 25, -5, 5, ["E7D7BB", "F3E6CC"], "wool")
    s.box(-4, 4, 26, 26, -4, 4, "E7D7BB", "wool")
    s.box(-7, 7, 14, 16, -5, 5, "F3E6CC", "wool")
    for x in (-3, 3):
        for z in (-3, 3):
            s.box(x - 1, x + 1, 0, 2, z - 1, z + 1, "5C3A24", "wood")
    s.line((6, 0, 0), (8, 28, 0), "8A5A3A", "wood", 1)
    s.line((8, 28, 0), (5, 30, 0), "8A5A3A", "wood", 1)
    s.line((5, 30, 0), (3, 27, 0), "8A5A3A", "wood", 1)

# ---------------------------------------------------------------------------
# Emit Swift
# ---------------------------------------------------------------------------

GROUPS = {
    "animal": ("VoxelAnimalModels", "VoxelAnimalModels.swift"),
    "building": ("VoxelBuildingModels", "VoxelBuildingModels.swift"),
    "nature": ("VoxelNatureModels", "VoxelNatureModels.swift"),
    "prop": ("VoxelPropModels", "VoxelPropModels.swift"),
    "crop": ("VoxelCropModels", "VoxelCropModels.swift"),
    "character": ("VoxelCharacterModels", "VoxelCharacterModels.swift"),
}


def swift_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


for category, (enum_name, filename) in GROUPS.items():
    entries = [entry for entry in MODELS if entry[2] == category]
    lines = [
        "import Foundation",
        "",
        "// Generated by Tools/generate_voxel_models.py.",
        "// Each row is x,y,z,RRGGBB,material and represents one real voxel.",
        "",
        f"public enum {enum_name} {{",
        "    public static let all: [VoxelModel] = [",
    ]
    for mid, name, cat, notes, sculpture in entries:
        count = len(sculpture.voxels)
        bounds = "?"
        rows = sculpture.rows()
        lines.extend([
            "        VoxelModelCodec.make(",
            f'            id: "{swift_string(mid)}",',
            f'            name: "{swift_string(name)}",',
            f"            category: .{cat},",
            f'            notes: "{swift_string(notes)} {count} voxels.",',
            '            rows: """',
        ])
        lines.extend(rows)
        lines.extend([
            '"""',
            "        ),",
        ])
    lines.extend([
        "    ]",
        "}",
        "",
    ])
    (OUT / filename).write_text("\n".join(lines), encoding="utf-8")
    print(f"{filename}: {len(lines)} lines, {len(entries)} models")

print(f"Total models: {len(MODELS)}")
print(f"Total voxels: {sum(len(s.voxels) for _, _, _, _, s in MODELS)}")
