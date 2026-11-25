#!/usr/bin/env python3
"""Build one calendar month of daily quiz packs from kiran morals.

Each day is five questions, one from each book part, grounded in that
kiran's moral. Distractors are other teachings, rejected when they
paraphrase the marked answer. Kirans already used on dated packs are
kept for later so a new month does not repeat them.

  python3 scripts/build_daily_quiz_month.py --month 2026-12
  python3 scripts/build_daily_quiz_month.py --month 2026-12 --force

Does nothing when that month folder already has every day, unless --force.
"""

from __future__ import annotations

import argparse
import calendar
import hashlib
import json
import re
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from kiran_quiz_bank import iter_kirans, kiran_meta  # noqa: E402
from local_kiran_quiz import _clauses, _clean, _clip, _split_heading  # noqa: E402
from quiz_option_distinctness import (  # noqa: E402
    option_set_is_distinct,
    options_too_similar,
)

QUIZ_DIR = SCRIPTS / "daily_quizzes"
ASKS = re.compile(r"(શું|કોણ|કોન|ક્યારે|ક્યાં|કેમ|કેવ|કય|\?)")
PROMPT_LIMIT = 58
TOPIC_LIMIT = 32
OPTION_MAX = 78
EXPLAIN_MAX = 230
DANGLING = {
    "અને", "પણ", "કે", "તો", "ને", "એટલે", "માટે", "વિના", "થી", "અથવા",
    "તથા", "તેમજ",
}
# Words that show up in almost every kiran, so they cannot be the only link
# between a question and its marked answer.
COMMON = {
    "ભગવાન", "સ્વરૂપ", "ભક્ત", "કલ્યાણ", "જ્ઞાન", "માયા", "ધર્મ", "સત્સંગ",
    "આત્મા", "મન", "વાત", "સુખ", "કરવા", "કરવાનું", "થવા", "થવાનું",
}
FRAMES = (
    " વિષે શું કહેવાયું?",
    " વિષે શું સિદ્ધાંત છે?",
    " મૂળ તત્ત્વ શું?",
    " અંગે શું નિર્ણય કરવો?",
    " — શું સમજવું?",
)
CONSONANTS = {
    "ક": "k", "ખ": "kh", "ગ": "g", "ઘ": "gh", "ઙ": "n",
    "ચ": "ch", "છ": "chh", "જ": "j", "ઝ": "jh", "ઞ": "n",
    "ટ": "t", "ઠ": "th", "ડ": "d", "ઢ": "dh", "ણ": "n",
    "ત": "t", "થ": "th", "દ": "d", "ધ": "dh", "ન": "n",
    "પ": "p", "ફ": "ph", "બ": "b", "ભ": "bh", "મ": "m",
    "ય": "y", "ર": "r", "લ": "l", "વ": "v", "ળ": "l",
    "શ": "sh", "ષ": "sh", "સ": "s", "હ": "h",
}


def _parse_month(value: str) -> tuple[int, int]:
    parts = value.split("-")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError("expected YYYY-MM")
    year, month = int(parts[0]), int(parts[1])
    if year < 1 or not 1 <= month <= 12:
        raise argparse.ArgumentTypeError("expected YYYY-MM")
    return year, month


def _used_kirans(skip_month: str | None = None) -> dict[tuple[int, int], str]:
    used: dict[tuple[int, int], str] = {}
    for path in sorted(QUIZ_DIR.glob("20*/*.json")):
        month = path.parent.name
        if skip_month and month == skip_month:
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        for question in payload.get("questions") or []:
            part = question.get("part")
            index = question.get("kiranIndex")
            if isinstance(part, int) and isinstance(index, int):
                used.setdefault((part, index), month)
    return used


def _used_prompts(skip_month: str | None = None) -> set[str]:
    prompts: set[str] = set()
    for path in QUIZ_DIR.glob("20*/*.json"):
        if skip_month and path.parent.name == skip_month:
            continue
        payload = json.loads(path.read_text(encoding="utf-8"))
        for question in payload.get("questions") or []:
            prompt = str(question.get("prompt") or "").strip()
            if prompt:
                prompts.add(prompt)
    return prompts


def _shorten(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    cut = text[:limit].rstrip()
    at = cut.rfind(" ")
    if at >= 8:
        cut = cut[:at]
    return re.sub(r"(નું|નો|ની|ના|ને|અને|તથા|તેમજ|છે)$", "", cut).strip(" ,.-")


def _topic(title: str) -> str:
    text = _clean(title)
    text = re.sub(r"\s*નું$", "", text).strip()
    for sep in (",", " અને ", " તથા ", " તેમજ ", " - ", " – ", " — "):
        if sep in text:
            head = text.split(sep, 1)[0].strip()
            if len(head) >= 8:
                text = head
                break
    text = re.sub(r"(નું|નો|ની|ના|ને)$", "", text).strip(" ,.-")
    return _shorten(text, TOPIC_LIMIT)


def _fit_prompt(topic: str, frame: str) -> str:
    prompt = topic + frame
    if len(prompt) <= PROMPT_LIMIT:
        return prompt
    room = PROMPT_LIMIT - len(frame)
    cut = topic[:room].rstrip()
    at = cut.rfind(" ")
    if at >= 8:
        cut = cut[:at]
    cut = re.sub(r"(નું|નો|ની|ના|ને|અને|તથા)$", "", cut).strip(" ,.-")
    return cut + frame


def _grams(text: str) -> set[str]:
    compact = re.sub(r"\s+", "", text)
    if len(compact) < 2:
        return set()
    return {compact[i : i + 2] for i in range(len(compact) - 1)}


def _tokens(text: str) -> set[str]:
    words = set()
    for raw in re.sub(r"[^\u0A80-\u0AFF]+", " ", text).split():
        word = re.sub(r"(નું|નો|ની|ના|ને|માં|થી|એ)$", "", raw)
        if len(word) >= 2:
            words.add(word)
    return words


def _grounded(clause: str, topic: str) -> bool:
    shared = _tokens(clause) & _tokens(topic)
    specific = {word for word in shared if word not in COMMON and len(word) >= 3}
    if specific:
        return True
    return len(shared) >= 2


def _score(clause: str, topic: str) -> float:
    if not _grounded(clause, topic):
        return 0
    left = _tokens(clause)
    right = _tokens(topic)
    token = len(left & right) / len(right) if right else 0
    topic_grams = _grams(topic)
    gram = len(topic_grams & _grams(clause)) / len(topic_grams) if topic_grams else 0
    length_bonus = 0.08 if 18 <= len(clause) <= 62 else 0
    return token * 0.65 + gram * 0.35 + length_bonus


def _usable_clause(clause: str) -> bool:
    words = clause.split()
    if not words or words[-1] in DANGLING or words[0] in DANGLING:
        return False
    if len(clause) < 16 or len(clause) > OPTION_MAX:
        return False
    return True


def _candidate_clauses(moral: str) -> list[str]:
    found = [item for item in _clauses(moral, 16, OPTION_MAX) if _usable_clause(item)]
    if found:
        return found
    clipped = _clip(moral, OPTION_MAX)
    return [clipped] if _usable_clause(clipped) else []


def _explanation(moral: str, correct: str) -> str:
    text = _clean(moral)
    if correct and correct not in text:
        text = f"{correct}. {text}".strip()
    if len(text) <= EXPLAIN_MAX and (not correct or correct in text):
        return text
    if correct and correct in text:
        at = text.find(correct)
        start = text.rfind(".", 0, at)
        start = 0 if start < 0 else start + 1
        window = text[start : start + EXPLAIN_MAX].strip(" .")
        if correct in window:
            return _clip(window, EXPLAIN_MAX) or correct
    return _clip(text, EXPLAIN_MAX) or correct


def _slug(text: str) -> str:
    parts: list[str] = []
    for word in text.split():
        letters: list[str] = []
        for char in word:
            mapped = CONSONANTS.get(char)
            if mapped:
                letters.append(mapped)
        if letters:
            parts.append("".join(letters))
        if len(parts) == 4:
            break
    slug = "-".join(parts)
    slug = re.sub(r"[^a-z0-9-]", "", slug)[:40].strip("-")
    return slug or "kiran"


def _pick_distractors(
    correct: str,
    same: list[str],
    others: list[str],
    blocked: set[str],
    salt: str,
) -> list[str]:
    chosen: list[str] = []

    def accept(item: str) -> bool:
        if item in blocked or item in chosen or item == correct:
            return False
        if options_too_similar(item, correct):
            return False
        if any(options_too_similar(item, prev) for prev in chosen):
            return False
        return True

    def take(pool: list[str], near: bool) -> None:
        if not pool or len(chosen) >= 3:
            return
        start = int(hashlib.sha1(salt.encode("utf-8")).hexdigest()[:8], 16)
        ordered = pool[start % len(pool) :] + pool[: start % len(pool)]
        if near:
            ordered = sorted(ordered, key=lambda item: abs(len(item) - len(correct)))
        for item in ordered:
            if len(chosen) >= 3:
                return
            if near and abs(len(item) - len(correct)) > 36:
                continue
            if accept(item):
                chosen.append(item)

    take(same, near=False)
    take(others, near=True)
    take(others, near=False)
    return chosen


def _load_sources() -> list[dict]:
    sources = []
    for part, index, path in iter_kirans():
        meta = kiran_meta(path)
        data = meta["data"]
        main = data.get("main") or {}
        extra = data.get("meta") or {}
        moral = _clean(extra.get("moral") or "")
        title = _clean(main.get("title") or "")
        summary = []
        pairs = []
        for item in extra.get("summary") or []:
            heading, body = _split_heading(item)
            body = _clip(body, OPTION_MAX)
            if _usable_clause(body):
                summary.append(body)
                pairs.append((_clean(heading), body))
        sources.append(
            {
                "part": part,
                "index": index,
                "title": title,
                "moral": moral,
                "clauses": _candidate_clauses(moral),
                "summary": summary,
                "pairs": pairs,
            }
        )
    return sources


def _giveaway(correct: str, topic: str, prompt: str) -> bool:
    if correct in prompt or prompt in correct:
        return True
    if len(topic) >= 12 and topic in correct:
        return True
    return options_too_similar(correct, topic) or options_too_similar(correct, prompt)


def _heading_in_body(heading: str, body: str) -> bool:
    if _grounded(body, heading):
        return True
    for token in _tokens(heading):
        if len(token) < 4:
            continue
        for other in _tokens(body):
            if other.startswith(token) or token.startswith(other) and len(other) >= 4:
                return True
    return False


def _candidates(source: dict, frame: str, used_prompts: set[str], used_topics: set[str]) -> list[tuple[str, str, str]]:
    found: list[tuple[str, str, str]] = []
    seen: set[str] = set()

    def add(topic: str, correct: str) -> None:
        if topic in used_topics or topic in seen or len(topic) < 4:
            return
        prompt = _fit_prompt(topic, frame)
        if prompt in used_prompts or not ASKS.search(prompt) or len(prompt.strip()) <= 8:
            return
        if not _usable_clause(correct) or _giveaway(correct, topic, prompt):
            return
        seen.add(topic)
        found.append((topic, prompt, correct))

    title_topic = _topic(source["title"])
    if len(title_topic) >= 6 and title_topic not in COMMON:
        for clause in source["clauses"]:
            if _score(clause, title_topic) < 0.2:
                continue
            add(title_topic, clause)
            break
    title_score = _topic(source["title"])
    ranked_pairs = sorted(
        source["pairs"],
        key=lambda pair: _score(pair[0], title_score) + _score(pair[1], title_score),
        reverse=True,
    )
    for heading, body in ranked_pairs:
        if heading in COMMON or heading == "સાર":
            continue
        if not _heading_in_body(heading, body):
            continue
        add(_shorten(heading, TOPIC_LIMIT), body)
    return found


def _compose(
    source: dict,
    pool: list[str],
    blocked: set[str],
    date_id: str,
    topic: str,
    prompt: str,
    correct: str,
) -> dict | None:
    same = [
        item
        for item in [*source["summary"], *source["clauses"]]
        if item != correct and not options_too_similar(item, correct)
    ]
    others = [item for item in pool if item not in same]
    distractors = _pick_distractors(
        correct,
        same,
        others,
        blocked,
        f"{date_id}-{source['part']}-{source['index']}",
    )
    if len(distractors) < 3:
        return None
    ordered = [correct, *distractors[:3]]
    shift = int(hashlib.sha1(f"{date_id}-{source['index']}".encode()).hexdigest()[:2], 16) % 4
    options = ordered[shift:] + ordered[:shift]
    if not option_set_is_distinct(options):
        return None
    if any(prompt in option or option in prompt for option in options):
        return None
    correct_index = options.index(correct)
    slug = _slug(topic)
    return {
        "id": f"dq-{date_id}-p{source['part']}-{source['index']}-{slug}",
        "prompt": prompt,
        "options": options,
        "correctIndex": correct_index,
        "explanation": _explanation(source["moral"], correct),
        "part": source["part"],
        "kiranIndex": source["index"],
        "_topic": topic,
        "_correct": correct,
    }


def _build_question(
    source: dict,
    pool: list[str],
    blocked: set[str],
    date_id: str,
    frame: str,
    used_prompts: set[str],
    used_topics: set[str],
) -> dict | None:
    best: tuple[float, dict] | None = None
    title = _topic(source["title"])
    for topic, prompt, correct in _candidates(source, frame, used_prompts, used_topics):
        question = _compose(source, pool, blocked, date_id, topic, prompt, correct)
        if question is None:
            continue
        rank = _score(correct, title) + _score(topic, title)
        if best is None or rank > best[0]:
            best = (rank, question)
    return None if best is None else best[1]


def _frames_for(source: dict) -> list[str]:
    start = int(hashlib.sha1(f"{source['part']}-{source['index']}".encode()).hexdigest()[:2], 16)
    ordered = [FRAMES[(start + offset) % len(FRAMES)] for offset in range(len(FRAMES))]
    topic = _topic(source["title"])
    if "તત્ત્વ" in topic:
        ordered = [frame for frame in ordered if frame != " મૂળ તત્ત્વ શું?"] + [" મૂળ તત્ત્વ શું?"]
    return ordered


def build_month(year: int, month: int, force: bool) -> int:
    days = calendar.monthrange(year, month)[1]
    folder = QUIZ_DIR / f"{year:04d}-{month:02d}"
    existing = list(folder.glob("*.json")) if folder.exists() else []
    if len(existing) >= days and not force:
        print(f"{folder.name} already has {len(existing)} day file(s); leaving them")
        return 0

    month_name = f"{year:04d}-{month:02d}"
    used = _used_kirans(month_name)
    used_prompts = _used_prompts(month_name)
    used_topics: set[str] = set()
    sources = _load_sources()
    pool = []
    for source in sources:
        pool.extend(source["clauses"])
        pool.extend(source["summary"])

    by_part: dict[int, list[dict]] = {part: [] for part in range(1, 6)}
    for source in sources:
        by_part[source["part"]].append(source)

    chosen: dict[int, list[dict]] = {}
    for part, group in by_part.items():
        def sort_key(item: dict, part: int = part) -> tuple:
            month_used = used.get((part, item["index"]))
            if month_used is None:
                rank = 0
            elif month_used < f"{year:04d}-{month:02d}":
                rank = 1
            else:
                rank = 2
            return (rank, item["index"])

        group = sorted(group, key=sort_key)
        built = []
        fresh = 0
        for source in group:
            question = None
            for frame in _frames_for(source):
                question = _build_question(
                    source, pool, set(), "probe", frame, used_prompts, used_topics
                )
                if question:
                    break
            if question:
                built.append((source, question))
                used_prompts.add(question["prompt"])
                used_topics.add(question["_topic"])
                if used.get((part, source["index"])) is None:
                    fresh += 1
            if len(built) == days:
                break
        print(f"  part {part}: {fresh} new kirans, {len(built) - fresh} earlier")
        if len(built) < days:
            print(
                f"part {part} produced {len(built)} questions, need {days}",
                file=sys.stderr,
            )
            return 1
        chosen[part] = built

    folder.mkdir(parents=True, exist_ok=True)
    for day in range(1, days + 1):
        date_id = f"{year:04d}-{month:02d}-{day:02d}"
        blocked: set[str] = set()
        questions = []
        for part in range(1, 6):
            source, probe = chosen[part][day - 1]
            question = _compose(
                source,
                pool,
                blocked,
                date_id,
                probe["_topic"],
                probe["prompt"],
                probe["_correct"],
            )
            if question is None:
                print(f"failed {date_id} part {part} kiran {source['index']}", file=sys.stderr)
                return 1
            blocked.add(probe["_correct"])
            questions.append(
                {key: value for key, value in question.items() if not key.startswith("_")}
            )
        payload = {"id": date_id, "questions": questions}
        path = folder / f"{day:02d}.json"
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    print(f"wrote {days} packs to {folder.relative_to(SCRIPTS.parent)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a month of daily quiz packs")
    parser.add_argument("--month", type=_parse_month, required=True)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    year, month = args.month
    return build_month(year, month, args.force)


if __name__ == "__main__":
    raise SystemExit(main())
