"""
Merges all kirans from the 5 parts, sorts them chronologically by date,
and writes a combined index to:

    assets/book/saxatsavita/_all_kirans_.json

Structure of each entry in the output list:
  {
    "part":       1,            # source part number (1-5)
    "index":      1,            # kiran index (unique across all parts)
    "number":     "૧.",         # display number string
    "title":      "...",
    "word_count": 800,
    "date":       "20-5-1975"   # 'D-M-YYYY'; empty string if unknown
  }

Entries without a date are placed at the END of the list, sorted by part
then by index.

Run from the repo root:
    python3 scripts/sort_kirans_by_date.py
"""

import json
import os
from datetime import date

BASE = "assets/book/saxatsavita"
OUTPUT = f"{BASE}/_all_kirans_.json"


def parse_date(date_str: str) -> date | None:
    """Parse 'D-M-YYYY' → datetime.date, or return None."""
    if not date_str:
        return None
    parts = date_str.split("-")
    if len(parts) != 3:
        return None
    try:
        d, m, y = int(parts[0]), int(parts[1]), int(parts[2])
        # Legacy 2-digit year fallback (should not appear after inject script)
        if y < 100:
            y = 1900 + y if y >= 50 else 2000 + y
        return date(y, m, d)
    except (ValueError, OverflowError):
        return None


# ── Load ─────────────────────────────────────────────────────────────────────

all_entries: list[dict] = []

for part_num in range(1, 6):
    path = f"{BASE}/part{part_num}/_kirans_.json"
    with open(path, encoding="utf-8") as f:
        index = json.load(f)
    for entry in index["list"]:
        all_entries.append(
            {
                "part":       part_num,
                "index":      entry["index"],
                "number":     entry.get("number", ""),
                "title":      entry.get("title", ""),
                "word_count": entry.get("word_count", 0),
                "date":       entry.get("date", ""),
            }
        )

# ── Sort ─────────────────────────────────────────────────────────────────────

def sort_key(e: dict):
    d = parse_date(e["date"])
    if d is None:
        # No date → sort after all dated entries, then by part / index
        return (1, 9999, 12, 31, e["part"], e["index"])
    return (0, d.year, d.month, d.day, e["part"], e["index"])

all_entries.sort(key=sort_key)

# ── Write ─────────────────────────────────────────────────────────────────────

dated_count = sum(1 for e in all_entries if e["date"])

output = {
    "total":  len(all_entries),
    "dated":  dated_count,
    "list":   all_entries,
}

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=4)

print(f"Written: {OUTPUT}")
print(f"Total entries : {len(all_entries)}")
print(f"With date     : {dated_count}")
print(f"Without date  : {len(all_entries) - dated_count}")

# ── Preview first and last 5 dated entries ────────────────────────────────────

print("\nFirst 5 (chronological):")
for e in [e for e in all_entries if e["date"]]:
    print(f"  [{e['date']:>12}]  part{e['part']}  #{e['index']:3d}  {e['title']}")

print("\nLast 5 (chronological):")
for e in [e for e in all_entries if e["date"]][-5:]:
    print(f"  [{e['date']:>12}]  part{e['part']}  #{e['index']:3d}  {e['title']}")
