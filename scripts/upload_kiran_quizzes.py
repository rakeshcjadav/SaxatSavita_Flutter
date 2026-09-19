#!/usr/bin/env python3
"""Upload generated or seed kiran quizzes to Firestore kiranQuizzes.

Requirements:
  pip install firebase-admin
  export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json

Examples:
  python3 scripts/upload_kiran_quizzes.py --seed
  python3 scripts/upload_kiran_quizzes.py --dir scripts/quiz_output
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "assets/book/saxatsavita/quizzes/kiran_quizzes.json"
DEFAULT_DIR = ROOT / "scripts/quiz_output"


def load_quizzes(seed: bool, directory: Path | None) -> list[dict]:
    quizzes: list[dict] = []
    if seed:
        data = json.loads(SEED.read_text(encoding="utf-8"))
        quizzes.extend(data.get("quizzes") or [])
    if directory and directory.exists():
        for path in sorted(directory.glob("*.json")):
            payload = json.loads(path.read_text(encoding="utf-8"))
            if "quizzes" in payload:
                quizzes.extend(payload["quizzes"])
            else:
                quizzes.append(payload)
    return quizzes


def main() -> int:
    parser = argparse.ArgumentParser(description="Upload kiran quizzes to Firestore")
    parser.add_argument("--seed", action="store_true", help="Include bundled seed bank")
    parser.add_argument("--dir", type=Path, default=DEFAULT_DIR)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    quizzes = load_quizzes(args.seed, args.dir)
    if not quizzes:
        print("No quizzes to upload", file=sys.stderr)
        return 1

    if args.dry_run:
        for quiz in quizzes:
            print(f"would upload {quiz.get('part')}_{quiz.get('kiranIndex')}")
        return 0

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print("Install firebase-admin and set GOOGLE_APPLICATION_CREDENTIALS", file=sys.stderr)
        return 1

    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.ApplicationDefault())
    db = firestore.client()

    for quiz in quizzes:
        part = quiz.get("part")
        index = quiz.get("kiranIndex")
        if part is None or index is None:
            print(f"skipping quiz without part/kiranIndex: {quiz}", file=sys.stderr)
            continue
        doc_id = f"{part}_{index}"
        db.collection("kiranQuizzes").document(doc_id).set(quiz, merge=True)
        print(f"uploaded {doc_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
