"""Pixel-accurate region segmentation and verification for the macro map.

The rough polygons are seeds only. OpenCV GrabCut snaps them to the visual
region colors/coastline, then a marker watershed resolves the four shared
borders into a gap-free, non-overlapping partition of the central landmass.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageFilter

from generate_macro_map_v2_assets import REGION_POLYGONS


REGION_IDS = ("consumption", "industry", "finance", "government")
VERIFY_COLORS = {
    "consumption": (74, 226, 114),
    "industry": (72, 171, 255),
    "finance": (204, 105, 255),
    "government": (255, 205, 72),
}

# User-reviewed correction at the finance/industry junction. This small zone
# covers the blue land spur that the automatic watershed previously assigned
# to finance. Only pixels currently labelled as finance are eligible to move.
FINANCE_TO_INDUSTRY_CORRECTION = [
    (0.481, 0.426),
    (0.511, 0.426),
    (0.521, 0.442),
    (0.516, 0.463),
    (0.508, 0.482),
    (0.501, 0.501),
    (0.489, 0.494),
    (0.481, 0.473),
]


def polygon_mask(size: tuple[int, int], points: list[tuple[float, float]]) -> np.ndarray:
    width, height = size
    pixels = np.array(
        [[round(x * (width - 1)), round(y * (height - 1))] for x, y in points],
        dtype=np.int32,
    )
    result = np.zeros((height, width), dtype=np.uint8)
    cv2.fillPoly(result, [pixels], 255)
    return result


def kernel(radius: int) -> np.ndarray:
    diameter = radius * 2 + 1
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (diameter, diameter))


def keep_seed_component(mask: np.ndarray, seed: np.ndarray) -> np.ndarray:
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8), 8)
    if count <= 1:
        return mask.astype(bool)
    best_label = max(
        range(1, count),
        key=lambda label: int(np.count_nonzero((labels == label) & seed.astype(bool))),
    )
    return labels == best_label


def fill_holes(mask: np.ndarray) -> np.ndarray:
    binary = (mask.astype(np.uint8) * 255) if mask.dtype == bool else mask.copy()
    flood = binary.copy()
    flood_mask = np.zeros((binary.shape[0] + 2, binary.shape[1] + 2), dtype=np.uint8)
    cv2.floodFill(flood, flood_mask, (0, 0), 255)
    return (binary | cv2.bitwise_not(flood)) > 0


def grabcut_region(image_bgr: np.ndarray, rough: np.ndarray) -> np.ndarray:
    # The hand-authored polygon is never used as the final alpha. It supplies a
    # conservative foreground core and a generous search window for edge snap.
    probable = cv2.dilate(rough, kernel(24), iterations=1)
    search = cv2.dilate(rough, kernel(70), iterations=1)
    core = cv2.erode(rough, kernel(22), iterations=1)

    grab_mask = np.full(rough.shape, cv2.GC_PR_BGD, dtype=np.uint8)
    grab_mask[search == 0] = cv2.GC_BGD
    grab_mask[probable > 0] = cv2.GC_PR_FGD
    grab_mask[core > 0] = cv2.GC_FGD
    background_model = np.zeros((1, 65), dtype=np.float64)
    foreground_model = np.zeros((1, 65), dtype=np.float64)
    cv2.grabCut(
        image_bgr,
        grab_mask,
        None,
        background_model,
        foreground_model,
        8,
        cv2.GC_INIT_WITH_MASK,
    )
    selected = np.logical_or(grab_mask == cv2.GC_FGD, grab_mask == cv2.GC_PR_FGD)
    selected &= search > 0
    selected = cv2.morphologyEx(selected.astype(np.uint8), cv2.MORPH_CLOSE, kernel(3)) > 0
    selected = cv2.morphologyEx(selected.astype(np.uint8), cv2.MORPH_OPEN, kernel(1)) > 0
    selected = keep_seed_component(selected, core)
    return fill_holes(selected)


def build_partition(image_bgr: np.ndarray) -> dict[str, np.ndarray]:
    height, width = image_bgr.shape[:2]
    size = (width, height)
    rough_masks = {key: polygon_mask(size, REGION_POLYGONS[key]) for key in REGION_IDS}
    candidates = {
        key: grabcut_region(image_bgr, rough_masks[key])
        for key in REGION_IDS
    }

    union = np.logical_or.reduce([candidates[key] for key in REGION_IDS])
    union = cv2.morphologyEx(union.astype(np.uint8), cv2.MORPH_CLOSE, kernel(2)) > 0
    union_seed = np.logical_or.reduce([cv2.erode(rough_masks[key], kernel(18)) > 0 for key in REGION_IDS])
    union = keep_seed_component(union, union_seed)
    union = fill_holes(union)

    markers = np.zeros((height, width), dtype=np.int32)
    markers[~cv2.dilate(union.astype(np.uint8), kernel(2)).astype(bool)] = len(REGION_IDS) + 1
    for index, region_id in enumerate(REGION_IDS, start=1):
        seed = cv2.erode(candidates[region_id].astype(np.uint8), kernel(7)) > 0
        # Prevent overlapping seeds from writing conflicting watershed labels.
        for other_id in REGION_IDS:
            if other_id != region_id:
                seed &= ~cv2.erode(candidates[other_id].astype(np.uint8), kernel(2)).astype(bool)
        markers[seed] = index

    watershed_input = cv2.bilateralFilter(image_bgr, 7, 28, 7)
    cv2.watershed(watershed_input, markers)

    valid_label = np.logical_and(markers >= 1, markers <= len(REGION_IDS))
    unresolved = union & ~valid_label
    if np.any(unresolved):
        distance_fields = []
        for index in range(1, len(REGION_IDS) + 1):
            distance_fields.append(
                cv2.distanceTransform((markers != index).astype(np.uint8), cv2.DIST_L2, 5)
            )
        nearest = np.argmin(np.stack(distance_fields, axis=0), axis=0) + 1
        markers[unresolved] = nearest[unresolved]

    return {
        region_id: np.logical_and(markers == index, union)
        for index, region_id in enumerate(REGION_IDS, start=1)
    }


def apply_reviewed_local_correction(masks: dict[str, np.ndarray]) -> tuple[np.ndarray, int]:
    height, width = masks["finance"].shape
    correction_zone = polygon_mask((width, height), FINANCE_TO_INDUSTRY_CORRECTION) > 0
    moved = masks["finance"] & correction_zone
    masks["finance"] = masks["finance"] & ~moved
    masks["industry"] = masks["industry"] | moved
    return correction_zone, int(np.count_nonzero(moved))


def boundary(mask: np.ndarray, radius: int = 1) -> np.ndarray:
    eroded = cv2.erode(mask.astype(np.uint8), kernel(radius)) > 0
    return mask & ~eroded


def edge_metrics(image_bgr: np.ndarray, masks: dict[str, np.ndarray]) -> dict[str, dict[str, float]]:
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (0, 0), 1.1)
    edges = cv2.Canny(gray, 42, 105)
    distance = cv2.distanceTransform((edges == 0).astype(np.uint8), cv2.DIST_L2, 5)
    result: dict[str, dict[str, float]] = {}
    for region_id, mask in masks.items():
        values = distance[boundary(mask, 1)]
        result[region_id] = {
            "area_ratio": round(float(np.count_nonzero(mask) / mask.size), 6),
            "boundary_edge_distance_median_px": round(float(np.median(values)), 3),
            "boundary_edge_distance_p90_px": round(float(np.percentile(values, 90)), 3),
        }
    return result


def topology_metrics(masks: dict[str, np.ndarray]) -> dict[str, float | int]:
    stack = np.stack([masks[key].astype(np.uint8) for key in REGION_IDS], axis=0)
    coverage = np.sum(stack, axis=0)
    union = coverage > 0
    components, _ = cv2.connectedComponents(union.astype(np.uint8), 8)
    return {
        "union_area_ratio": round(float(np.count_nonzero(union) / union.size), 6),
        "overlap_pixels": int(np.count_nonzero(coverage > 1)),
        "union_connected_components": int(max(0, components - 1)),
        "unassigned_inside_union_pixels": int(np.count_nonzero(union & (coverage == 0))),
    }


def load_versioned_masks(root: Path, shape: tuple[int, int], version: str) -> dict[str, np.ndarray] | None:
    masks: dict[str, np.ndarray] = {}
    for region_id in REGION_IDS:
        path = root / f"macro_map_mask_{region_id}_{version}.png"
        image = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
        if image is None:
            return None
        if image.shape != shape:
            image = cv2.resize(image, (shape[1], shape[0]), interpolation=cv2.INTER_LINEAR)
        masks[region_id] = image >= 128
    return masks


def render_verification(
    image_rgb: np.ndarray,
    masks: dict[str, np.ndarray],
    output_path: Path,
) -> None:
    overlay = image_rgb.copy()
    for region_id in REGION_IDS:
        color = np.array(VERIFY_COLORS[region_id], dtype=np.uint8)
        line = boundary(masks[region_id], 2)
        overlay[line] = color
    # A 50/50 label-map panel makes overlaps, holes, and coastline mistakes easy
    # to spot without relying on the runtime hover animation.
    label_panel = np.zeros_like(image_rgb)
    for region_id in REGION_IDS:
        label_panel[masks[region_id]] = VERIFY_COLORS[region_id]
    label_panel = cv2.addWeighted(image_rgb, 0.35, label_panel, 0.65, 0.0)
    combined = np.concatenate([overlay, label_panel], axis=1)
    rendered = Image.fromarray(combined).resize(
        (combined.shape[1] // 2, combined.shape[0] // 2), Image.Resampling.LANCZOS
    )
    temporary_path = output_path.with_suffix(".tmp.png")
    rendered.save(temporary_path, "PNG", optimize=True)
    temporary_path.replace(output_path)


def save_assets(
    master: Image.Image,
    work_masks: dict[str, np.ndarray],
    output_root: Path,
) -> dict[str, dict[str, list[float]]]:
    output_root.mkdir(parents=True, exist_ok=True)
    master_size = master.size
    work_height, work_width = next(iter(work_masks.values())).shape
    metadata: dict[str, dict[str, list[float]]] = {}

    for region_id in REGION_IDS:
        work_mask = (work_masks[region_id].astype(np.uint8) * 255)
        hit_path = output_root / f"macro_map_mask_{region_id}_v3.png"
        hit_temporary_path = hit_path.with_suffix(".tmp.png")
        Image.fromarray(work_mask, "L").save(hit_temporary_path, optimize=True)
        hit_temporary_path.replace(hit_path)

        high_mask = Image.fromarray(work_mask, "L").resize(master_size, Image.Resampling.LANCZOS)
        high_mask = high_mask.filter(ImageFilter.GaussianBlur(radius=0.55))
        bbox = high_mask.getbbox()
        if bbox is None:
            raise RuntimeError(f"Empty final mask: {region_id}")
        padding = 12
        left = max(0, bbox[0] - padding)
        top = max(0, bbox[1] - padding)
        right = min(master_size[0], bbox[2] + padding)
        bottom = min(master_size[1], bbox[3] + padding)
        crop_box = (left, top, right, bottom)

        layer = master.crop(crop_box).convert("RGBA")
        layer.putalpha(high_mask.crop(crop_box))
        layer_path = output_root / f"macro_map_region_{region_id}_v3.webp"
        layer_temporary_path = layer_path.with_suffix(".tmp.webp")
        layer.save(
            layer_temporary_path,
            "WEBP",
            quality=95,
            method=6,
        )
        layer_temporary_path.replace(layer_path)
        metadata[region_id] = {
            "layer_rect": [
                left / master_size[0],
                top / master_size[1],
                (right - left) / master_size[0],
                (bottom - top) / master_size[1],
            ]
        }

    return metadata


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("master", type=Path)
    parser.add_argument("output_root", type=Path)
    parser.add_argument("--baseline-root", type=Path)
    parser.add_argument("--preserve-root", type=Path)
    args = parser.parse_args()

    master = Image.open(args.master).convert("RGB")
    work = master.resize((master.width // 2, master.height // 2), Image.Resampling.LANCZOS)
    image_rgb = np.asarray(work)
    image_bgr = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2BGR)
    cv2.setRNGSeed(0)
    preserved = None
    if args.preserve_root:
        preserved = load_versioned_masks(args.preserve_root, (work.height, work.width), "v3")
    masks = build_partition(image_bgr)
    before_local_fix = {region_id: mask.copy() for region_id, mask in masks.items()}
    correction_zone, moved_pixels = apply_reviewed_local_correction(masks)

    report: dict[str, object] = {
        "work_resolution": [work.width, work.height],
        "output_resolution": [master.width, master.height],
        "topology": topology_metrics(masks),
        "regions": edge_metrics(image_bgr, masks),
        "reviewed_local_fix": {
            "from": "finance",
            "to": "industry",
            "moved_pixels": moved_pixels,
        },
    }
    if args.baseline_root:
        baseline = load_versioned_masks(args.baseline_root, (work.height, work.width), "v2")
        if baseline is not None:
            report["baseline_v2"] = {
                "topology": topology_metrics(baseline),
                "regions": edge_metrics(image_bgr, baseline),
            }

    topology = report["topology"]
    assert isinstance(topology, dict)
    failures: list[str] = []
    if topology["overlap_pixels"] != 0:
        failures.append("region masks overlap")
    if topology["union_connected_components"] != 1:
        failures.append("central land union is not one connected component")
    if not 0.12 <= float(topology["union_area_ratio"]) <= 0.30:
        failures.append("central land coverage is outside expected range")
    for region_id, metrics in report["regions"].items():
        if not 0.02 <= float(metrics["area_ratio"]) <= 0.10:
            failures.append(f"{region_id} area is outside expected range")
        if float(metrics["boundary_edge_distance_median_px"]) > 4.0:
            failures.append(f"{region_id} boundary is not aligned to visual edges")

    if moved_pixels <= 0:
        failures.append("reviewed finance-to-industry correction moved no pixels")
    operation_guard: dict[str, dict[str, int]] = {}
    for region_id in REGION_IDS:
        changed = np.logical_xor(before_local_fix[region_id], masks[region_id])
        changed_outside_zone = changed & ~correction_zone
        operation_guard[region_id] = {
            "changed_pixels": int(np.count_nonzero(changed)),
            "changed_outside_local_zone": int(np.count_nonzero(changed_outside_zone)),
        }
    report["local_operation_guard"] = operation_guard
    if operation_guard["consumption"]["changed_pixels"] != 0:
        failures.append("local correction operation changed consumption")
    if operation_guard["government"]["changed_pixels"] != 0:
        failures.append("local correction operation changed government")
    if operation_guard["industry"]["changed_pixels"] != moved_pixels:
        failures.append("industry change count does not match moved finance pixels")
    if operation_guard["finance"]["changed_pixels"] != moved_pixels:
        failures.append("finance change count does not match moved industry pixels")
    for region_id in REGION_IDS:
        if operation_guard[region_id]["changed_outside_local_zone"] != 0:
            failures.append(f"local correction changed {region_id} outside reviewed zone")
    if preserved is not None:
        preserve_metrics: dict[str, dict[str, int]] = {}
        for region_id in REGION_IDS:
            changed = np.logical_xor(preserved[region_id], masks[region_id])
            changed_outside_zone = changed & ~correction_zone
            preserve_metrics[region_id] = {
                "changed_pixels": int(np.count_nonzero(changed)),
                "changed_outside_local_zone": int(np.count_nonzero(changed_outside_zone)),
            }
        report["local_change_guard"] = preserve_metrics
        if preserve_metrics["consumption"]["changed_pixels"] != 0:
            failures.append("consumption mask changed during blue/purple local fix")
        if preserve_metrics["government"]["changed_pixels"] != 0:
            failures.append("government mask changed during blue/purple local fix")
        for region_id in REGION_IDS:
            if preserve_metrics[region_id]["changed_outside_local_zone"] != 0:
                failures.append(f"{region_id} changed outside reviewed local zone")

    metadata = save_assets(master, masks, args.output_root)
    report["metadata"] = metadata
    report["passed"] = not failures
    report["failures"] = failures
    report_path = args.output_root / "macro_map_v3_validation.json"
    report_temporary_path = report_path.with_suffix(".tmp.json")
    report_temporary_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    report_temporary_path.replace(report_path)
    render_verification(image_rgb, masks, args.output_root / "macro_map_v3_verification.png")

    print(json.dumps(report, ensure_ascii=False, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
