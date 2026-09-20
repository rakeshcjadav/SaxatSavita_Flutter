"""
Build a curated village coordinate catalog from kiran place names.

Reads unique `place` / `places` values from
`assets/book/saxatsavita/_all_kirans_.json` and writes
`assets/book/saxatsavita/places.json`.

Coordinates are committed (not geocoded at runtime). Each pin is a real
village/town (OSM, census/taluka gazetteers, Wikipedia, GeoNames) —
not a guessed offset around Junagadh. Aliases such as ઇવનગર / ઈવનગર
share one record. Homonyms are disambiguated from same-day vicharan
(e.g. Bodka = Manavadar, not Vanthali; Khambhle = Sultanabad/Khambhla).

Run from the repo root:
    python3 scripts/geocode_kiran_places.py
"""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIRANS_PATH = ROOT / "assets/book/saxatsavita/_all_kirans_.json"
PLACES_PATH = ROOT / "assets/book/saxatsavita/places.json"

# Junagadh city — default for unmatched Saurashtra villages.
DEFAULT_LAT = 21.5222
DEFAULT_LNG = 70.4579

# Curated catalog. `names` lists Gujarati spellings used in kiran JSON.
KNOWN_PLACES: list[dict] = [
    {
        "id": "piplana",
        "names": ["પીપલાણા"],
        "en": "Piplana",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.439511,
        "lng": 70.242075,
    },
    {
        "id": "junagadh",
        "names": ["જૂનાગઢ"],
        "en": "Junagadh",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.5222,
        "lng": 70.4579,
    },
    {
        "id": "vanthali",
        "names": ["વંથલી"],
        "en": "Vanthali",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.47751,
        "lng": 70.332301,
    },
    {
        "id": "kalana",
        "names": ["કલાણા"],
        "en": "Kalana",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.592826,
        "lng": 70.28291,
    },
    {
        "id": "ivanagar",
        "names": ["ઇવનગર", "ઈવનગર"],
        "en": "Ivanagar",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.477083,
        "lng": 70.433137,
    },
    {
        "id": "shapur",
        "names": ["શાપુર"],
        "en": "Shapur",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.46724,
        "lng": 70.374848,
    },
    {
        "id": "manavadar",
        "names": ["માણાવદર"],
        "en": "Manavadar",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.491671,
        "lng": 70.137952,
    },
    {
        "id": "haliyad",
        "names": ["હળિયાદ"],
        "en": "Haliyad",
        "district": "Amreli",
        "region": "saurashtra",
        "lat": 21.505161,
        "lng": 70.871231,
    },
    {
        "id": "gorviyali",
        "names": ["ગોરવીયાળી"],
        "en": "Gorviyali",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.524276,
        "lng": 70.830894,
    },
    {
        "id": "rajkot",
        "names": ["રાજકોટ"],
        "en": "Rajkot",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 22.3039,
        "lng": 70.8022,
    },
    {
        "id": "mumbai",
        "names": ["મુંબઈ"],
        "en": "Mumbai",
        "district": "Mumbai",
        "region": "mumbai",
        "lat": 19.076,
        "lng": 72.8777,
    },
    {
        "id": "sardargadh",
        "names": ["સરદારગઢ"],
        "en": "Sardargadh",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.572618,
        "lng": 70.199984,
    },
    {
        "id": "keshod",
        "names": ["કેશોદ"],
        "en": "Keshod",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.299677,
        "lng": 70.250957,
    },
    {
        "id": "limbuda",
        "names": ["લીંબુડા"],
        "en": "Limbuda",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.572049,
        "lng": 70.088536,
    },
    {
        "id": "sanosara",
        "names": ["સણોસરા"],
        "en": "Sanosara",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.524063,
        "lng": 70.195632,
    },
    {
        "id": "chudva",
        "names": ["ચુડવા"],
        "en": "Chudva",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.592217,
        "lng": 70.228987,
    },
    {
        "id": "paneli_moti",
        "names": ["પાનેલી"],
        "en": "Paneli Moti",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.872609,
        "lng": 70.154605,
    },
    {
        "id": "upleta",
        "names": ["ઉપલેટા"],
        "en": "Upleta",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.740876,
        "lng": 70.277134,
    },
    {
        "id": "dhoraji",
        "names": ["ધોરાજી"],
        "en": "Dhoraji",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.734548,
        "lng": 70.447876,
    },
    {
        "id": "bhader",
        "names": ["ભાડેર"],
        "en": "Bhader",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.607296,
        "lng": 70.326866,
    },
    {
        "id": "kutiyana",
        "names": ["કુતિયાણા"],
        "en": "Kutiyana",
        "district": "Porbandar",
        "region": "saurashtra",
        "lat": 21.6241,
        "lng": 69.98494,
    },
    {
        "id": "vadtal",
        "names": ["વરતાલ"],
        "en": "Vadtal",
        "district": "Kheda",
        "region": "central_gujarat",
        "lat": 22.5875,
        "lng": 72.7528,
    },
    {
        "id": "mendarda",
        "names": ["મેંદરડા"],
        "en": "Mendarda",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.322066,
        "lng": 70.442498,
    },
    {
        "id": "ajab",
        "names": ["અજાબ"],
        "en": "Ajab",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.26401,
        "lng": 70.355199,
    },
    {
        "id": "thana_pipali",
        "names": ["થાણાપીપળી"],
        "en": "Thana Pipali",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.40777,
        "lng": 70.362196,
    },
    {
        "id": "agatray",
        "names": ["અગતરાય"],
        "en": "Agatray",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.364403,
        "lng": 70.254137,
    },
    {
        "id": "bodka",
        "names": ["બોડકા"],
        "en": "Bodka",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.478393,
        "lng": 70.235583,
    },
    {
        "id": "sukhpur",
        "names": ["સુખપુર"],
        "en": "Sukhpur",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.425052,
        "lng": 70.44325,
    },
    {
        "id": "thaniyana",
        "names": ["થાનિયાણા"],
        "en": "Thaniyana",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.615076,
        "lng": 70.216778,
    },
    {
        "id": "patanvav",
        "names": ["પાટણવાવ"],
        "en": "Patanvav",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.641098,
        "lng": 70.261734,
    },
    {
        "id": "bholgamde",
        "names": ["ભોલગામડે"],
        "en": "Bholgamde",
        "district": "Rajkot",
        "region": "saurashtra",
        "lat": 21.723813,
        "lng": 70.342105,
    },
    {
        "id": "mahobatpara",
        "names": ["મહોબતપરા"],
        "en": "Mahobatpara",
        "district": "Porbandar",
        "region": "saurashtra",
        "lat": 21.66695,
        "lng": 70.02338,
    },
    {
        "id": "mesvan",
        "names": ["મેસવાણ"],
        "en": "Mesvan",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.260017,
        "lng": 70.281537,
    },
    {
        "id": "khambhle",
        "names": ["ખાંભલે"],
        "en": "Khambhla",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.494411,
        "lng": 70.105118,
    },
    {
        "id": "araniyala",
        "names": ["અરણીયાળા"],
        "en": "Araniyala",
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": 21.354933,
        "lng": 70.365543,
    },
    {
        "id": "munjiyasar",
        "names": ["મુંજીયાસર"],
        "en": "Munjiyasar",
        "district": "Amreli",
        "region": "saurashtra",
        "lat": 21.489167,
        "lng": 70.900556,
    },
    {
        "id": "nadiad",
        "names": ["નડિયાદ"],
        "en": "Nadiad",
        "district": "Kheda",
        "region": "central_gujarat",
        "lat": 22.6916,
        "lng": 72.8615,
    },
    {
        "id": "matunga",
        "names": ["માટુંગા"],
        "en": "Matunga",
        "district": "Mumbai",
        "region": "mumbai",
        "lat": 19.027,
        "lng": 72.8553,
    },
    {
        "id": "ghatkopar",
        "names": ["ઘાટકોપર"],
        "en": "Ghatkopar",
        "district": "Mumbai",
        "region": "mumbai",
        "lat": 19.086,
        "lng": 72.908,
    },
    {
        "id": "dadar",
        "names": ["દાદર"],
        "en": "Dadar",
        "district": "Mumbai",
        "region": "mumbai",
        "lat": 19.018,
        "lng": 72.844,
    },
    {
        "id": "malad",
        "names": ["મલાડ"],
        "en": "Malad",
        "district": "Mumbai",
        "region": "mumbai",
        "lat": 19.1864,
        "lng": 72.8484,
    },
    # 1979 Maharashtra vicharan — real coords, grouped with mumbai so the
    # All-years camera stays on the Saurashtra cluster.
    {
        "id": "sangli",
        "names": ["સાંગલી"],
        "en": "Sangli",
        "district": "Sangli",
        "region": "mumbai",
        "lat": 16.8524,
        "lng": 74.5815,
    },
    {
        "id": "karad",
        "names": ["કરાડ"],
        "en": "Karad",
        "district": "Satara",
        "region": "mumbai",
        "lat": 17.2895,
        "lng": 74.1818,
    },
    {
        "id": "kolhapur",
        "names": ["કોલ્હાપુર"],
        "en": "Kolhapur",
        "district": "Kolhapur",
        "region": "mumbai",
        "lat": 16.705,
        "lng": 74.2433,
    },
]


def village_names_from(item: dict) -> list[str]:
    places = item.get("places") or []
    names = [str(p).strip() for p in places if str(p).strip()]
    place = str(item.get("place") or "").strip()
    if not names and place:
        names = [place]
    return names


def unique_names(kirans: list[dict]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for item in kirans:
        for name in village_names_from(item):
            if name not in seen:
                seen.add(name)
                ordered.append(name)
    return ordered


def fallback_place(name: str, index: int) -> dict:
    """Spread unmatched villages around Junagadh so markers do not stack."""
    offset = (index + 1) * 0.012
    slug = "place_" + "_".join(f"{ord(c):x}" for c in name[:12])
    return {
        "id": slug,
        "names": [name],
        "en": name,
        "district": "Junagadh",
        "region": "saurashtra",
        "lat": round(DEFAULT_LAT + offset * 0.25, 4),
        "lng": round(DEFAULT_LNG + offset, 4),
    }


def main() -> None:
    with KIRANS_PATH.open(encoding="utf-8") as f:
        data = json.load(f)
    kirans = data.get("list") or []
    names = unique_names(kirans)

    lookup: dict[str, dict] = {}
    for place in KNOWN_PLACES:
        for alias in place["names"]:
            lookup[alias] = place

    assigned: dict[str, dict] = {}
    unmatched: list[str] = []

    for name in names:
        known = lookup.get(name)
        if known is None:
            unmatched.append(name)
            continue
        record = assigned.setdefault(known["id"], deepcopy(known))
        if name not in record["names"]:
            record["names"].append(name)

    for i, name in enumerate(unmatched):
        record = fallback_place(name, i)
        assigned[record["id"]] = record

    places = sorted(assigned.values(), key=lambda p: (p["region"], p["en"]))
    payload = {"places": places}

    PLACES_PATH.parent.mkdir(parents=True, exist_ok=True)
    with PLACES_PATH.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"Unique village names: {len(names)}")
    print(f"Places written: {len(places)}")
    print(f"Wrote {PLACES_PATH.relative_to(ROOT)}")
    if unmatched:
        print("Unmatched names (assigned Junagadh-default coords):")
        for name in unmatched:
            print(f"  - {name}")
    else:
        print("Unmatched names: none")


if __name__ == "__main__":
    main()
