"""
Reads each individual kiran_*.json and writes village fields into the
matching _kirans_.json index entry:

  place   – first village (main.place)
  places  – unique villages in sitting order, taken from meta.locations
            ("venue, village"); falls back to main.place

Run from the repo root:
    python3 scripts/inject_kiran_places.py
"""

import json
import os

BASE = "assets/book/saxatsavita"


def villages_from(kdata: dict) -> list[str]:
    """Ordered unique villages from locations, else main.place."""
    locs = (kdata.get("meta") or {}).get("locations") or []
    out: list[str] = []
    seen: set[str] = set()
    for loc in locs:
        s = str(loc).strip()
        if not s:
            continue
        village = s.rsplit(",", 1)[-1].strip() if "," in s else s
        if village and village not in seen:
            seen.add(village)
            out.append(village)
    if not out:
        place = ((kdata.get("main") or {}).get("place") or "").strip()
        if place:
            out = [place]
    return out


total_updated = 0

for part_name in ["part1", "part2", "part3", "part4", "part5"]:
    part_dir = f"{BASE}/{part_name}"
    index_path = f"{part_dir}/_kirans_.json"

    with open(index_path, encoding="utf-8") as f:
        index = json.load(f)

    village_map: dict[int, list[str]] = {}
    for fname in sorted(os.listdir(part_dir)):
        if not (fname.startswith("kiran_") and fname.endswith(".json")):
            continue
        kiran_idx = int(fname[len("kiran_") : -len(".json")])
        with open(f"{part_dir}/{fname}", encoding="utf-8") as f:
            kdata = json.load(f)
        village_map[kiran_idx] = villages_from(kdata)

    changed = 0
    for entry in index["list"]:
        villages = village_map.get(entry["index"], [])
        place_val = villages[0] if villages else ""
        if entry.get("place") != place_val or entry.get("places") != villages:
            entry["place"] = place_val
            entry["places"] = villages
            changed += 1

    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=4)

    total = len(index["list"])
    with_place = sum(1 for e in index["list"] if e.get("place"))
    multi = sum(1 for e in index["list"] if len(e.get("places") or []) > 1)
    total_updated += changed
    print(
        f"{part_name}: {changed:3d} updated | "
        f"{with_place}/{total} have place | {multi} multi-village"
    )

print(f"\nTotal entries updated: {total_updated}")
print("Done.")
