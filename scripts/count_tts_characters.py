#!/usr/bin/env python3
"""
Count total characters across all exported kiran text files.

Default input folder:
  scripts/tts_output

Usage:
  python3 scripts/count_tts_characters.py
  python3 scripts/count_tts_characters.py --root scripts/tts_output
  python3 scripts/count_tts_characters.py --exclude-whitespace
"""

from __future__ import annotations

import argparse
from pathlib import Path


def count_chars(text: str, exclude_whitespace: bool) -> int:
    if not exclude_whitespace:
        return len(text)
    return sum(1 for ch in text if not ch.isspace())


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Count total characters in scripts/tts_output across all kiran txt files",
    )
    parser.add_argument(
        "--root",
        default="scripts/tts_output",
        help="Root folder containing exported kiran txt files",
    )
    parser.add_argument(
        "--exclude-whitespace",
        action="store_true",
        help="Ignore spaces/newlines/tabs while counting",
    )
    args = parser.parse_args()

    root = Path(args.root)
    if not root.exists() or not root.is_dir():
        print(f"Root directory not found: {root}")
        return 1

    files = sorted(root.rglob("kiran_*.txt"))
    if not files:
        print(f"No kiran text files found under: {root}")
        return 1

    grand_total = 0
    per_part: dict[str, int] = {}

    for file_path in files:
        text = file_path.read_text(encoding="utf-8")
        n = count_chars(text, args.exclude_whitespace)
        grand_total += n

        part_name = file_path.parent.name
        per_part[part_name] = per_part.get(part_name, 0) + n

    mode = "excluding whitespace" if args.exclude_whitespace else "including whitespace"

    print(f"Files scanned: {len(files)}")
    print(f"Count mode: {mode}")
    print(f"Grand total characters: {grand_total}")
    print("")
    print("Per-part totals:")
    for part_name in sorted(per_part.keys()):
        print(f"  {part_name}: {per_part[part_name]}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
