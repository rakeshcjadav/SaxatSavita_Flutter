"""
Reads each individual kiran_*.json, extracts the publication date from
main.content (or meta.date if present), then writes a 'date' field into
every entry of the corresponding _kirans_.json index file.

Output format: 'D-M-YYYY'  (e.g. '23-6-1975', '2-11-1977').
All years are stored as 4-digit values.

Handles the two number-systems found in the source texts:
  - Gujarati numerals  ૦-૯  (U+0AE6-U+0AEF)
  - Gujarati consonants used as look-alike digits in older typesetting:
        ર  (U+0AB0)  →  2
        પ  (U+0AAA)  →  5

Run from the repo root:
    python3 scripts/inject_kiran_dates.py
"""

import json
import re
import os

# Maps Gujarati numerals AND look-alike consonants → ASCII digits
GU_TO_ASCII = str.maketrans(
    "૦૧૨૩૪૫૬૭૮૯"   # proper Gujarati numerals U+0AE6-U+0AEF
    "રપ",            # look-alike consonants: ર=2 (U+0AB0), પ=5 (U+0AAA)
    "0123456789"
    "25",
)

# Some kirans write 'તા.' (with period) and some 'તા ' (space only) — make
# the period optional.
_D = r"[\u0AE6-\u0AEF\u0AB0\u0AAA\d]+"
DATE_RE = re.compile(r"તા\.?\s*(" + _D + r")-(" + _D + r")-(" + _D + r")")


def _to_int(gu_str: str) -> int:
    return int(gu_str.translate(GU_TO_ASCII))


def _normalize_year(yy: int) -> int:
    """Expand a 2-digit year to 4-digit; leave 4-digit years untouched."""
    if yy >= 100:
        return yy
    return 1900 + yy if yy >= 50 else 2000 + yy


def extract_date(content: str) -> str:
    """Return 'D-M-YYYY' extracted from *content*, or '' if not found."""
    m = DATE_RE.search(content)
    if not m:
        return ""
    try:
        d  = _to_int(m.group(1))
        mo = _to_int(m.group(2))
        y  = _normalize_year(_to_int(m.group(3)))
        # Sanity-check the parsed values
        if not (1 <= d <= 31 and 1 <= mo <= 12 and 1900 <= y <= 2100):
            return ""
        return f"{d}-{mo}-{y}"
    except (ValueError, OverflowError):
        return ""


BASE = "assets/book/saxatsavita"

total_updated = 0

for part_name in ["part1", "part2", "part3", "part4", "part5"]:
    part_dir = f"{BASE}/{part_name}"
    index_path = f"{part_dir}/_kirans_.json"

    with open(index_path, encoding="utf-8") as f:
        index = json.load(f)

    # Build {kiran_index: date_string} from individual kiran_*.json files
    date_map: dict[int, str] = {}
    for fname in sorted(os.listdir(part_dir)):
        if not (fname.startswith("kiran_") and fname.endswith(".json")):
            continue
        kiran_idx = int(fname[len("kiran_"):-len(".json")])
        with open(f"{part_dir}/{fname}", encoding="utf-8") as f:
            kdata = json.load(f)
        meta_date = kdata.get("meta", {}).get("date", "").strip()
        if meta_date:
            # Normalize meta.date (may still be old 2-digit-year format)
            parts = meta_date.split("-")
            if len(parts) == 3:
                try:
                    d  = int(parts[0])
                    mo = int(parts[1])
                    y  = _normalize_year(int(parts[2]))
                    if 1 <= d <= 31 and 1 <= mo <= 12 and 1900 <= y <= 2100:
                        date_map[kiran_idx] = f"{d}-{mo}-{y}"
                        continue
                except ValueError:
                    pass
        date_map[kiran_idx] = extract_date(kdata["main"]["content"])

    changed = 0
    for entry in index["list"]:
        date_val = date_map.get(entry["index"], "")
        if entry.get("date") != date_val:
            entry["date"] = date_val
            changed += 1

    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=4)

    total = len(index["list"])
    with_date = sum(1 for e in index["list"] if e.get("date"))
    total_updated += changed
    print(f"{part_name}: {changed:3d} updated | {with_date}/{total} have dates")

print(f"\nTotal entries updated: {total_updated}")
print("Done.")
