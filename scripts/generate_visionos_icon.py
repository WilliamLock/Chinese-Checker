#!/usr/bin/env python3
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
VISION_ROOT = ROOT / "Shared" / "Assets.xcassets" / "AppIconVision.solidimagestack"
BOARD_SOURCE = ROOT / "Shared" / "Assets.xcassets" / "LuxuryBoardBackground.imageset" / "luxury-board-background-symmetric.png"
SIZE = (1024, 1024)


def cover(image, size):
    width, height = size
    scale = max(width / image.width, height / image.height)
    resized = image.resize((math.ceil(image.width * scale), math.ceil(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def lerp(a, b, t):
    return int(a + (b - a) * t)


def make_background():
    if BOARD_SOURCE.exists():
        source = Image.open(BOARD_SOURCE).convert("RGBA")
        image = cover(source, SIZE).filter(ImageFilter.GaussianBlur(1.2))
        shade = Image.new("RGBA", SIZE, (32, 12, 5, 78))
        image.alpha_composite(shade)
    else:
        image = Image.new("RGBA", SIZE, (88, 24, 10, 255))

    opaque = Image.new("RGBA", SIZE, (66, 18, 8, 255))
    opaque.alpha_composite(image)
    return opaque


def board_points():
    points = []
    spacing_x = 78
    spacing_y = 67
    center_x = SIZE[0] * 0.5
    start_y = 298
    for row in range(7):
        count = 5 + (row if row < 4 else 6 - row)
        y = start_y + row * spacing_y
        start_x = center_x - (count - 1) * spacing_x / 2
        for col in range(count):
            points.append((start_x + col * spacing_x, y))
    return points


def make_middle():
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    points = board_points()
    for i, (x1, y1) in enumerate(points):
        for x2, y2 in points[i + 1 :]:
            distance = math.hypot(x2 - x1, y2 - y1)
            if 62 <= distance <= 86:
                draw.line((x1, y1 + 3, x2, y2 + 3), fill=(0, 0, 0, 105), width=10)
                draw.line((x1, y1, x2, y2), fill=(248, 194, 86, 225), width=5)
    for x, y in points:
        draw.ellipse((x - 18, y - 18, x + 18, y + 18), fill=(12, 6, 3, 252), outline=(255, 197, 82, 220), width=4)
    return layer


def radial_marble(draw, center, radius, palette):
    cx, cy = center
    draw.ellipse((cx - radius * 1.08, cy - radius * 0.72, cx + radius * 1.12, cy + radius * 0.88), fill=(0, 0, 0, 115))
    for r in range(radius, 0, -1):
        edge = r / radius
        color = (
            lerp(palette[0][0], palette[1][0], edge),
            lerp(palette[0][1], palette[1][1], edge),
            lerp(palette[0][2], palette[1][2], edge),
            255,
        )
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(255, 229, 182, 190), width=6)
    draw.ellipse((cx - radius * 0.46, cy - radius * 0.58, cx - radius * 0.05, cy - radius * 0.22), fill=(255, 255, 255, 188))


def make_front():
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    radial_marble(draw, (352, 710), 104, ((255, 105, 88), (74, 0, 0)))
    radial_marble(draw, (666, 314), 104, ((148, 240, 120), (6, 74, 22)))
    return layer


def write_json(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n")


def write_layer(name, filename, image):
    layer_root = VISION_ROOT / f"{name}.solidimagestacklayer"
    image_path = layer_root / "Content.imageset" / filename
    image_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(image_path)
    write_json(
        layer_root / "Contents.json",
        """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
""",
    )
    write_json(
        image_path.parent / "Contents.json",
        f"""
{{
  "images" : [
    {{
      "filename" : "{filename}",
      "idiom" : "vision",
      "scale" : "2x"
    }}
  ],
  "info" : {{
    "author" : "xcode",
    "version" : 1
  }}
}}
""",
    )


def main():
    if VISION_ROOT.exists():
        for path in sorted(VISION_ROOT.rglob("*"), reverse=True):
            if path.is_file():
                path.unlink()
            elif path.is_dir():
                path.rmdir()
    VISION_ROOT.mkdir(parents=True, exist_ok=True)
    write_layer("Back", "visionos-back.png", make_background())
    write_layer("Middle", "visionos-middle.png", make_middle())
    write_layer("Front", "visionos-front.png", make_front())
    write_json(
        VISION_ROOT / "Contents.json",
        """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "layers" : [
    {
      "filename" : "Front.solidimagestacklayer"
    },
    {
      "filename" : "Middle.solidimagestacklayer"
    },
    {
      "filename" : "Back.solidimagestacklayer"
    }
  ]
}
""",
    )
    print(VISION_ROOT)


if __name__ == "__main__":
    main()
