"""
Extract named swamis from kiran JSON and write them into indexes.

Writes:
  - swamis[] on each assets/book/saxatsavita/partN/_kirans_.json entry
  - assets/book/saxatsavita/swamis/swamis.json  (name → kirans)

Bare સ્વામી (the speaking swami of the sabha) is not a named saint and is
left out. Kirtan or vachanamrut readings are mentions, not a reader role.

Does not rewrite individual kiran_*.json files.

Run from the repo root:
    python3 scripts/inject_swami_names.py
"""

from __future__ import annotations

import json
import os
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets" / "book" / "saxatsavita"
ALIASES_PATH = ROOT / "scripts" / "swami_aliases.json"
OUTPUT = BASE / "swamis" / "swamis.json"

# Longer endings first so આનંદ wins over નંદ when both could anchor.
STEM_ENDINGS = (
    "આનંદ",
    "પ્રસાદ",
    "પ્રકાશ",
    "નારાયણ",
    "સ્વરૂપ",
    "વલ્લભ",
    "ચરણ",
    "જીવન",
    "મુકુંદ",
    "દાસ",
    "નંદ",
)

# Real names that do not end in STEM_ENDINGS.
EXTRA_STEMS = (
    "ગોવિંદ",
    "ગોંવિદ",
    "વિષ્ણુ",
    "બળદેવ",
    "વાસુદેવ",
    "યોગેશ્વર",
)

HTML_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"[\s\u00a0]+")
QUESTION_LEAD_RE = re.compile(r"^(?:ો|ું|ા)*\s*(?:જે|કે)\s*[;:,]?\s*")
QUESTION_STOP_RE = re.compile(r"\s+(?:પછી|તેનો ઉત્તર|તેનો જવાબ)")
QUESTION_MARKERS = ("પ્રશ્ન પૂછ્ય", "પ્રશ્ન પુછ્ય")

STEM_RE = (
    "(?:"
    + "|".join(EXTRA_STEMS)
    + r"|[\u0A80-\u0AFF]{2,}(?:"
    + "|".join(STEM_ENDINGS)
    + "))"
)
SWAMI_RE = re.compile(
    r"(?<![\u0A80-\u0AFF])"
    r"(" + STEM_RE + r")"
    r"\s*સ્વામી"
    r"(ના|ની|નું|નુ|નો|ને|નાં|એ|માં|થી)?"
    r"(?![\u0A80-\u0AFF])"
)

ROLE_RANK = {"question": 0, "mentioned": 1}


def load_overrides() -> tuple[dict[str, str], set[str]]:
    if not ALIASES_PATH.exists():
        return {}, set()
    data = json.loads(ALIASES_PATH.read_text(encoding="utf-8"))
    aliases = {
        str(k).strip(): str(v).strip()
        for k, v in (data.get("aliases") or {}).items()
        if str(k).strip() and str(v).strip()
    }
    drop = {str(x).strip() for x in (data.get("drop") or []) if str(x).strip()}
    return aliases, drop


def strip_html(value: str) -> str:
    text = HTML_RE.sub(" ", value)
    text = text.replace("&nbsp;", " ").replace("&amp;", "&")
    return WS_RE.sub(" ", text).strip()


def _stem_matches(stem: str) -> bool:
    if stem in EXTRA_STEMS:
        return True
    return any(stem.endswith(ending) and len(stem) > len(ending) + 1 for ending in STEM_ENDINGS)


def strip_honorific_ji(stem: str) -> str:
    if stem.endswith("જી"):
        base = stem[: -len("જી")]
        if base and _stem_matches(base):
            return base
    return stem


def spaced_name(stem: str) -> str:
    return f"{strip_honorific_ji(stem)} સ્વામી"


def apply_alias(name: str, aliases: dict[str, str]) -> str:
    seen = set()
    current = name
    while current in aliases and current not in seen:
        seen.add(current)
        current = aliases[current]
    return current


def canonical_name(stem: str, aliases: dict[str, str]) -> str:
    spaced = spaced_name(stem)
    return apply_alias(spaced, aliases)


def question_text_after(text: str, after: int) -> str:
    rest = QUESTION_LEAD_RE.sub("", text[after:], count=1)
    rest = WS_RE.sub(" ", rest).strip()
    if not rest:
        return ""
    qmark = rest.find("?")
    if 0 <= qmark <= 360:
        question = rest[: qmark + 1].strip()
    else:
        stop = QUESTION_STOP_RE.search(rest)
        end = stop.start() if stop and stop.start() >= 12 else min(len(rest), 220)
        question = rest[:end].strip(" ,;।.")
    question = question.strip(" \"“”'‘’")
    return question if len(question) >= 8 else ""


def _is_question(text: str, match: re.Match[str]) -> tuple[bool, str]:
    if match.group(2) != "એ":
        return False, ""
    rest = text[match.end() :]
    for marker in QUESTION_MARKERS:
        if rest.startswith(marker) or rest.startswith(" " + marker):
            offset = rest.find(marker)
            question = question_text_after(text, match.end() + offset + len(marker))
            return True, question
    return False, ""


def extract_kiran(
    kdata: dict, aliases: dict[str, str], drop: set[str]
) -> tuple[list[dict], dict[str, str]]:
    """People in this kiran, and surface spellings mapped to canonical names."""
    content = strip_html(str((kdata.get("main") or {}).get("content") or ""))
    by_name: dict[str, dict] = {}
    surfaces: dict[str, str] = {}

    for match in SWAMI_RE.finditer(content):
        stem = match.group(1)
        name = canonical_name(stem, aliases)
        raw_spaced = f"{stem} સ્વામી"
        raw_glued = f"{stem}સ્વામી"
        if not name or name in drop or raw_spaced in drop or raw_glued in drop:
            continue
        is_question, question = _is_question(content, match)
        role = "question" if is_question else "mentioned"
        person = by_name.get(name)
        if person is None:
            person = {"name": name, "role": role, "questions": []}
            by_name[name] = person
        elif ROLE_RANK[role] < ROLE_RANK[person["role"]]:
            person["role"] = role
        if question and question not in person["questions"]:
            person["questions"].append(question)
        for surface in (
            raw_spaced,
            raw_glued,
            f"{strip_honorific_ji(stem)}સ્વામી",
        ):
            if surface != name:
                surfaces[surface] = name

    people = []
    for person in by_name.values():
        item = {"name": person["name"], "role": person["role"]}
        if person["role"] == "question" and person["questions"]:
            item["questions"] = person["questions"]
        people.append(item)
    people.sort(key=lambda item: item["name"])
    return people, surfaces


def main() -> None:
    aliases, drop = load_overrides()
    global_map: dict[str, list[dict]] = defaultdict(list)
    surface_to_name: dict[str, str] = {}
    kirans_with = 0
    total = 0

    for part_num in range(1, 6):
        part_dir = BASE / f"part{part_num}"
        index_path = part_dir / "_kirans_.json"
        with index_path.open(encoding="utf-8") as f:
            index = json.load(f)

        people_map: dict[int, list[dict]] = {}
        for fname in sorted(os.listdir(part_dir)):
            if not (fname.startswith("kiran_") and fname.endswith(".json")):
                continue
            kiran_idx = int(fname[len("kiran_") : -len(".json")])
            with (part_dir / fname).open(encoding="utf-8") as f:
                kdata = json.load(f)
            people, surfaces = extract_kiran(kdata, aliases, drop)
            people_map[kiran_idx] = people
            for surface, name in surfaces.items():
                surface_to_name[surface] = name
            for person in people:
                glued = person["name"].replace(" ", "")
                if glued != person["name"]:
                    surface_to_name[glued] = person["name"]

        changed = 0
        for entry in index["list"]:
            people = people_map.get(entry["index"], [])
            if entry.get("swamis") != people:
                changed += 1
            entry["swamis"] = people
            total += 1
            if people:
                kirans_with += 1
                for person in people:
                    hit = {"index": entry["index"], "role": person["role"]}
                    if person.get("questions"):
                        hit["questions"] = list(person["questions"])
                    global_map[person["name"]].append(hit)

        with index_path.open("w", encoding="utf-8") as f:
            json.dump(index, f, ensure_ascii=False, indent=4)
            f.write("\n")

        with_question = sum(
            1
            for e in index["list"]
            if any(p.get("role") == "question" for p in (e.get("swamis") or []))
        )
        print(
            f"part{part_num}: {changed:3d} updated | "
            f"{sum(1 for e in index['list'] if e.get('swamis'))}/{len(index['list'])} "
            f"have names | {with_question} with question"
        )

    items = []
    for name in sorted(global_map.keys()):
        by_idx: dict[int, dict] = {}
        for hit in global_map[name]:
            idx = hit["index"]
            role = hit["role"]
            questions = list(hit.get("questions") or [])
            current = by_idx.get(idx)
            if current is None:
                by_idx[idx] = {"role": role, "questions": questions}
                continue
            if ROLE_RANK[role] < ROLE_RANK[current["role"]]:
                current["role"] = role
            for question in questions:
                if question not in current["questions"]:
                    current["questions"].append(question)
        kiran_list = []
        for idx in sorted(by_idx):
            item = {"index": idx, "role": by_idx[idx]["role"]}
            if by_idx[idx]["questions"]:
                item["questions"] = by_idx[idx]["questions"]
            kiran_list.append(item)
        items.append({"name": name, "count": len(kiran_list), "kirans": kiran_list})

    listed = {item["name"] for item in items}
    alias_out = {
        key: value
        for key, value in {**aliases, **surface_to_name}.items()
        if value in listed and key != value and key not in drop
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {"total": len(items), "aliases": alias_out, "list": items}
    OUTPUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=4) + "\n",
        encoding="utf-8",
    )

    print(f"\nKirans scanned    : {total}")
    print(f"Kirans with names : {kirans_with}")
    print(f"Unique swamis     : {len(items)}")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    print("\nName list:")
    for item in sorted(items, key=lambda row: (-row["count"], row["name"])):
        questions = sum(1 for k in item["kirans"] if k["role"] == "question")
        suffix = f"  questions={questions}" if questions else ""
        print(f"  {item['count']:4d}  {item['name']}{suffix}")


if __name__ == "__main__":
    main()
