#!/usr/bin/env python3
"""Upload generated or seed kiran quizzes to Firestore kiranQuizzes.

Always uses farenidham.dev@gmail.com. Default gcloud / other Firebase
logins are ignored.

Examples:
  python3 scripts/upload_kiran_quizzes.py --seed
  python3 scripts/upload_kiran_quizzes.py --dir scripts/quiz_output
  python3 scripts/upload_kiran_quizzes.py --verify --seed
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from firebase_deploy_account import (  # noqa: E402
    DEFAULT_PROJECT,
    REQUIRED_ACCOUNT,
    access_token,
    assert_account,
    http_json,
)

ROOT = SCRIPTS.parent
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


def quiz_doc_id(quiz: dict) -> str | None:
    part = quiz.get("part")
    index = quiz.get("kiranIndex")
    if part is None or index is None:
        return None
    return f"{part}_{index}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Upload kiran quizzes to Firestore")
    parser.add_argument("--seed", action="store_true", help="Include bundled seed bank")
    parser.add_argument("--dir", type=Path, default=DEFAULT_DIR)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verify", action="store_true", help="List and check kiranQuizzes")
    parser.add_argument(
        "--account",
        default=REQUIRED_ACCOUNT,
        help=f"Must be {REQUIRED_ACCOUNT}",
    )
    parser.add_argument(
        "--project",
        default=DEFAULT_PROJECT,
        help="Firebase / GCP project ID",
    )
    args = parser.parse_args()
    account = assert_account(args.account)

    upload_dir = args.dir if args.dir.exists() else None
    if args.verify:
        expected = load_quizzes(args.seed, upload_dir if args.seed else None)
        return verify_quizzes(args.project, account, expected or None)

    quizzes = load_quizzes(args.seed, upload_dir)

    if not quizzes:
        print("No quizzes to upload", file=sys.stderr)
        return 1

    if args.dry_run:
        print(f"would upload as {account} to {args.project}")
        for quiz in quizzes:
            doc_id = quiz_doc_id(quiz)
            if doc_id:
                print(f"would upload {doc_id}")
        return 0

    print(f"uploading as {account} to {args.project}")
    return _upload_via_rest(quizzes, args.project, account)


def _to_value(value):
    if value is None:
        return {"nullValue": None}
    if isinstance(value, bool):
        return {"booleanValue": value}
    if isinstance(value, int):
        return {"integerValue": str(value)}
    if isinstance(value, float):
        return {"doubleValue": value}
    if isinstance(value, str):
        return {"stringValue": value}
    if isinstance(value, list):
        return {"arrayValue": {"values": [_to_value(item) for item in value]}}
    if isinstance(value, dict):
        return {
            "mapValue": {
                "fields": {key: _to_value(item) for key, item in value.items()}
            }
        }
    return {"stringValue": str(value)}


def _from_value(value):
    if "nullValue" in value:
        return None
    if "booleanValue" in value:
        return value["booleanValue"]
    if "integerValue" in value:
        return int(value["integerValue"])
    if "doubleValue" in value:
        return float(value["doubleValue"])
    if "stringValue" in value:
        return value["stringValue"]
    if "arrayValue" in value:
        return [_from_value(item) for item in value.get("arrayValue", {}).get("values", [])]
    if "mapValue" in value:
        fields = value.get("mapValue", {}).get("fields", {})
        return {key: _from_value(item) for key, item in fields.items()}
    return value


def _firestore_request(url: str, token: str, method: str = "GET", body: bytes | None = None):
    return http_json(
        url,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        data=body,
    )


def _collection_url(project: str, doc_id: str | None = None) -> str:
    base = (
        f"https://firestore.googleapis.com/v1/projects/{project}"
        f"/databases/(default)/documents/kiranQuizzes"
    )
    return f"{base}/{doc_id}" if doc_id else base


def _upload_via_rest(quizzes: list[dict], project: str, account: str) -> int:
    token = access_token(account)
    for quiz in quizzes:
        doc_id = quiz_doc_id(quiz)
        if not doc_id:
            print(f"skipping quiz without part/kiranIndex: {quiz}", file=sys.stderr)
            continue
        body = json.dumps(
            {"fields": {key: _to_value(value) for key, value in quiz.items()}}
        ).encode("utf-8")
        try:
            _firestore_request(_collection_url(project, doc_id), token, method="PATCH", body=body)
        except RuntimeError as error:
            print(f"failed {doc_id}: {error}", file=sys.stderr)
            return 1
        print(f"uploaded {doc_id}")
    return 0


def verify_quizzes(project: str, account: str, expected: list[dict] | None) -> int:
    token = access_token(account)
    console = (
        f"https://console.firebase.google.com/project/{project}"
        "/firestore/databases/-default-/data/~2FkiranQuizzes"
    )
    print(f"checking kiranQuizzes as {account} on {project}")
    print(console)
    try:
        payload = _firestore_request(_collection_url(project), token)
    except RuntimeError as error:
        print(f"list failed: {error}", file=sys.stderr)
        return 1

    documents = payload.get("documents") or []
    remote: dict[str, dict] = {}
    for document in documents:
        name = document.get("name") or ""
        doc_id = name.rsplit("/", 1)[-1]
        fields = {
            key: _from_value(value)
            for key, value in (document.get("fields") or {}).items()
        }
        remote[doc_id] = fields
        questions = fields.get("questions") or []
        print(
            f"  {doc_id}  part={fields.get('part')}  "
            f"kiran={fields.get('kiranIndex')}  "
            f"questions={len(questions)}  version={fields.get('version')}"
        )

    if not documents:
        print("  (no documents — quizzes are not uploaded yet)")

    print(f"{len(documents)} document(s) in kiranQuizzes")
    if not expected:
        return 0

    missing = []
    for quiz in expected:
        doc_id = quiz_doc_id(quiz)
        if not doc_id:
            continue
        if doc_id not in remote:
            missing.append(doc_id)
            continue
        want = len(quiz.get("questions") or [])
        got = len(remote[doc_id].get("questions") or [])
        if want != got:
            print(f"mismatch {doc_id}: expected {want} questions, found {got}", file=sys.stderr)
            return 1
    if missing:
        print(f"missing: {', '.join(missing)}", file=sys.stderr)
        return 1
    print(f"seed bank present ({len(expected)} quiz(zes))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
