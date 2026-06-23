#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFilter
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Shared" / "Assets.xcassets" / "AppIcon.appiconset" / "app-icon-1024.png"
SIZE = 1024


def lerp(a, b, t):
    return int(a + (b - a) * t)


def radial_marble(draw, center, radius, palette, ribbon_angle):
    cx, cy = center
    for r in range(radius, 0, -1):
        t = r / radius
        color = (
            lerp(palette[0][0], palette[1][0], t),
            lerp(palette[0][1], palette[1][1], t),
            lerp(palette[0][2], palette[1][2], t),
            255,
        )
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)

    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    ribbon_w = radius * 0.36
    ribbon_h = radius * 1.65
    od.rounded_rectangle(
        (cx - ribbon_w / 2, cy - ribbon_h / 2, cx + ribbon_w / 2, cy + ribbon_h / 2),
        radius=int(ribbon_w / 2),
        fill=(20, 8, 8, 120),
    )
    rotated = overlay.rotate(ribbon_angle, center=center, resample=Image.Resampling.BICUBIC)
    base.alpha_composite(rotated)

    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(255, 255, 255, 135), width=5)
    draw.ellipse((cx - radius * 0.45, cy - radius * 0.54, cx - radius * 0.05, cy - radius * 0.24), fill=(255, 255, 255, 150))


base = Image.new("RGBA", (SIZE, SIZE), (28, 1, 5, 255))
draw = ImageDraw.Draw(base)

for y in range(SIZE):
    t = y / (SIZE - 1)
    for x in range(SIZE):
        s = (x / (SIZE - 1)) * 0.35
        r = lerp(96, 24, t) + int(32 * s)
        g = lerp(9, 1, t)
        b = lerp(12, 5, t)
        base.putpixel((x, y), (r, g, b, 255))

grain = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(grain)
for i in range(34):
    y = 86 + i * 29
    alpha = 22 if i % 3 == 0 else 11
    gd.rounded_rectangle((-120, y, SIZE + 120, y + 5 + (i % 4)), radius=8, fill=(255, 210, 190, alpha))
grain = grain.rotate(-12, center=(SIZE // 2, SIZE // 2), resample=Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(3))
base.alpha_composite(grain)

board = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
bd = ImageDraw.Draw(board)
polygon = [(202, 98), (822, 98), (934, 218), (934, 806), (808, 930), (216, 930), (90, 806), (90, 218)]
bd.polygon([(x, y + 34) for x, y in polygon], fill=(52, 0, 4, 230))
bd.polygon(polygon, fill=(108, 5, 12, 245))
bd.line(polygon + [polygon[0]], fill=(255, 210, 190, 95), width=8)
bd.line([(934, 218), (934, 806), (808, 930), (216, 930), (90, 806)], fill=(18, 0, 2, 170), width=10)
base.alpha_composite(board)

points = []
spacing = 68
for row in range(7):
    count = 4 + row
    y = 300 + row * 58
    start = 512 - (count - 1) * spacing / 2
    for col in range(count):
        points.append((start + col * spacing, y))

for i, (x, y) in enumerate(points):
    for j, (x2, y2) in enumerate(points):
        if j <= i:
            continue
        d = math.hypot(x - x2, y - y2)
        if 58 <= d <= 76:
            bd = ImageDraw.Draw(base)
            bd.line((x, y, x2, y2), fill=(220, 230, 238, 90), width=5)
            bd.line((x, y + 3, x2, y2 + 3), fill=(0, 0, 0, 55), width=8)

draw = ImageDraw.Draw(base)
for x, y in points:
    draw.ellipse((x - 18, y - 18, x + 18, y + 18), fill=(38, 0, 4, 210), outline=(255, 255, 255, 72), width=3)

radial_marble(draw, (392, 724), 92, ((255, 104, 36), (70, 3, 3)), 28)
radial_marble(draw, (636, 286), 92, ((255, 236, 36), (90, 62, 2)), -26)

shine = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(shine)
sd.rounded_rectangle((-80, 140, 930, 206), radius=34, fill=(255, 255, 255, 38))
shine = shine.rotate(-18, center=(SIZE // 2, SIZE // 2), resample=Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(12))
base.alpha_composite(shine)

OUT.parent.mkdir(parents=True, exist_ok=True)
base.save(OUT)
print(OUT)
