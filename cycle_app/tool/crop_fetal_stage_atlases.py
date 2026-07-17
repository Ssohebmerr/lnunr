"""Crop three 2x2 generated atlases into optimized Flutter WebP assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


STAGE_NAMES = (
    "stage_01_zygote",
    "stage_02_cleavage",
    "stage_03_blastocyst",
    "stage_04_implantation",
    "stage_05_week05",
    "stage_06_week07",
    "stage_07_week09",
    "stage_08_week12",
    "stage_09_week16",
    "stage_10_week22",
    "stage_11_week30",
    "stage_12_week38",
)


def crop_atlas(source: Path, output: Path, names: tuple[str, ...]) -> None:
    with Image.open(source) as image:
        image = image.convert("RGB")
        width, height = image.size
        half_width = width // 2
        half_height = height // 2
        gutter = max(2, round(min(width, height) * 0.004))
        boxes = (
            (0, 0, half_width - gutter, half_height - gutter),
            (half_width + gutter, 0, width, half_height - gutter),
            (0, half_height + gutter, half_width - gutter, height),
            (half_width + gutter, half_height + gutter, width, height),
        )
        for name, box in zip(names, boxes, strict=True):
            tile = image.crop(box)
            side = min(tile.size)
            left = (tile.width - side) // 2
            top = (tile.height - side) // 2
            tile = tile.crop((left, top, left + side, top + side))
            tile = tile.resize((640, 640), Image.Resampling.LANCZOS)
            tile.save(output / f"{name}.webp", "WEBP", quality=92, method=6)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--early", type=Path, required=True)
    parser.add_argument("--first-trimester", type=Path, required=True)
    parser.add_argument("--later", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    crop_atlas(args.early, args.output, STAGE_NAMES[0:4])
    crop_atlas(args.first_trimester, args.output, STAGE_NAMES[4:8])
    crop_atlas(args.later, args.output, STAGE_NAMES[8:12])


if __name__ == "__main__":
    main()
