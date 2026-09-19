import json
from pathlib import Path

import inject_haribhakt_names as h

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets" / "book" / "saxatsavita"
aliases, drop, never_host = h.load_overrides()
drop |= h.STOP_NAMES


def people_for(part: int, index: int) -> list[dict[str, str]]:
    path = BASE / f"part{part}" / f"kiran_{index}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    return h.extract_kiran(data, aliases, drop, never_host=never_host)


def role_of(people: list[dict[str, str]], name: str) -> str | None:
    for person in people:
        if person["name"] == name or person["name"].startswith(name):
            return person["role"]
    return None


def check(label: str, got, expected) -> None:
    if got != expected:
        raise SystemExit(f"FAIL {label}: {got!r} != {expected!r}")
    print(f"OK {label}: {got}")


check("kiran 652 jethabapa asks", role_of(people_for(5, 652), "જેઠાબાપા"), "question")
check("kiran 650 bachu not asker", role_of(people_for(5, 650), "બચુભાઈ"), None)
check("kiran 660 purushottam not asker", role_of(people_for(5, 660), "પુરુષોત્તમ"), None)
check("kiran 620 swami not listed as asker", role_of(people_for(5, 620), "સ્વામી"), None)
check("kiran 579 nanu asks", role_of(people_for(4, 579), "નાનુભાઈ"), "question")
check("kiran 541 kashidas asks", role_of(people_for(4, 541), "કાશીદાસ"), "question")
check("kiran 51 chaturbhuj not asker", role_of(people_for(1, 51), "ચતુર્ભુજ"), None)
check("kiran 513 lakshmi asks", role_of(people_for(4, 513), "લક્ષ્મીદાસ"), "question")


def questions_of(people, name):
    for person in people:
        if person["name"] == name or person["name"].startswith(name):
            return person.get("questions") or []
    return []


check(
    "kiran 652 question text",
    questions_of(people_for(5, 652), "જેઠાબાપા"),
    ["સંકલ્પ બંધ થતા નથી એનું કારણ શું ?"],
)
check(
    "kiran 541 question text",
    questions_of(people_for(4, 541), "કાશીદાસ"),
    ["ગૃહસ્થને ભગવાનના સ્વરૂપમાં મનની અખંડ વૃત્તિ કેમ રહે ?"],
)
check(
    "kiran 650 no question for bachu",
    questions_of(people_for(5, 650), "બચુભાઈ"),
    [],
)
print("all asker tests passed")
