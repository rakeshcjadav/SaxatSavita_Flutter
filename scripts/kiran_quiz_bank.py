#!/usr/bin/env python3
"""Shared kiran quiz bank helpers: targets, sources, and expected docs."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIRAN_ROOT = ROOT / "assets/book/saxatsavita"
HARIBHAKT_PATH = KIRAN_ROOT / "haribhakts/haribhakts.json"
OUT_DIR = ROOT / "scripts/quiz_output"

CHUNK_SIZE = 10


def target_question_count(word_count: int, recorded_question_count: int = 0) -> int:
    if word_count < 150:
        count = 5
    elif word_count < 250:
        count = 10
    elif word_count < 500:
        count = 15
    elif word_count < 900:
        count = 20
    elif word_count < 1400:
        count = 28
    else:
        count = 35
    count += min(max(recorded_question_count, 0), 5)
    return max(3, min(35, count))


def strip_html(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def normalize_gu(text: str) -> str:
    text = strip_html(text).replace("\u00a0", " ")
    text = re.sub(r"[\s,.;:!?\"'“”‘’()\[\]{}।૦-૯0-9\-–—]+", "", text)
    return text


def iter_kirans(part: int | None = None, index: int | None = None, limit: int | None = None):
    parts = [part] if part else range(1, 6)
    count = 0
    for part_no in parts:
        folder = KIRAN_ROOT / f"part{part_no}"
        files = sorted(
            folder.glob("kiran_*.json"),
            key=lambda path: int(path.stem.split("_")[1]),
        )
        for path in files:
            kiran_index = int(path.stem.split("_")[1])
            if index is not None and kiran_index != index:
                continue
            yield part_no, kiran_index, path
            count += 1
            if limit is not None and count >= limit:
                return


def load_haribhakt_index() -> dict[int, dict]:
    payload = json.loads(HARIBHAKT_PATH.read_text(encoding="utf-8"))
    by_kiran: dict[int, dict] = {}
    for person in payload.get("list") or []:
        name = (person.get("name") or "").strip()
        for ref in person.get("kirans") or []:
            kiran_index = ref.get("index")
            if not kiran_index:
                continue
            entry = by_kiran.setdefault(
                int(kiran_index),
                {"hosts": [], "readers": [], "mentioned": [], "questions": []},
            )
            role = (ref.get("role") or "").strip()
            if role == "host" and name:
                entry["hosts"].append(name)
            elif role == "reader" and name:
                entry["readers"].append(name)
            elif role == "mentioned" and name:
                entry["mentioned"].append(name)
            for question in ref.get("questions") or []:
                text = str(question).strip()
                if text:
                    entry["questions"].append({"askers": name, "text": text})
    return by_kiran


def kiran_meta(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    main = data.get("main") or {}
    return {
        "data": data,
        "word_count": int(main.get("word_count") or 0),
        "paragraph_count": int(main.get("paragraph_count") or 0),
        "title": main.get("title") or "",
        "place": main.get("place") or "",
    }


def expected_bank(haribhakts: dict[int, dict] | None = None) -> list[dict]:
    index = haribhakts if haribhakts is not None else load_haribhakt_index()
    expected = []
    for part, kiran_index, path in iter_kirans():
        meta = kiran_meta(path)
        recorded = len((index.get(kiran_index) or {}).get("questions") or [])
        expected.append(
            {
                "part": part,
                "kiranIndex": kiran_index,
                "wordCount": meta["word_count"],
                "targetCount": target_question_count(meta["word_count"], recorded),
                "recordedQuestions": recorded,
                "path": str(path),
            }
        )
    return expected


def source_payload(part: int, index: int, data: dict, haribhakt: dict | None) -> dict:
    main = data.get("main") or {}
    meta = data.get("meta") or {}
    people = haribhakt or {}
    return {
        "part": part,
        "kiranIndex": index,
        "title": main.get("title"),
        "place": main.get("place"),
        "date": meta.get("date"),
        "moral": meta.get("moral"),
        "summary": meta.get("summary"),
        "hosts": people.get("hosts") or [],
        "readers": people.get("readers") or [],
        "mentioned": people.get("mentioned") or [],
        "recordedQuestions": people.get("questions") or [],
        "text": strip_html(main.get("content") or ""),
    }


def source_blob(part: int, index: int, data: dict, haribhakt: dict | None) -> str:
    return json.dumps(
        source_payload(part, index, data, haribhakt),
        ensure_ascii=False,
        indent=2,
    )


def grounding_corpus(data: dict, haribhakt: dict | None) -> str:
    main = data.get("main") or {}
    meta = data.get("meta") or {}
    people = haribhakt or {}
    chunks = [
        strip_html(main.get("content") or ""),
        str(main.get("title") or ""),
        str(main.get("place") or ""),
        str(meta.get("date") or ""),
        str(meta.get("moral") or ""),
        " ".join(str(item) for item in (meta.get("summary") or [])),
        " ".join(str(item) for item in (meta.get("locations") or [])),
        " ".join(people.get("hosts") or []),
        " ".join(people.get("readers") or []),
        " ".join(people.get("mentioned") or []),
        " ".join(item.get("text") or "" for item in people.get("questions") or []),
        " ".join(item.get("askers") or "" for item in people.get("questions") or []),
    ]
    return normalize_gu(" ".join(chunks))


def question_is_grounded(question: dict, corpus: str) -> bool:
    options = question.get("options") or []
    correct = question.get("correctIndex", -1)
    if isinstance(correct, int) and 0 <= correct < len(options):
        option = normalize_gu(str(options[correct]))
        if len(option) >= 4 and option in corpus:
            return True
    explanation = normalize_gu(str(question.get("explanation") or ""))
    if len(explanation) >= 8:
        for size in (16, 12, 8):
            if len(explanation) >= size and explanation[:size] in corpus:
                return True
    hint = normalize_gu(str(question.get("sourceHint") or ""))
    return bool(hint) and hint in corpus


def validate_quiz(
    quiz: dict,
    part: int,
    index: int,
    target: int,
    corpus: str,
) -> list[str]:
    errors: list[str] = []
    questions = quiz.get("questions") or []
    if len(questions) != target:
        errors.append(f"expected {target} questions, got {len(questions)}")
    prompts: set[str] = set()
    for i, question in enumerate(questions, start=1):
        qid = question.get("id") or f"p{part}-{index}-q{i}"
        options = question.get("options") or []
        if len(options) != 4:
            errors.append(f"{qid} needs 4 options")
            continue
        if any(not str(option).strip() for option in options):
            errors.append(f"{qid} has an empty option")
        correct = question.get("correctIndex", -1)
        if not isinstance(correct, int) or not 0 <= correct < 4:
            errors.append(f"{qid} has bad correctIndex")
        prompt = str(question.get("prompt") or "").strip()
        if not prompt:
            errors.append(f"{qid} missing prompt")
        elif prompt in prompts:
            errors.append(f"{qid} duplicate prompt")
        else:
            prompts.add(prompt)
        if not question_is_grounded(question, corpus):
            errors.append(f"{qid} is not grounded in the kiran")
    return errors


def normalize_quiz(quiz: dict, part: int, index: int) -> dict:
    quiz["part"] = part
    quiz["kiranIndex"] = index
    quiz.setdefault("version", 1)
    quiz.setdefault("locale", "gu")
    for i, question in enumerate(quiz.get("questions") or [], start=1):
        question["id"] = f"p{part}-{index}-q{i}"
        if isinstance(question.get("correctIndex"), str) and question["correctIndex"].isdigit():
            question["correctIndex"] = int(question["correctIndex"])
    return quiz


def output_path(out_dir: Path, part: int, index: int) -> Path:
    return out_dir / f"{part}_{index}.json"


def load_existing_quiz(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    if "quizzes" in payload:
        payload = (payload.get("quizzes") or [None])[0]
    return payload if isinstance(payload, dict) else None


def chunk_sizes(target: int, chunk_size: int = CHUNK_SIZE) -> list[int]:
    if target <= chunk_size:
        return [target]
    sizes = [chunk_size] * (target // chunk_size)
    remainder = target % chunk_size
    if remainder:
        sizes.append(remainder)
    return sizes
