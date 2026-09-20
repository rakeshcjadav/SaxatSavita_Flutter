#!/usr/bin/env python3
"""Upload bundled daily quiz bank to Firestore dailyQuizBank/current.

Always uses farenidham.dev@gmail.com.

Examples:
  python3 scripts/upload_daily_quizzes.py
  python3 scripts/upload_daily_quizzes.py --dry-run
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
BANK = ROOT / "assets/book/saxatsavita/quizzes/daily_quiz_bank.json"


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


def main() -> int:
    parser = argparse.ArgumentParser(description="Upload daily quiz bank")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--account", default=REQUIRED_ACCOUNT)
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    args = parser.parse_args()
    account = assert_account(args.account)

    if not BANK.exists():
        print(f"missing {BANK}", file=sys.stderr)
        return 1

    payload = json.loads(BANK.read_text(encoding="utf-8"))
    packs = payload.get("packs") or []
    print(f"{len(packs)} pack(s), locale={payload.get('locale')}")

    if args.dry_run:
        print(f"would upload dailyQuizBank/current as {account} to {args.project}")
        return 0

    token = access_token(account)
    url = (
        f"https://firestore.googleapis.com/v1/projects/{args.project}"
        "/databases/(default)/documents/dailyQuizBank/current"
    )
    body = json.dumps(
        {"fields": {key: _to_value(value) for key, value in payload.items()}}
    ).encode()
    http_json(
        url,
        method="PATCH",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        data=body,
    )
    print(f"uploaded dailyQuizBank/current as {account} on {args.project}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
