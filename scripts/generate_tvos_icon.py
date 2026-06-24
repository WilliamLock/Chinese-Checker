#!/usr/bin/env python3
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
TV_ROOT = ROOT / "Shared" / "Assets.xcassets" / "AppIconTV.brandassets"
BOARD_SOURCE = ROOT / "Shared" / "Assets.xcassets" / "LuxuryBoardBackground.imageset" / "luxury-board-background-symmetric.png"
LARGE = (1280, 768)
SMALL = (400, 240)
SMALL_2X = (800, 480)
TOP_SHELF = (2320, 720)


def lerp(a, b, t):
    return int(a + (b - a) * t)


def cover(image, size):
    width, height = size
    scale = max(width / image.width, height / image.height)
    resized = image.resize((math.ceil(image.width * scale), math.ceil(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def board_background(size):
    if BOARD_SOURCE.exists():
        source = Image.open(BOARD_SOURCE).convert("RGBA").rotate(90, expand=True, resample=Image.Resampling.BICUBIC)
        image = cover(source, size).filter(ImageFilter.GaussianBlur(max(2, size[0] * 0.003)))
        shade = Image.new("RGBA", size, (18, 12, 8, 118))
        image.alpha_composite(shade)

        fit_scale = min(size[0] * 0.95 / source.width, size[1] * 0.90 / source.height)
        fitted = source.resize((math.floor(source.width * fit_scale), math.floor(source.height * fit_scale)), Image.Resampling.LANCZOS)
        left = (size[0] - fitted.width) // 2
        top = (size[1] - fitted.height) // 2
        image.alpha_composite(fitted, (left, top))
    else:
        image = Image.new("RGBA", size, (55, 20, 8, 255))

    # tvOS icon background layers must be fully opaque.
    opaque = Image.new("RGBA", size, (18, 12, 8, 255))
    opaque.alpha_composite(image)
    return opaque


def hex_points(size):
    width, height = size
    points = []
    spacing_x = width * 0.064
    spacing_y = height * 0.077
    center_x = width * 0.50
    start_y = height * 0.31
    for row in range(7):
        count = 5 + (row if row < 4 else 6 - row)
        y = start_y + row * spacing_y
        start_x = center_x - (count - 1) * spacing_x / 2
        for col in range(count):
            points.append((start_x + col * spacing_x, y))
    return points


def draw_board_lattice(image):
    draw = ImageDraw.Draw(image)
    points = hex_points(image.size)
    max_distance = image.size[0] * 0.073
    min_distance = image.size[0] * 0.050
    for i, (x1, y1) in enumerate(points):
        for x2, y2 in points[i + 1 :]:
            distance = math.hypot(x2 - x1, y2 - y1)
            if min_distance <= distance <= max_distance:
                draw.line((x1, y1 + 3, x2, y2 + 3), fill=(0, 0, 0, 125), width=max(4, image.size[0] // 170))
                draw.line((x1, y1, x2, y2), fill=(255, 207, 104, 218), width=max(2, image.size[0] // 310))
    radius = max(7, image.size[0] // 62)
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(10, 5, 2, 250), outline=(255, 196, 92, 210), width=max(1, radius // 5))


def radial_marble(layer, center, radius, palette, ribbon_angle):
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    draw.ellipse((cx - radius * 1.08, cy - radius * 0.66, cx + radius * 1.12, cy + radius * 0.82), fill=(0, 0, 0, 120))
    for r in range(radius, 0, -1):
        t = 1 - r / radius
        edge = r / radius
        color = (
            lerp(palette[0][0], palette[1][0], edge),
            lerp(palette[0][1], palette[1][1], edge),
            lerp(palette[0][2], palette[1][2], edge),
            255,
        )
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)

    ribbon = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(ribbon)
    rd.rounded_rectangle(
        (cx - radius * 0.15, cy - radius * 0.78, cx + radius * 0.15, cy + radius * 0.78),
        radius=max(4, int(radius * 0.12)),
        fill=(255, 255, 255, 30),
    )
    layer.alpha_composite(ribbon.rotate(ribbon_angle, center=center, resample=Image.Resampling.BICUBIC))
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(255, 232, 186, 180), width=max(3, radius // 13))
    draw.ellipse((cx - radius * 0.46, cy - radius * 0.58, cx - radius * 0.04, cy - radius * 0.22), fill=(255, 255, 255, 190))
    draw.ellipse((cx + radius * 0.18, cy - radius * 0.20, cx + radius * 0.30, cy - radius * 0.08), fill=(255, 255, 255, 120))


def draw_foreground(size):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    width, height = size
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((width * 0.20, height * 0.70, width * 0.42, height * 0.86), fill=(0, 0, 0, 112))
    sd.ellipse((width * 0.58, height * 0.16, width * 0.80, height * 0.32), fill=(0, 0, 0, 112))
    layer.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(6, width * 0.010))))

    radius = int(min(width, height) * 0.115)
    radial_marble(layer, (int(width * 0.31), int(height * 0.73)), radius, ((255, 105, 88), (72, 0, 0)), 28)
    radial_marble(layer, (int(width * 0.69), int(height * 0.27)), radius, ((154, 242, 122), (8, 74, 22)), -26)

    shine = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shine)
    sd.rounded_rectangle((-width * 0.04, height * 0.14, width * 0.76, height * 0.21), radius=int(height * 0.035), fill=(255, 255, 255, 42))
    layer.alpha_composite(shine.rotate(-10, center=(width // 2, height // 2), resample=Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(max(5, width * 0.007))))
    return layer


def make_icon(size):
    background = board_background(size)
    draw_board_lattice(background)
    foreground = draw_foreground(size)
    return background, foreground


def resize(image, size):
    return image.resize(size, Image.Resampling.LANCZOS)


def force_opaque(image):
    opaque = Image.new("RGBA", image.size, (18, 12, 8, 255))
    opaque.alpha_composite(image.convert("RGBA"))
    return opaque


def save_icon_set():
    large_bg, large_fg = make_icon(LARGE)
    large_bg = force_opaque(large_bg)
    paths = {
        TV_ROOT / "App Icon - Large.imagestack/Background.imagestacklayer/Content.imageset/background.png": large_bg,
        TV_ROOT / "App Icon - Large.imagestack/Foreground.imagestacklayer/Content.imageset/foreground.png": large_fg,
        TV_ROOT / "App Icon - Small.imagestack/Background.imagestacklayer/Content.imageset/background.png": resize(large_bg, SMALL),
        TV_ROOT / "App Icon - Small.imagestack/Foreground.imagestacklayer/Content.imageset/foreground.png": resize(large_fg, SMALL),
        TV_ROOT / "App Icon - Small.imagestack/Background.imagestacklayer/Content.imageset/background@2x.png": resize(large_bg, SMALL_2X),
        TV_ROOT / "App Icon - Small.imagestack/Foreground.imagestacklayer/Content.imageset/foreground@2x.png": resize(large_fg, SMALL_2X),
    }
    for path, image in paths.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path)

    top_bg, top_fg = make_icon(TOP_SHELF)
    top = force_opaque(Image.alpha_composite(force_opaque(top_bg), top_fg))
    top.save(TV_ROOT / "Top Shelf Image.imageset/top-shelf.png")


if __name__ == "__main__":
    save_icon_set()
    print(TV_ROOT)
