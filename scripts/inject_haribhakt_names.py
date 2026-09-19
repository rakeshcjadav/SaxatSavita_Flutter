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
    "ની વાડીમાં",
    "નાં વાડીમાં",
    "ની વાડીએ",
    "નાં વાડીએ",
    "ના વાડીએ",
    "ની વાડી",
    "નાં વાડી",
    "ના વાડી",
    "ની ઘેરે",
    "નાં ઘેરે",
    "ની ઘેર",
    "નાં ઘેર",
    "નાં ઘરે",
    "ના ઘરે",
    "ને ઘરે",
    "ની ઘરે",
    "ને ઘેર",
    "ને ત્યાં",
    "ના ત્યાં",
    "નાં ઘર",
)

# People named in a teaching, not sitting as host/reader.
MENTION_SUFFIXES = (
    "ની વાત વિસ્તારથી કરી",
    "ની વાત કરી",
    "ની પેઠે",
)

# Two people in one host phrase: "X અને Yના ઘરે" or "Xને ત્યાંથી Yને ત્યાં"
CONJ_SPLIT_RE = re.compile(r"\s+(?:અને|તથા)\s+")
PLACE_SHIFT_RE = re.compile(r"(?:ને\s+)?ત્યાંથી\s+")

HTML_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"[\s\u00a0]+")
PREFIX_RE = re.compile(r"^(?:પ\.ભ\.|પભ\.|પ\.પૂ\.|પૂ\.|પ્રી\.|પ્રિ\.|શ્રી|સંત)\s*")
GUJ_WORD_RE = re.compile(r"[\u0A80-\u0AFF.]+")
HONORIFIC_RE = re.compile(r"(ભાઈ|ભાઇ|બાપા|ભગત|બાઈ|બાઇ)")
TITLE_TOKENS = {"મહારાજ"}

READER_MARKERS = ("વાંચ્ય", "વાચ્ય", "બોલ્ય", "વાંચતા")
QUESTION_MARKERS = ("પ્રશ્ન પૂછ્ય", "પ્રશ્ન પુછ્ય", "પ્રશ્નો પૂછ્ય")

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
    "પડશાળા",
    "વાડી",
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

ROLE_RANK = {"host": 0, "reader": 1, "question": 2, "mentioned": 3}


def load_overrides() -> tuple[dict[str, str], set[str], set[str]]:
    if not ALIASES_PATH.exists():
        return {}, set(), set()
    data = json.loads(ALIASES_PATH.read_text(encoding="utf-8"))
    aliases = {str(k).strip(): str(v).strip() for k, v in (data.get("aliases") or {}).items()}
    drop = {str(x).strip() for x in (data.get("drop") or []) if str(x).strip()}
    never_host = {
        str(x).strip().replace("ભાઇ", "ભાઈ").replace("બાઇ", "બાઈ")
        for x in (data.get("never_host") or [])
        if str(x).strip()
    }
    return aliases, drop, never_host


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
    "ઉપર",
    "પાસે",
    "રસ્તામાં",
    "આગળ",
    "હોય",
    "ત્યાં",
    "સાથે",
    "પત્ર",
    "ખાતો",
    "મેળાવીને",
    "સંતમંડળ",
    "થઈ",
    "જે",
    "મારાં",
    "મારા",
    "શું",
    "હેત",
    "પછે",
    "દર્શન",
    "એમ",
}


AGENTIVE_RE = re.compile(r"(ભાઈ|ભાઇ|બાપા|ભગત|બાઈ|બાઇ)(?:એણે|એ|ે)$")


def strip_agentive(token: str) -> str:
    token = AGENTIVE_RE.sub(r"\1", token)
    token = re.sub(r"(?:એણે|એ)$", "", token)
    token = re.sub(r"(દાસ|ઠક્કર)ે$", r"\1", token)
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
    if any(not _is_gujarati_letter_start(t) for t in tokens):
        return False
    body = tokens[:-1] if len(tokens) > 1 and tokens[-1] in TITLE_TOKENS else tokens
    if any(t in STOP_TOKENS or t in FILLER_TOKENS for t in body):
        return False
    if not re.search(r"[\u0A80-\u0AFF]", name):
        return False
    if name.endswith("સ્વામી") or "સ્વામી" in name:
        return False
    if tokens[0] in STOP_NAMES:
        return False
    if require_honorific and not HONORIFIC_RE.search(name):
        return False
    return True


def apply_alias(name: str, aliases: dict[str, str]) -> str:
    if name in aliases:
        return aliases[name]
    return name


def normalize_honorific_spelling(name: str) -> str:
    return name.replace("ભાઇ", "ભાઈ").replace("બાઇ", "બાઈ")


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
    if suffix.endswith("વાડી") and rest.startswith(("એ", "માં")):
        return False
    if suffix.endswith("ઘેર") and rest.startswith("ે"):
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
        or t.endswith("દાસ")
    )


def _has_person_marker(name: str) -> bool:
    return bool(
        HONORIFIC_RE.search(name)
        or any(_given_name_token(t) for t in name.split())
    )


VERBISH_ENDINGS = ("તો", "તા", "તી", "તું", "તાં", "યો", "યા", "યું")


def _is_gujarati_letter_start(token: str) -> bool:
    return bool(token) and 0x0A85 <= ord(token[0]) <= 0x0AB9


def _leading_name_token(token: str) -> bool:
    """Given name or surname that may sit before an honorific/જી token."""
    t = strip_agentive(token)
    if t in FILLER_TOKENS or t in STOP_TOKENS:
        return False
    if HONORIFIC_RE.search(t):
        return False
    if not _is_gujarati_letter_start(t):
        return False
    if t.endswith(("માં", "માંથી", "થી", "ને", "ના", "ની", "નો", "નાં")):
        return False
    if t.endswith(VERBISH_ENDINGS):
        return False
    if any(p in t for p in AFTER_NAME_STOP):
        return False
    if not re.fullmatch(r"[\u0A80-\u0AFF]+", t):
        return False
    return len(t) >= 3


def name_from_host_window(window: str) -> str | None:
    """Name immediately before a host/mention suffix (last person cluster).

    Taking every token after the *first* honorific concatenated two people
    in one location/sentence (e.g. X અને Yના ઘરે, Xને ત્યાંથી Yને ત્યાં).
    """
    tokens = [
        t
        for t in GUJ_WORD_RE.findall(window)
        if t not in FILLER_TOKENS
        and (t in TITLE_TOKENS or t not in STOP_TOKENS)
        and _is_gujarati_letter_start(t)
        and not re.search(r"[\u0AE6-\u0AEF0-9]", t)
    ]
    if not tokens:
        return None
    anchors = [
        i
        for i, t in enumerate(tokens)
        if HONORIFIC_RE.search(t) or _given_name_token(t)
    ]
    if not anchors:
        return None
    i = anchors[-1]
    begin = i
    extra = 0
    while begin > 0 and extra < 1 and _leading_name_token(tokens[begin - 1]):
        begin -= 1
        extra += 1
    end = i + 1
    while end < len(tokens):
        nxt = tokens[end]
        if nxt in TITLE_TOKENS:
            end += 1
            break
        if HONORIFIC_RE.search(nxt) or _given_name_token(nxt):
            break
        if nxt in FILLER_TOKENS or nxt in STOP_TOKENS or not _after_ok(nxt):
            break
        if not _leading_name_token(nxt):
            break
        end += 1
    name = clean_name(" ".join(tokens[begin:end]))
    if looks_like_person(name) and _has_person_marker(name):
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


def _clause_window(text: str, idx: int, chars: int) -> str:
    start = max(0, idx - chars)
    if start > 0:
        while start < idx and not text[start].isspace():
            start += 1
        while start < idx and text[start].isspace():
            start += 1
    return _last_clause(text[start:idx])


def _names_before_suffixes(text: str, suffixes: tuple[str, ...], window_chars: int = 50) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for suffix in suffixes:
        start = 0
        while True:
            idx = text.find(suffix, start)
            if idx < 0:
                break
            if _letter_before(text, idx) and _suffix_boundary(text, idx, suffix):
                window = _clause_window(text, idx, window_chars)
                for name in names_from_host_window(window):
                    if name not in seen:
                        seen.add(name)
                        out.append(name)
            start = idx + len(suffix)
    return out


def hosts_from_text(text: str) -> list[str]:
    return _names_before_suffixes(text, HOST_SUFFIXES)


def mentions_from_text(text: str) -> list[str]:
    return _names_before_suffixes(text, MENTION_SUFFIXES, window_chars=60)


def _after_ok(token: str) -> bool:
    if re.search(r"[\u0AE6-\u0AEF0-9]", token):
        return False
    return not any(token.startswith(p) or p in token for p in AFTER_NAME_STOP)


def _stem_case(token: str) -> str:
    t = strip_agentive(token)
    if t.endswith("ને"):
        return t[:-2]
    if t.endswith("ે"):
        return t[:-1]
    return t


def _is_dative_token(token: str) -> bool:
    return token.endswith("ને")


def _is_agentive_token(token: str) -> bool:
    if _is_dative_token(token):
        return False
    if token.endswith("એણે") or token.endswith("એ"):
        return True
    stem = _stem_case(token)
    if token.endswith("ે") and (
        HONORIFIC_RE.search(token) or _given_name_token(stem)
    ):
        return True
    return False


def _name_cluster_at(tokens: list[str], idx: int) -> str | None:
    begin = idx
    if idx > 0 and _given_name_token(_stem_case(tokens[idx - 1])):
        begin = idx - 1
    end = idx + 1
    nxt = tokens[idx + 1] if idx + 1 < len(tokens) else ""
    if (
        nxt
        and _after_ok(nxt)
        and nxt not in FILLER_TOKENS
        and _given_name_token(_stem_case(nxt))
    ):
        end = idx + 2
    name = clean_name(" ".join(tokens[begin:end]))
    if looks_like_person(name, require_honorific=True):
        return name
    if looks_like_person(name) and _has_person_marker(name):
        return name
    return None


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


QUESTION_LEAD_RE = re.compile(r"^(?:ો|ું|ા)*\s*(?:જે|કે)\s*[;:,]?\s*")
QUESTION_STOP_RE = re.compile(r"\s+(?:પછી|તેનો ઉત્તર|તેનો જવાબ)")


def _question_text_after(text: str, after: int) -> str:
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


def questions_from_text(text: str) -> list[tuple[str, str]]:
    """(asker, question) for Xએ પ્રશ્ન પૂછ્યો, not Xને."""
    out: list[tuple[str, str]] = []
    for marker in QUESTION_MARKERS:
        start = 0
        while True:
            idx = text.find(marker, start)
            if idx < 0:
                break
            window = _last_clause(text[max(0, idx - 80) : idx])
            tokens = [
                t
                for t in GUJ_WORD_RE.findall(window)
                if t not in FILLER_TOKENS
            ]
            honor_idx = None
            for i, tok in enumerate(tokens):
                stem = _stem_case(tok)
                if not _is_agentive_token(tok):
                    continue
                if HONORIFIC_RE.search(tok) or _given_name_token(stem):
                    honor_idx = i
            if honor_idx is not None:
                name = _name_cluster_at(tokens, honor_idx)
                question = _question_text_after(text, idx + len(marker))
                if name and question:
                    out.append((name, question))
            start = idx + len(marker)
    return out


def askers_from_text(text: str) -> list[str]:
    """People who asked a question (Xએ પ્રશ્ન પૂછ્યો), not those asked (Xને)."""
    out: list[str] = []
    seen: set[str] = set()
    for name, _question in questions_from_text(text):
        if name not in seen:
            seen.add(name)
            out.append(name)
    return out


def _extend_questions(person: dict, extras: list[str]) -> None:
    if not extras:
        return
    questions = list(person.get("questions") or [])
    for question in extras:
        if question and question not in questions:
            questions.append(question)
    if questions:
        person["questions"] = questions


def collapse_shorter_names(people: list[dict]) -> list[dict]:
    names = [p["name"] for p in people]
    keep: list[dict] = []
    moved: dict[str, list[str]] = defaultdict(list)
    for person in people:
        name = person["name"]
        longer = next(
            (
                other
                for other in names
                if other != name
                and (other.startswith(name + " ") or other.endswith(" " + name))
            ),
            None,
        )
        if longer:
            moved[longer].extend(person.get("questions") or [])
            continue
        keep.append(person)
    for person in keep:
        _extend_questions(person, moved.get(person["name"], []))
    return keep


def merge_people(
    hosts: list[str],
    readers: list[str],
    aliases: dict[str, str],
    drop: set[str],
    mentions: list[str] | None = None,
    askers: list[str] | None = None,
    never_host: set[str] | None = None,
) -> list[dict[str, str]]:
    skip_host = never_host or set()
    by_name: dict[str, str] = {}
    order: list[str] = []
    for role, names in (
        ("host", hosts),
        ("reader", readers),
        ("question", askers or []),
        ("mentioned", mentions or []),
    ):
        for raw in names:
            name = normalize_honorific_spelling(apply_alias(clean_name(raw), aliases))
            name = apply_alias(name, aliases)
            if not name or name in drop or not looks_like_person(name):
                continue
            assigned = "mentioned" if name in skip_host and role == "host" else role
            if name not in by_name:
                by_name[name] = assigned
                order.append(name)
            elif ROLE_RANK[assigned] < ROLE_RANK[by_name[name]]:
                by_name[name] = assigned
    return collapse_shorter_names([{"name": n, "role": by_name[n]} for n in order])


def extract_kiran(
    kdata: dict,
    aliases: dict[str, str],
    drop: set[str],
    never_host: set[str] | None = None,
) -> list[dict]:
    meta = kdata.get("meta") or {}
    main = kdata.get("main") or {}
    content = strip_html(str(main.get("content") or ""))
    hosts = hosts_from_locations(meta.get("locations") or [])
    hosts.extend(hosts_from_text(content))
    readers = readers_from_text(content)
    asked = questions_from_text(content)
    askers = [name for name, _question in asked]
    mentions = mentions_from_text(content)
    people = merge_people(
        hosts,
        readers,
        aliases,
        drop,
        mentions=mentions,
        askers=askers,
        never_host=never_host,
    )
    questions_by_name: dict[str, list[str]] = defaultdict(list)
    for raw, question in asked:
        name = normalize_honorific_spelling(apply_alias(clean_name(raw), aliases))
        name = apply_alias(name, aliases)
        if name and question and question not in questions_by_name[name]:
            questions_by_name[name].append(question)
    for person in people:
        extras = list(questions_by_name.get(person["name"], []))
        if not extras:
            for key, values in questions_by_name.items():
                if person["name"].startswith(key) or key.startswith(person["name"]):
                    extras = values
                    break
        _extend_questions(person, extras)
    return people


def main() -> None:
    aliases, drop, never_host = load_overrides()
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
            people_map[kiran_idx] = extract_kiran(
                kdata, aliases, drop, never_host=never_host
            )

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
                    hit = {"index": entry["index"], "role": person["role"]}
                    if person.get("questions"):
                        hit["questions"] = list(person["questions"])
                    global_map[person["name"]].append(hit)

        with index_path.open("w", encoding="utf-8") as f:
            json.dump(index, f, ensure_ascii=False, indent=4)
            f.write("\n")

        with_host = sum(
            1
            for e in index["list"]
            if any(p.get("role") == "host" for p in (e.get("haribhakts") or []))
        )
        with_mentioned = sum(
            1
            for e in index["list"]
            if any(p.get("role") == "mentioned" for p in (e.get("haribhakts") or []))
        )
        with_question = sum(
            1
            for e in index["list"]
            if any(p.get("role") == "question" for p in (e.get("haribhakts") or []))
        )
        print(
            f"part{part_num}: {changed:3d} updated | "
            f"{sum(1 for e in index['list'] if e.get('haribhakts'))}/{len(index['list'])} "
            f"have names | {with_host} with host | {with_question} with question | "
            f"{with_mentioned} with mention"
        )

    items = []
    for name in sorted(global_map.keys()):
        kirans = global_map[name]
        # unique by index, keep best role and any asked questions
        by_idx: dict[int, dict] = {}
        for hit in kirans:
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
        key: normalize_honorific_spelling(value)
        for key, value in aliases.items()
        if normalize_honorific_spelling(value) in listed
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    payload = {"total": len(items), "aliases": alias_out, "list": items}
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

    print(f"\nKirans scanned     : {total}")
    print(f"Kirans with names  : {kirans_with}")
    print(f"Unique haribhakts  : {len(items)}")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
