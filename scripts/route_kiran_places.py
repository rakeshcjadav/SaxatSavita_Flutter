"""
Precompute driving-road geometries between kiran villages.

Reads places.json and _all_kirans_.json, collects unique directed hops
from year vicharan and same-day sittings, then asks OSRM once per hop.
Writes assets/book/saxatsavita/routes.json for the map to load.

Re-run after places.json coordinates change. Existing hops are skipped
so the script can resume.

Run from the repo root:
    python3 scripts/route_kiran_places.py
    python3 scripts/route_kiran_places.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import time
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIRANS_PATH = ROOT / "assets/book/saxatsavita/_all_kirans_.json"
PLACES_PATH = ROOT / "assets/book/saxatsavita/places.json"
ROUTES_PATH = ROOT / "assets/book/saxatsavita/routes.json"

OSRM_URL = "https://router.project-osrm.org/route/v1/driving/{coords}"
USER_AGENT = "SakshatSavita/1.0 (vicharan-routes; one-time catalog)"
MIN_POINT_GAP_M = 70.0
REQUEST_GAP_S = 1.1


def village_names_from(item: dict) -> list[str]:
    places = item.get("places") or []
    names = [str(p).strip() for p in places if str(p).strip()]
    place = str(item.get("place") or "").strip()
    if not names and place:
        names = [place]
    return names


def parse_kiran_date(date_str: str) -> tuple[int, int, int] | None:
    parts = str(date_str or "").split("-")
    if len(parts) != 3:
        return None
    try:
        day, month, year = (int(parts[0]), int(parts[1]), int(parts[2]))
    except ValueError:
        return None
    if year < 100:
        year = 1900 + year if year >= 50 else 2000 + year
    return year, month, day


def haversine_m(a: tuple[float, float], b: tuple[float, float]) -> float:
    lat1, lon1 = math.radians(a[0]), math.radians(a[1])
    lat2, lon2 = math.radians(b[0]), math.radians(b[1])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    )
    return 2 * 6371000 * math.asin(math.sqrt(h))


def thin_path(points: list[list[float]], min_gap_m: float) -> list[list[float]]:
    if len(points) <= 2:
        return points
    kept = [points[0]]
    for point in points[1:-1]:
        prev = kept[-1]
        if haversine_m((prev[0], prev[1]), (point[0], point[1])) >= min_gap_m:
            kept.append(point)
    kept.append(points[-1])
    return kept


def load_places() -> tuple[dict[str, dict], dict[str, dict]]:
    with PLACES_PATH.open(encoding="utf-8") as f:
        data = json.load(f)
    by_name: dict[str, dict] = {}
    by_id: dict[str, dict] = {}
    for item in data.get("places") or []:
        place_id = str(item.get("id") or "").strip()
        if not place_id:
            continue
        by_id[place_id] = item
        for name in item.get("names") or []:
            by_name[str(name)] = item
    return by_name, by_id


def mapped_stops(names: list[str], by_name: dict[str, dict]) -> list[dict]:
    stops: list[dict] = []
    last_id: str | None = None
    for name in names:
        place = by_name.get(name)
        if place is None:
            continue
        place_id = place["id"]
        if place_id == last_id:
            continue
        stops.append(place)
        last_id = place_id
    return stops


def collect_hops(by_name: dict[str, dict]) -> list[tuple[str, str]]:
    with KIRANS_PATH.open(encoding="utf-8") as f:
        data = json.load(f)
    kirans = []
    for item in data.get("list") or []:
        parsed = parse_kiran_date(str(item.get("date") or ""))
        if parsed is None:
            continue
        kirans.append((parsed, int(item.get("index") or 0), item))
    kirans.sort(key=lambda row: (row[0], row[1]))

    hops: set[tuple[str, str]] = set()

    def add_sequence(stops: list[dict]) -> None:
        for i in range(len(stops) - 1):
            src, dst = stops[i]["id"], stops[i + 1]["id"]
            if src != dst:
                hops.add((src, dst))

    last_id_by_year: dict[int, str] = {}
    for (year, _month, _day), _index, item in kirans:
        stops = mapped_stops(village_names_from(item), by_name)
        add_sequence(stops)
        for stop in stops:
            prev = last_id_by_year.get(year)
            if prev is not None and prev != stop["id"]:
                hops.add((prev, stop["id"]))
            last_id_by_year[year] = stop["id"]

    return sorted(hops)


def osrm_route(src: dict, dst: dict) -> tuple[list[list[float]], int] | None:
    coords = f"{src['lng']},{src['lat']};{dst['lng']},{dst['lat']}"
    query = urllib.parse.urlencode(
        {
            "overview": "simplified",
            "geometries": "geojson",
            "alternatives": "false",
            "steps": "false",
        }
    )
    url = f"{OSRM_URL.format(coords=coords)}?{query}"
    try:
        completed = subprocess.run(
            ["curl", "-sS", "--max-time", "30", "-A", USER_AGENT, url],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        print(f"  OSRM error {src['id']} -> {dst['id']}: {exc}")
        return None
    if completed.returncode != 0:
        err = completed.stderr.strip() or f"curl exit {completed.returncode}"
        print(f"  OSRM error {src['id']} -> {dst['id']}: {err}")
        return None
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        print(f"  OSRM error {src['id']} -> {dst['id']}: {exc}")
        return None

    if payload.get("code") != "Ok":
        print(f"  OSRM {payload.get('code')} {src['id']} -> {dst['id']}")
        return None
    routes = payload.get("routes") or []
    if not routes:
        return None
    geometry = routes[0].get("geometry") or {}
    lnglat = geometry.get("coordinates") or []
    if len(lnglat) < 2:
        return None
    path = [
        [round(float(lat), 5), round(float(lng), 5)] for lng, lat in lnglat
    ]
    path = thin_path(path, MIN_POINT_GAP_M)
    distance_m = int(round(float(routes[0].get("distance") or 0)))
    return path, distance_m


def load_existing() -> dict[tuple[str, str], dict]:
    if not ROUTES_PATH.exists():
        return {}
    with ROUTES_PATH.open(encoding="utf-8") as f:
        data = json.load(f)
    existing: dict[tuple[str, str], dict] = {}
    for item in data.get("routes") or []:
        key = (item.get("from"), item.get("to"))
        if key[0] and key[1] and item.get("path"):
            existing[key] = item
    return existing


def write_routes(routes: list[dict]) -> None:
    routes = sorted(routes, key=lambda item: (item["from"], item["to"]))
    payload = {
        "source": "osrm",
        "profile": "driving",
        "routes": routes,
    }
    with ROUTES_PATH.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    by_name, by_id = load_places()
    hops = collect_hops(by_name)
    print(f"Unique directed hops: {len(hops)}")
    for src_id, dst_id in hops:
        src = by_id[src_id]
        dst = by_id[dst_id]
        print(f"  {src.get('en')} -> {dst.get('en')}")

    if args.dry_run:
        return

    existing = load_existing()
    routes = list(existing.values())
    pending = [hop for hop in hops if hop not in existing]
    print(f"Already routed: {len(existing)}")
    print(f"To route: {len(pending)}")

    failed = 0
    for i, (src_id, dst_id) in enumerate(pending, start=1):
        src, dst = by_id[src_id], by_id[dst_id]
        print(f"[{i}/{len(pending)}] {src.get('en')} -> {dst.get('en')}", flush=True)
        result = osrm_route(src, dst)
        if result is None:
            failed += 1
        else:
            path, distance_m = result
            routes.append(
                {
                    "from": src_id,
                    "to": dst_id,
                    "distance_m": distance_m,
                    "path": path,
                }
            )
            write_routes(routes)
        if i < len(pending):
            time.sleep(REQUEST_GAP_S)

    write_routes(routes)
    print(f"Wrote {ROUTES_PATH.relative_to(ROOT)}")
    print(f"Routed: {len(routes)}  failed: {failed}")


if __name__ == "__main__":
    main()
