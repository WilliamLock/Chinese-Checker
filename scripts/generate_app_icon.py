#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "ReleaseAssets" / "AppIcon" / "app-icon-source.png"
OUT_DIR = ROOT / "Shared" / "Assets.xcassets" / "AppIcon.appiconset"
ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]

if not SOURCE.exists():
    raise FileNotFoundError(f"Missing icon source: {SOURCE}")

source = Image.open(SOURCE).convert("RGB")
OUT_DIR.mkdir(parents=True, exist_ok=True)

for icon_size in ICON_SIZES:
    resized = source.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    resized.save(OUT_DIR / f"app-icon-{icon_size}.png")

print(OUT_DIR / "app-icon-1024.png")
