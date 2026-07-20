#!/usr/bin/env python3
"""Build the Chinese font subset used by the Godot project before Web export."""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

try:
    from fontTools import subset
    from fontTools.ttLib import TTFont
except ImportError as error:
    raise SystemExit(
        "fonttools is required to build the Web font subset. "
        "Install it with: python -m pip install fonttools"
    ) from error


PROJECT_ROOT = Path(__file__).resolve().parent.parent
FONT_DIR = PROJECT_ROOT / "assets" / "fonts"
SOURCE_FONT = FONT_DIR / "NotoSansSC-Regular.full.ttf.bak"
OUTPUT_FONT = FONT_DIR / "NotoSansSC-Regular.ttf"
SCAN_SUFFIXES = {".gd", ".tscn", ".tres", ".json", ".cfg"}
EXCLUDED_DIRECTORIES = {
    ".git",
    ".godot",
    ".godot_cli_user",
    "web_build",
    "releases",
    "root_index",
    "docs",
    "temp",
    "tmp",
    "backup",
    "node_modules",
    "temp_online_check",
}

FIXED_TEXT = """
章节关卡解锁锁完成前一关顺序选择已解锁未解锁确认取消智慧点数请求提示单击以继续
本轮总结模型回放政策财政货币经济顾问大臣季度公元当前问题理论面板国家地图
CIGTYiISLMADASDebtGDPNPVIRR
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
↑↓→←π%-–—/\\·:：;；,，.。!！?？“”‘’（）()[]【】《》、 \n
"""

KEY_CHARACTERS = "顺序解锁关卡提示π↑↓"


def should_scan(path: Path) -> bool:
    relative = path.relative_to(PROJECT_ROOT)
    if any(part in EXCLUDED_DIRECTORIES for part in relative.parts):
        return False
    if path.suffix.lower() not in SCAN_SUFFIXES:
        return False
    return not path.name.endswith(".bak")


def collect_project_characters() -> tuple[str, int]:
    characters: set[str] = set(FIXED_TEXT)
    scanned_files = 0
    for path in PROJECT_ROOT.rglob("*"):
        if not path.is_file() or not should_scan(path):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = path.read_text(encoding="utf-8-sig")
        characters.update(text)
        scanned_files += 1
    return "".join(sorted(characters)), scanned_files


def glyphs_in_font(font_path: Path) -> set[int]:
    font = TTFont(font_path, lazy=True)
    cmap: set[int] = set()
    for table in font["cmap"].tables:
        cmap.update(table.cmap.keys())
    font.close()
    return cmap


def build_subset(characters: str) -> None:
    if not SOURCE_FONT.is_file():
        raise SystemExit(f"Full source font is missing: {SOURCE_FONT}")

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_glyph = True
    options.notdef_outline = True
    options.recalc_timestamp = False

    font = TTFont(SOURCE_FONT)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=characters)
    subsetter.subset(font)

    with tempfile.NamedTemporaryFile(
        prefix="NotoSansSC-Regular.", suffix=".tmp.ttf", dir=FONT_DIR, delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
    try:
        font.save(temporary_path)
        temporary_path.replace(OUTPUT_FONT)
    finally:
        font.close()
        if temporary_path.exists():
            temporary_path.unlink()


def main() -> int:
    characters, scanned_files = collect_project_characters()
    print(f"Scanned files: {scanned_files}")
    print(f"Unique characters: {len(characters)}")
    build_subset(characters)

    cmap = glyphs_in_font(OUTPUT_FONT)
    missing = [character for character in KEY_CHARACTERS if ord(character) not in cmap]
    if missing:
        raise SystemExit("Subset validation failed; missing key characters: " + ", ".join(missing))

    print(f"Subset font: {OUTPUT_FONT}")
    print(f"Subset size: {OUTPUT_FONT.stat().st_size} bytes")
    print("Key character check: PASS (顺 序 解 锁 关 卡 提 示 π ↑ ↓)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
