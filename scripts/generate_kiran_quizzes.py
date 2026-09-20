#!/usr/bin/env python3
"""Generate grounded Gujarati kiran MCQs from the book JSON.

No Gemini or other external model. Questions are built from place, date,
title, haribhakts, summary, moral, and sentences in each kiran.

Examples:
  python3 scripts/generate_kiran_quizzes.py --part 1 --index 1
  python3 scripts/generate_kiran_quizzes.py --dry-run
  python3 scripts/generate_kiran_quizzes.py
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from kiran_quiz_bank import (  # noqa: E402
    OUT_DIR,
    expected_bank,
    grounding_corpus,
    iter_kirans,
    kiran_meta,
    load_existing_quiz,
    load_haribhakt_index,
    normalize_quiz,
    output_path,
    target_question_count,
    validate_quiz,
)
from local_kiran_quiz import build_questions, load_catalog  # noqa: E402


def quiz_is_complete(quiz: dict | None, part: int, index: int, target: int, corpus: str) -> bool:
    if not quiz:
        return False
    normalize_quiz(quiz, part, index)
    return not validate_quiz(quiz, part, index, target, corpus)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate kiran MCQs from book JSON")
    parser.add_argument("--part", type=int, choices=range(1, 6))
    parser.add_argument("--index", type=int)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--out-dir", type=Path, default=OUT_DIR)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    haribhakts = load_haribhakt_index()
    items = list(iter_kirans(args.part, args.index, args.limit))
    if not items:
        print("No kirans matched", file=sys.stderr)
        return 1

    planned = []
    for part, index, path in items:
        meta = kiran_meta(path)
        recorded = len((haribhakts.get(index) or {}).get("questions") or [])
        target = target_question_count(meta["word_count"], recorded)
        planned.append((part, index, path, meta, recorded, target))

    if args.dry_run:
        total = sum(item[5] for item in planned)
        for part, index, path, meta, recorded, target in planned:
            print(
                f"part={part} index={index} words={meta['word_count']} "
                f"recorded={recorded} target={target} {path.name}"
            )
        print(f"{len(planned)} kirans, {total} questions")
        return 0

    sources, pools = load_catalog()
    by_id = {(item["part"], item["kiranIndex"]): item for item in sources}
    args.out_dir.mkdir(parents=True, exist_ok=True)
    failed = 0
    written = 0
    skipped = 0

    for part, index, path, meta, recorded, target in planned:
        source = by_id[(part, index)]
        corpus = grounding_corpus(meta["data"], haribhakts.get(index))
        out = output_path(args.out_dir, part, index)
        existing = None if args.force else load_existing_quiz(out)
        if quiz_is_complete(existing, part, index, target, corpus):
            skipped += 1
            continue
        questions = build_questions(source, pools, target)
        quiz = normalize_quiz(
            {
                "part": part,
                "kiranIndex": index,
                "version": 2,
                "locale": "gu",
                "questions": questions,
            },
            part,
            index,
        )
        errors = validate_quiz(quiz, part, index, target, corpus)
        if errors:
            failed += 1
            print(
                f"invalid part={part} index={index} "
                f"got={len(questions)} target={target}: {'; '.join(errors[:4])}",
                file=sys.stderr,
            )
            continue
        out.write_text(json.dumps(quiz, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        written += 1
        print(f"wrote {out.name} ({len(questions)} questions)")

    print(f"wrote={written} skipped={skipped} failed={failed} of {len(planned)}")
    if failed:
        return 1
    if not planned:
        return 1
    print(f"expected bank {len(expected_bank(haribhakts))} kirans")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
