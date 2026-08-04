"""Build the high-resolution macro map and hover layers from an approved source.

The source art remains the visual authority. Region polygons only define the
interactive hit/hover silhouettes; no labels or UI are baked into the result.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


REGION_POLYGONS = {
    "consumption": [
        (0.273, 0.435), (0.255, 0.414), (0.251, 0.389), (0.268, 0.363),
        (0.286, 0.347), (0.284, 0.321), (0.305, 0.298), (0.330, 0.277),
        (0.360, 0.260), (0.390, 0.242), (0.425, 0.230), (0.460, 0.223),
        (0.488, 0.236), (0.512, 0.250), (0.527, 0.273), (0.523, 0.303),
        (0.535, 0.325), (0.526, 0.349), (0.531, 0.378), (0.520, 0.400),
        (0.516, 0.429), (0.493, 0.432), (0.468, 0.443), (0.435, 0.444),
        (0.392, 0.427), (0.345, 0.421), (0.302, 0.431),
    ],
    "industry": [
        (0.535, 0.245), (0.565, 0.220), (0.608, 0.208), (0.655, 0.195),
        (0.698, 0.188), (0.727, 0.210), (0.727, 0.249), (0.742, 0.272),
        (0.750, 0.311), (0.748, 0.354), (0.740, 0.397), (0.726, 0.440),
        (0.704, 0.455), (0.673, 0.463), (0.637, 0.473), (0.599, 0.480),
        (0.568, 0.472), (0.540, 0.458), (0.513, 0.451), (0.516, 0.429),
        (0.532, 0.384), (0.543, 0.329), (0.548, 0.278),
    ],
    "finance": [
        (0.273, 0.435), (0.302, 0.431), (0.345, 0.421), (0.392, 0.427),
        (0.435, 0.444), (0.468, 0.443), (0.493, 0.432), (0.513, 0.451),
        (0.500, 0.490), (0.494, 0.532), (0.495, 0.578), (0.489, 0.625),
        (0.491, 0.680), (0.480, 0.731), (0.457, 0.756), (0.423, 0.766),
        (0.386, 0.773), (0.349, 0.765), (0.314, 0.748), (0.282, 0.719),
        (0.267, 0.680), (0.260, 0.632), (0.262, 0.586), (0.253, 0.548),
        (0.258, 0.504), (0.266, 0.470),
    ],
    "government": [
        (0.513, 0.451), (0.540, 0.458), (0.568, 0.472), (0.599, 0.480),
        (0.637, 0.473), (0.673, 0.463), (0.704, 0.455), (0.723, 0.493),
        (0.733, 0.529), (0.740, 0.574), (0.736, 0.621), (0.726, 0.664),
        (0.707, 0.699), (0.683, 0.733), (0.654, 0.757), (0.622, 0.770),
        (0.590, 0.776), (0.557, 0.762), (0.530, 0.741), (0.508, 0.713),
        (0.491, 0.680), (0.489, 0.625), (0.495, 0.578), (0.494, 0.532),
        (0.500, 0.490),
    ],
}


def scaled_points(points: list[tuple[float, float]], size: tuple[int, int]):
    width, height = size
    return [(round(x * width), round(y * height)) for x, y in points]


def build_assets(source_path: Path, output_root: Path) -> None:
    source = Image.open(source_path).convert("RGB")
    target_size = (source.width * 2, source.height * 2)
    master = source.resize(target_size, Image.Resampling.LANCZOS)
    master = master.filter(ImageFilter.UnsharpMask(radius=1.15, percent=118, threshold=3))

    output_root.mkdir(parents=True, exist_ok=True)
    region_root = output_root / "regions_v2"
    region_root.mkdir(parents=True, exist_ok=True)

    master_path = output_root / "macro_map_master_v2.webp"
    master.save(master_path, "WEBP", quality=95, method=6)

    metadata: dict[str, dict[str, list[float]]] = {}
    for region_id, normalized_points in REGION_POLYGONS.items():
        full_mask = Image.new("L", target_size, 0)
        ImageDraw.Draw(full_mask).polygon(scaled_points(normalized_points, target_size), fill=255)
        full_mask = full_mask.filter(ImageFilter.GaussianBlur(radius=1.2))

        # Keep lightweight full-canvas hit masks. Their resolution is already
        # sufficient for precise mouse hit testing and avoids Web memory waste.
        hit_mask = full_mask.resize(source.size, Image.Resampling.LANCZOS)
        hit_mask.save(region_root / f"macro_map_mask_{region_id}_v2.png", optimize=True)

        bbox = full_mask.getbbox()
        if bbox is None:
            raise RuntimeError(f"Empty region polygon: {region_id}")
        padding = 10
        left = max(0, bbox[0] - padding)
        top = max(0, bbox[1] - padding)
        right = min(target_size[0], bbox[2] + padding)
        bottom = min(target_size[1], bbox[3] + padding)
        crop_box = (left, top, right, bottom)

        layer = master.crop(crop_box).convert("RGBA")
        layer.putalpha(full_mask.crop(crop_box))
        layer.save(region_root / f"macro_map_region_{region_id}_v2.webp", "WEBP", quality=94, method=6)

        metadata[region_id] = {
            "layer_rect": [
                left / target_size[0],
                top / target_size[1],
                (right - left) / target_size[0],
                (bottom - top) / target_size[1],
            ],
            "polygon": [[x, y] for x, y in normalized_points],
        }

    (region_root / "macro_map_v2_metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"master={master_path} size={target_size[0]}x{target_size[1]}")
    print(json.dumps(metadata, ensure_ascii=False))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_root", type=Path)
    args = parser.parse_args()
    build_assets(args.source, args.output_root)


if __name__ == "__main__":
    main()
