"""
Extract named haribhakts from kiran JSON and write them into indexes.

Writes:
  - haribhakts[] on each assets/book/saxatsavita/partN/_kirans_.json entry
  - assets/book/saxatsavita/haribhakts/haribhakts.json  (name → kirans)

Does not rewrite individual kiran_*.json files.

Run from the repo root:
    python3 scripts/inject_haribhakt_names.py
"""

from __future__ import annotations

import json
import os
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets" / "book" / "saxatsavita"
ALIASES_PATH = ROOT / "scripts" / "haribhakt_aliases.json"
OUTPUT = BASE / "haribhakts" / "haribhakts.json"

HOST_SUFFIXES = (
    "ના મકાનના",
    "નાં મકાનના",
    "ના મકાનમાં",
    "નાં મકાનમાં",
    "ના મકાન",
    "નાં મકાન",
    "નાં ઘરે",
    "ના ઘરે",
    "ને ઘરે",
    "ને ઘેર",
    "ને ત્યાં",
    "ના ત્યાં",
    "નાં ઘર",
)

# Two people in one host phrase: "X અને Yના ઘરે" or "Xને ત્યાંથી Yને ત્યાં"
CONJ_SPLIT_RE = re.compile(r"\s+(?:અને|તથા)\s+")
PLACE_SHIFT_RE = re.compile(r"(?:ને\s+)?ત્યાંથી\s+")

HTML_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"[\s\u00a0]+")
PREFIX_RE = re.compile(r"^(?:પ\.ભ\.|પભ\.|પ\.પૂ\.|પૂ\.|શ્રી|સંત)\s*")
GUJ_WORD_RE = re.compile(r"[\u0A80-\u0AFF.]+")
HONORIFIC_RE = re.compile(r"(ભાઈ|ભાઇ|બાપા|ભગત|બાઈ|બાઇ)")

READER_MARKERS = ("વાંચ્ય", "વાચ્ય", "બોલ્ય", "પ્રશ્ન પૂછ્ય", "વાંચતા")

STOP_NAMES = {
    "ભગવાન",
    "સ્વામિનારાયણ",
    "કણબી",
    "કડિયા",
    "સંત",
    "હરિભક્ત",
    "હરિભક્તો",
    "સંતો",
    "મંદિર",
    "ગામ",
    "સભા",
    "કોઈ",
    "કોઇ",
    "એક",
    "તે",
    "આ",
    "પોતાના",
    "પોતાને",
    "અમારા",
    "તમારા",
    "ભગવાનના",
    "દેવના",
    "સત્સંગી",
    "સાધુ",
    "મહારાજ",
    "ઠાકોરજી",
    "સ્વામી",
    "સ્વામીશ્રી",
    "શ્રીજી",
    "નારાયણ",
    "ગુરુ",
    "ગુરુકુળ",
    "ઓરડા",
    "મંડપ",
    "સભામંડપ",
    "ભાઈ",
    "ભાઇ",
    "બાપા",
    "બાઈ",
    "બાઇ",
    "ભગત",
    "આગેવાન",
    "આગેવાન ભાઇઓ",
    "આગેવાન ભાઈઓ",
}

STOP_TOKENS = STOP_NAMES | {
    "હરિભક્તને",
    "હરિભક્તનો",
    "હરિભક્તની",
    "હરિભક્તોને",
    "સંતહરિભક્તો",
    "સંતહરિભક્તોની",
    "હરિભક્તોની",
    "સંતોની",
}

VENUE_FRAGMENTS = (
    "સભામંડપ",
    "મંદિર",
    "ઢોલિયા",
    "ગુરુકુળ",
    "ઓસરી",
    "ઓરડા",
    "હાઉસીંગ",
    "મશીન ટુલ્સ",
    "વાસ્તુ",
    "બોર્ડ",
)

AFTER_NAME_STOP = (
    "વચનામૃત",
    "કિરણ",
    "પ્રકરણ",
    "ભક્તચિંતામણિ",
    "ભક્તચિંતામણી",
    "કથા",
    "મૂર્તિ",
    "લોયા",
    "ઠાકોરજી",
    "સાક્ષાત્",
    "પુરુષોત્તમપ્રકાશ",
    "સારાંશ",
    "શિક્ષણ",
    "મધ્ય",
    "છેલ્લા",
    "છેલ્લાં",
    "છેલ્લાનું",
    "જન્મ",
    "લ્યે",
    "લ્યો",
    "પતિ",
    "સતિ",
)

ROLE_RANK = {"host": 0, "reader": 1}


def load_overrides() -> tuple[dict[str, str], set[str]]:
    if not ALIASES_PATH.exists():
        return {}, set()
    data = json.loads(ALIASES_PATH.read_text(encoding="utf-8"))
    aliases = {str(k).strip(): str(v).strip() for k, v in (data.get("aliases") or {}).items()}
    drop = {str(x).strip() for x in (data.get("drop") or []) if str(x).strip()}
    return aliases, drop


def strip_html(s: str) -> str:
    s = HTML_RE.sub(" ", s)
    s = s.replace("&nbsp;", " ").replace("&amp;", "&")
    return WS_RE.sub(" ", s).strip()


CLAUSE_SPLIT_RE = re.compile(r"[.।!?]|પછી|મધ્યે")
FILLER_TOKENS = {
    "પછી",
    "છે",
    "હતી",
    "હતા",
    "હતો",
    "હતાં",
    "કરી",
    "કરીને",
    "વાત",
    "પધાર્યા",
    "પધાર્યાં",
    "પધાર્યો",
    "આપીને",
    "બપોર",
    "મધ્યે",
    "નથી",
    "રહ્યું",
    "થાળ",
    "કરવા",
    "વિરાજમાન",
    "આશીર્વાદ",
    "એટલા",
    "એટલી",
    "ગામ",
    "શ્રી",
    "તે",
    "જ",
    "દિવસે",
    "દિવસ",
    "ને",
    "અને",
    "તથા",
    "પણ",
    "જેમ",
    "તેમ",
    "બેસીને",
    "ચાલ્યા",
    "ચાલ્યાં",
    "જન્મ",
    "લ્યે",
    "લ્યો",
    "ઘરે",
    "ઘેર",
    "ત્યાંથી",
}


AGENTIVE_RE = re.compile(r"(ભાઈ|ભાઇ|બાપા|ભગત|બાઈ|બાઇ)(?:એણે|એ|ે)$")


def strip_agentive(token: str) -> str:
    token = AGENTIVE_RE.sub(r"\1", token)
    token = re.sub(r"(?:એણે|એ)$", "", token)
    return token


def clean_name(raw: str) -> str:
    s = WS_RE.sub(" ", raw).strip(" ,।.|-–—")
    s = PREFIX_RE.sub("", s).strip()
    tokens = [strip_agentive(t) for t in s.split() if t]
    s = " ".join(tokens)
    s = re.sub(r"(?:ની|ના|નાં|નો|ને|માં|થી)$", "", s).strip()
    s = re.sub(r"^(?:પછી|ને|તથા|અને|પૂ|શ્રી)\s+", "", s).strip()
    return s


def looks_like_person(name: str, require_honorific: bool = False) -> bool:
    if not name or len(name) < 3:
        return False
    if "." in name or "।" in name or "પછી" in name:
        return False
    if name in STOP_NAMES or name in STOP_TOKENS:
        return False
    if any(v in name for v in VENUE_FRAGMENTS):
        return False
    if any(p in name for p in AFTER_NAME_STOP):
        return False
    tokens = name.split()
    if not tokens or len(tokens) > 5 or len(name) > 40:
        return False
    if any(t in STOP_TOKENS or t in FILLER_TOKENS for t in tokens):
        return False
    if not re.search(r"[\u0A80-\u0AFF]", name):
        return False
    if name.endswith("સ્વામી") or "સ્વામી" in name:
        return False
    if require_honorific and not HONORIFIC_RE.search(name):
        return False
    return True


def apply_alias(name: str, aliases: dict[str, str]) -> str:
    if name in aliases:
        return aliases[name]
    return name


def _letter_before(text: str, idx: int) -> bool:
    return idx > 0 and "\u0A80" <= text[idx - 1] <= "\u0AFF"


def _suffix_boundary(text: str, idx: int, suffix: str) -> bool:
    """Reject a suffix that is only a prefix of a longer host/place phrase.

    Stops `ને ત્યાં` matching inside `ને ત્યાંથી`, and `ના મકાન`
    matching inside `ના મકાનમાં`. A trailing matra such as `ે` on `ઘેરે`
    is still a valid match.
    """
    end = idx + len(suffix)
    if end >= len(text):
        return True
    rest = text[end:]
    if suffix.endswith("ત્યાં") and rest.startswith("થી"):
        return False
    if suffix.endswith("મકાન") and rest.startswith("માં"):
        return False
    if suffix.endswith("મકાન") and rest.startswith("ના"):
        return False
    return True


def _host_chunks(text: str) -> list[str]:
    chunks: list[str] = []
    for shifted in PLACE_SHIFT_RE.split(text):
        chunks.extend(CONJ_SPLIT_RE.split(shifted))
    return [c.strip() for c in chunks if c.strip()]


def _host_from_chunk(chunk: str, allow_bare: bool = False) -> str | None:
    for suffix in HOST_SUFFIXES:
        idx = chunk.find(suffix)
        if idx > 0 and _letter_before(chunk, idx) and _suffix_boundary(chunk, idx, suffix):
            name = clean_name(chunk[:idx])
            if looks_like_person(name):
                return name
    # Bare names only after splitting "X અને Y" / "Xને ત્યાંથી Y"
    if allow_bare:
        name = clean_name(chunk)
        if looks_like_person(name, require_honorific=True):
            return name
    return None


def hosts_from_phrase(phrase: str) -> list[str]:
    head = phrase.split(",")[0].strip()
    if not head:
        return []
    chunks = _host_chunks(head)
    allow_bare = len(chunks) > 1
    out: list[str] = []
    seen: set[str] = set()
    for chunk in chunks:
        name = _host_from_chunk(chunk, allow_bare=allow_bare)
        if name and name not in seen:
            seen.add(name)
            out.append(name)
    return out


def hosts_from_locations(locations: list) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for loc in locations:
        for name in hosts_from_phrase(str(loc)):
            if name not in seen:
                seen.add(name)
                out.append(name)
    return out


def _last_clause(window: str) -> str:
    parts = CLAUSE_SPLIT_RE.split(window)
    return parts[-1].strip() if parts else window


def _given_name_token(token: str) -> bool:
    t = strip_agentive(token)
    return bool(
        HONORIFIC_RE.search(t)
        or t.endswith("જી")
        or t.endswith("લાલ")
        or t.endswith("શી")
        or t.endswith("દાસ")
    )


def name_from_host_window(window: str) -> str | None:
    """Name immediately before a host suffix (last honorific cluster).

    Taking every token after the *first* honorific concatenated two people
    in one location/sentence (e.g. X અને Yના ઘરે, Xને ત્યાંથી Yને ત્યાં).
    """
    tokens = [
        t
        for t in GUJ_WORD_RE.findall(window)
        if t not in FILLER_TOKENS and t not in STOP_TOKENS
    ]
    if not tokens:
        return None
    honor_idxs = [i for i, t in enumerate(tokens) if HONORIFIC_RE.search(t)]
    if not honor_idxs:
        return None
    i = honor_idxs[-1]
    begin = i
    if i > 0 and _given_name_token(tokens[i - 1]):
        begin = i - 1
    end = i + 1
    while end < len(tokens):
        nxt = tokens[end]
        if HONORIFIC_RE.search(nxt) or _given_name_token(nxt):
            break
        if nxt in FILLER_TOKENS or nxt in STOP_TOKENS or not _after_ok(nxt):
            break
        end += 1
    name = clean_name(" ".join(tokens[begin:end]))
    if looks_like_person(name, require_honorific=True):
        return name
    return None


def names_from_host_window(window: str) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for chunk in _host_chunks(window):
        name = name_from_host_window(chunk)
        if name and name not in seen:
            seen.add(name)
            out.append(name)
    return out


def hosts_from_text(text: str) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for suffix in HOST_SUFFIXES:
        start = 0
        while True:
            idx = text.find(suffix, start)
            if idx < 0:
                break
            if _letter_before(text, idx) and _suffix_boundary(text, idx, suffix):
                window = _last_clause(text[max(0, idx - 50) : idx])
                for name in names_from_host_window(window):
                    if name not in seen:
                        seen.add(name)
                        out.append(name)
            start = idx + len(suffix)
    return out


def _after_ok(token: str) -> bool:
    return not any(token.startswith(p) or p in token for p in AFTER_NAME_STOP)


def readers_from_text(text: str) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for marker in READER_MARKERS:
        start = 0
        while True:
            idx = text.find(marker, start)
            if idx < 0:
                break
            window = _last_clause(text[max(0, idx - 60) : idx])
            window = re.sub(r"(?:એણે|એ)\s*$", "", window).strip()
            tokens = [
                t
                for t in GUJ_WORD_RE.findall(window)
                if t not in FILLER_TOKENS
            ]
            honor_idx = None
            for i, tok in enumerate(tokens):
                if HONORIFIC_RE.search(tok):
                    honor_idx = i
            if honor_idx is not None:
                begin = honor_idx
                if honor_idx > 0 and _given_name_token(tokens[honor_idx - 1]):
                    begin = honor_idx - 1
                end = honor_idx + 1
                nxt = tokens[honor_idx + 1] if honor_idx + 1 < len(tokens) else ""
                if nxt and _after_ok(nxt) and nxt not in FILLER_TOKENS:
                    end = honor_idx + 2
                name = clean_name(" ".join(tokens[begin:end]))
                if looks_like_person(name, require_honorific=True) and name not in seen:
                    seen.add(name)
                    out.append(name)
            start = idx + len(marker)
    return out


def collapse_shorter_names(people: list[dict[str, str]]) -> list[dict[str, str]]:
    names = [p["name"] for p in people]
    keep: list[dict[str, str]] = []
    for person in people:
        name = person["name"]
        if any(other != name and other.startswith(name + " ") for other in names):
            continue
        if any(other != name and other.endswith(" " + name) for other in names):
            continue
        keep.append(person)
    return keep


def merge_people(
    hosts: list[str], readers: list[str], aliases: dict[str, str], drop: set[str]
) -> list[dict[str, str]]:
    by_name: dict[str, str] = {}
    order: list[str] = []
    for role, names in (("host", hosts), ("reader", readers)):
        for raw in names:
            name = apply_alias(clean_name(raw), aliases)
            if not name or name in drop or not looks_like_person(name):
                continue
            if name not in by_name:
                by_name[name] = role
                order.append(name)
            elif ROLE_RANK[role] < ROLE_RANK[by_name[name]]:
                by_name[name] = role
    return collapse_shorter_names([{"name": n, "role": by_name[n]} for n in order])


def extract_kiran(kdata: dict, aliases: dict[str, str], drop: set[str]) -> list[dict[str, str]]:
    meta = kdata.get("meta") or {}
    main = kdata.get("main") or {}
    content = strip_html(str(main.get("content") or ""))
    hosts = hosts_from_locations(meta.get("locations") or [])
    hosts.extend(hosts_from_text(content))
    readers = readers_from_text(content)
    return merge_people(hosts, readers, aliases, drop)


def main() -> None:
    aliases, drop = load_overrides()
    drop |= STOP_NAMES
    global_map: dict[str, list[dict]] = defaultdict(list)
    kirans_with = 0
    total = 0

    for part_num in range(1, 6):
        part_dir = BASE / f"part{part_num}"
        index_path = part_dir / "_kirans_.json"
        with index_path.open(encoding="utf-8") as f:
            index = json.load(f)

        people_map: dict[int, list[dict[str, str]]] = {}
        for fname in sorted(os.listdir(part_dir)):
            if not (fname.startswith("kiran_") and fname.endswith(".json")):
                continue
            kiran_idx = int(fname[len("kiran_") : -len(".json")])
            with (part_dir / fname).open(encoding="utf-8") as f:
                kdata = json.load(f)
            people_map[kiran_idx] = extract_kiran(kdata, aliases, drop)

        changed = 0
        for entry in index["list"]:
            people = people_map.get(entry["index"], [])
            if entry.get("haribhakts") != people:
                entry["haribhakts"] = people
                changed += 1
            else:
                entry["haribhakts"] = people
            total += 1
            if people:
                kirans_with += 1
                for person in people:
                    global_map[person["name"]].append(
                        {"index": entry["index"], "role": person["role"]}
                    )

        with index_path.open("w", encoding="utf-8") as f:
            json.dump(index, f, ensure_ascii=False, indent=4)
            f.write("\n")

        with_host = sum(
            1
            for e in index["list"]
            if any(p.get("role") == "host" for p in (e.get("haribhakts") or []))
        )
        print(
            f"part{part_num}: {changed:3d} updated | "
            f"{sum(1 for e in index['list'] if e.get('haribhakts'))}/{len(index['list'])} "
            f"have names | {with_host} with host"
        )

    items = []
    for name in sorted(global_map.keys()):
        kirans = global_map[name]
        # unique by index, keep best role
        by_idx: dict[int, str] = {}
        for hit in kirans:
            idx = hit["index"]
            role = hit["role"]
            if idx not in by_idx or ROLE_RANK[role] < ROLE_RANK[by_idx[idx]]:
                by_idx[idx] = role
        kiran_list = [{"index": i, "role": by_idx[i]} for i in sorted(by_idx)]
        items.append({"name": name, "count": len(kiran_list), "kirans": kiran_list})

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {"total": len(items), "list": items}
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

    print(f"\nKirans scanned     : {total}")
    print(f"Kirans with names  : {kirans_with}")
    print(f"Unique haribhakts  : {len(items)}")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
