#!/usr/bin/env python3
"""Generate Gujarati kiran MCQs with Gemini. Not used at app runtime.

Requirements:
  pip install google-genai
  export GEMINI_API_KEY=your_api_key

Examples:
  python3 scripts/generate_kiran_quizzes.py --part 1 --index 1
  python3 scripts/generate_kiran_quizzes.py --part 1 --limit 5
  python3 scripts/generate_kiran_quizzes.py --part 1 --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIRAN_ROOT = ROOT / "assets/book/saxatsavita"
OUT_DIR = ROOT / "scripts/quiz_output"

try:
    from google import genai
except ImportError:
    genai = None


PROMPT = """You write Gujarati multiple-choice questions for a Swaminarayan kiran.
Use ONLY the source below. Do not invent doctrine, people, places, or quotes.
Return JSON only, no markdown.

Schema:
{{
  "part": {part},
  "kiranIndex": {index},
  "version": 1,
  "locale": "gu",
  "questions": [
    {{
      "id": "p{part}-{index}-q1",
      "prompt": "Gujarati question",
      "options": ["A", "B", "C", "D"],
      "correctIndex": 0,
      "explanation": "Short Gujarati reason from the kiran",
      "sourceHint": "place or teaching"
    }}
  ]
}}

Write 2 or 3 questions:
1. One fact (place, host, reader, or date if present).
2. One teaching from the moral/summary.
3. Optional: a recorded haribhakt question if the source lists one.

Each question needs exactly 4 Gujarati options and one correctIndex.

SOURCE:
{source}
"""


def strip_html(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def iter_kirans(part: int | None, index: int | None, limit: int | None):
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


def source_blob(part: int, index: int, data: dict) -> str:
    main = data.get("main") or {}
    meta = data.get("meta") or {}
    haribhakts = data.get("haribhakts") or main.get("haribhakts") or []
    return json.dumps(
        {
            "part": part,
            "kiranIndex": index,
            "title": main.get("title"),
            "place": main.get("place"),
            "date": meta.get("date"),
            "moral": meta.get("moral"),
            "summary": meta.get("summary"),
            "haribhakts": haribhakts,
            "text": strip_html(main.get("content") or ""),
        },
        ensure_ascii=False,
        indent=2,
    )


def parse_quiz(raw: str, part: int, index: int) -> dict:
    text = raw.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?", "", text)
        text = re.sub(r"```$", "", text).strip()
    quiz = json.loads(text)
    quiz["part"] = part
    quiz["kiranIndex"] = index
    quiz.setdefault("version", 1)
    quiz.setdefault("locale", "gu")
    questions = quiz.get("questions") or []
    if not 2 <= len(questions) <= 3:
        raise ValueError(f"expected 2-3 questions, got {len(questions)}")
    for i, question in enumerate(questions, start=1):
        question.setdefault("id", f"p{part}-{index}-q{i}")
        options = question.get("options") or []
        if len(options) != 4:
            raise ValueError(f"{question.get('id')} needs 4 options")
        correct = question.get("correctIndex", -1)
        if not isinstance(correct, int) or not 0 <= correct < 4:
            raise ValueError(f"{question.get('id')} has bad correctIndex")
    return quiz


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate kiran MCQs with Gemini")
    parser.add_argument("--part", type=int, choices=range(1, 6))
    parser.add_argument("--index", type=int)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--model", default="gemini-2.5-flash")
    parser.add_argument("--out-dir", type=Path, default=OUT_DIR)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    items = list(iter_kirans(args.part, args.index, args.limit))
    if not items:
        print("No kirans matched", file=sys.stderr)
        return 1

    if args.dry_run:
        for part, index, path in items:
            print(f"would generate part={part} index={index} {path}")
        return 0

    if genai is None:
        print("Install google-genai and set GEMINI_API_KEY", file=sys.stderr)
        return 1
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Set GEMINI_API_KEY", file=sys.stderr)
        return 1

    client = genai.Client(api_key=api_key)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    for part, index, path in items:
        data = json.loads(path.read_text(encoding="utf-8"))
        prompt = PROMPT.format(
            part=part, index=index, source=source_blob(part, index, data)
        )
        print(f"generating part={part} index={index}")
        response = client.models.generate_content(model=args.model, contents=prompt)
        text = getattr(response, "text", None) or ""
        if not text and getattr(response, "candidates", None):
            text = response.candidates[0].content.parts[0].text
        quiz = parse_quiz(text, part, index)
        out = args.out_dir / f"{part}_{index}.json"
        out.write_text(json.dumps(quiz, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"  wrote {out}")
        time.sleep(0.4)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
