#!/usr/bin/env python3
"""Upload daily quizzes to Firestore.

Default: --month YYYY-MM PATCHes that folder to dailyQuizzes/{yyyy-MM-dd}.
--bank PATCHes the 3-pack rotation to dailyQuizBank/current. With no
args (or only --dry-run), print usage and do nothing.

  python3 scripts/upload_daily_quizzes.py --month 2026-09
  python3 scripts/upload_daily_quizzes.py --month 2026-09 --dry-run
  python3 scripts/upload_daily_quizzes.py --bank
  python3 scripts/upload_daily_quizzes.py --bank --dry-run

Authoring layout (dated overlays, one pack per calendar day):

  scripts/daily_quizzes/_bank.json          # rotation for dailyQuizBank/current
  scripts/daily_quizzes/2026-09/01.json     # PATCH -> dailyQuizzes/2026-09-01
  scripts/daily_quizzes/2026-09/30.json

Each DD.json is one day's pack: id (yyyy-MM-dd) plus 5 questions
(prompt/options/correctIndex/explanation/part/kiranIndex).

The app already prefers dated dailyQuizzes/{date} over bank rotation.
--bank copies _bank.json into the bundled asset (offline fallback).
--month does not touch assets.

Always uses farenidham.dev@gmail.com. Default gcloud / other Firebase
logins are ignored.
"""

from __future__ import annotations

import argparse
import calendar
import json
import shutil
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
QUIZ_DIR = SCRIPTS / "daily_quizzes"
BANK = QUIZ_DIR / "_bank.json"
ASSET = ROOT / "assets/book/saxatsavita/quizzes/daily_quiz_bank.json"
MIN_QUESTIONS = 5


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


def _parse_month(value: str) -> tuple[int, int]:
    parts = value.split("-")
    if len(parts) != 2 or len(parts[0]) != 4 or len(parts[1]) != 2:
        raise argparse.ArgumentTypeError("expected YYYY-MM")
    try:
        year = int(parts[0])
        month = int(parts[1])
    except ValueError as error:
        raise argparse.ArgumentTypeError("expected YYYY-MM") from error
    if year < 1 or not (1 <= month <= 12):
        raise argparse.ArgumentTypeError("expected YYYY-MM")
    return year, month


def _read_int(value) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        return None


def _question_errors(question) -> list[str]:
    if not isinstance(question, dict):
        return ["not an object"]
    errors: list[str] = []
    qid = str(question.get("id") or "").strip()
    prompt = str(question.get("prompt") or "").strip()
    raw_options = question.get("options") or []
    if not isinstance(raw_options, list):
        options: list[str] = []
    else:
        options = [str(item).strip() for item in raw_options if str(item).strip()]
    correct = _read_int(question.get("correctIndex"))
    part = _read_int(question.get("part"))
    kiran = _read_int(question.get("kiranIndex"))
    if not qid:
        errors.append("empty id")
    if not prompt:
        errors.append("empty prompt")
    if len(options) < 2:
        errors.append("need >=2 options")
    if correct is None or not (0 <= correct < len(options)):
        errors.append("correctIndex out of range")
    if part is None or part < 1:
        errors.append("part < 1")
    if kiran is None or kiran < 1:
        errors.append("kiranIndex < 1")
    return errors


def _valid_questions(payload: dict) -> list[dict]:
    questions = payload.get("questions") or []
    if not isinstance(questions, list):
        return []
    return [
        question
        for question in questions
        if isinstance(question, dict) and not _question_errors(question)
    ]


def _print_pack_counts(payload: dict) -> list:
    packs = payload.get("packs") or []
    print(f"{len(packs)} pack(s), locale={payload.get('locale')}")
    for pack in packs:
        questions = pack.get("questions") or []
        print(f"  {pack.get('id')}  questions={len(questions)}")
    return packs


def _sync_asset() -> None:
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(BANK, ASSET)
    print(f"copied {BANK.relative_to(ROOT)} -> {ASSET.relative_to(ROOT)}")


def _patch_document(
    *,
    token: str,
    project: str,
    collection: str,
    doc_id: str,
    payload: dict,
) -> None:
    url = (
        f"https://firestore.googleapis.com/v1/projects/{project}"
        f"/databases/(default)/documents/{collection}/{doc_id}"
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


def _load_json(path: Path) -> tuple[dict | None, str | None]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return None, str(error)
    if not isinstance(payload, dict):
        return None, "root must be an object"
    return payload, None


def _upload_bank(*, dry_run: bool, account: str, project: str) -> int:
    if not BANK.exists():
        print(f"missing {BANK}", file=sys.stderr)
        return 1

    payload, error = _load_json(BANK)
    if payload is None:
        print(f"invalid {BANK}: {error}", file=sys.stderr)
        return 1

    packs = _print_pack_counts(payload)
    valid_packs = [
        pack
        for pack in packs
        if isinstance(pack, dict)
        and str(pack.get("id") or "").strip()
        and len(_valid_questions(pack)) >= MIN_QUESTIONS
    ]
    if len(valid_packs) != len(packs) or not valid_packs:
        print(
            f"bank needs >=1 pack with {MIN_QUESTIONS} valid questions "
            f"({len(valid_packs)}/{len(packs)} ok)",
            file=sys.stderr,
        )
        return 1

    if dry_run:
        print(f"would upload dailyQuizBank/current as {account} to {project}")
        print(f"would copy {BANK.relative_to(ROOT)} -> {ASSET.relative_to(ROOT)}")
        return 0

    _sync_asset()
    token = access_token(account)
    _patch_document(
        token=token,
        project=project,
        collection="dailyQuizBank",
        doc_id="current",
        payload=payload,
    )
    print(f"uploaded dailyQuizBank/current as {account} on {project}")
    return 0


def _upload_month(
    *,
    year: int,
    month: int,
    dry_run: bool,
    account: str,
    project: str,
) -> int:
    month_key = f"{year:04d}-{month:02d}"
    month_dir = QUIZ_DIR / month_key
    last_day = calendar.monthrange(year, month)[1]
    if not month_dir.is_dir():
        print(f"missing {month_dir.relative_to(ROOT)}", file=sys.stderr)
        return 1

    expected_names = {f"{day:02d}.json" for day in range(1, last_day + 1)}
    extras = sorted(
        path.name
        for path in month_dir.glob("*.json")
        if path.name not in expected_names
    )
    if extras:
        print(f"ignored extra json: {', '.join(extras)}")

    ready: list[tuple[str, Path, dict]] = []
    missing: list[str] = []
    invalid: list[str] = []

    for day in range(1, last_day + 1):
        date_id = f"{year:04d}-{month:02d}-{day:02d}"
        path = month_dir / f"{day:02d}.json"
        rel = path.relative_to(ROOT)
        if not path.exists():
            missing.append(date_id)
            print(f"  missing  {rel}")
            continue
        payload, error = _load_json(path)
        if payload is None:
            invalid.append(date_id)
            print(f"  invalid  {rel}  {error}")
            continue
        pack_id = str(payload.get("id") or "").strip()
        questions = _valid_questions(payload)
        errors: list[str] = []
        if len(questions) < MIN_QUESTIONS:
            errors.append(
                f"{len(questions)} valid questions (need {MIN_QUESTIONS})"
            )
        if not pack_id:
            errors.append("empty id")
        if errors:
            invalid.append(date_id)
            print(f"  invalid  {rel}  {'; '.join(errors)}")
            continue
        if pack_id != date_id:
            print(f"  warning  {rel}  id={pack_id!r} coerced to {date_id}")
            payload = {**payload, "id": date_id}
        ready.append((date_id, path, payload))
        print(f"  ok       {rel}  questions={len(questions)}")

    print(
        f"{month_key}: {len(ready)} ready, {len(missing)} missing, "
        f"{len(invalid)} invalid, {last_day} calendar days"
    )

    if not ready:
        print("nothing to upload", file=sys.stderr)
        return 1

    if dry_run:
        for date_id, path, _payload in ready:
            print(
                f"would PATCH dailyQuizzes/{date_id} from "
                f"{path.relative_to(ROOT)} as {account} to {project}"
            )
        print(
            f"would upload {len(ready)}/{last_day} days to "
            f"dailyQuizzes/{{yyyy-MM-dd}} on {project}"
        )
        return 1 if invalid else 0

    token = access_token(account)
    uploaded = 0
    failed: list[str] = []
    for date_id, path, payload in ready:
        try:
            _patch_document(
                token=token,
                project=project,
                collection="dailyQuizzes",
                doc_id=date_id,
                payload=payload,
            )
        except Exception as error:
            failed.append(date_id)
            print(
                f"  FAIL     dailyQuizzes/{date_id}  {error}",
                file=sys.stderr,
            )
            continue
        uploaded += 1
        print(f"  PATCH    dailyQuizzes/{date_id}")

    print(
        f"uploaded {uploaded}  failed {len(failed)}  "
        f"skipped invalid {len(invalid)}  missing {len(missing)}  "
        f"as {account} on {project}"
    )
    if failed or invalid:
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--month",
        metavar="YYYY-MM",
        type=_parse_month,
        help="PATCH scripts/daily_quizzes/YYYY-MM/DD.json to dailyQuizzes/{yyyy-MM-dd}",
    )
    parser.add_argument(
        "--bank",
        action="store_true",
        help="PATCH _bank.json to dailyQuizBank/current and refresh the bundled asset",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--account", default=REQUIRED_ACCOUNT)
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    args = parser.parse_args()
    if args.month is None and not args.bank:
        parser.print_help()
        return 2

    account = assert_account(args.account)
    status = 0
    if args.month is not None:
        year, month = args.month
        status = _upload_month(
            year=year,
            month=month,
            dry_run=args.dry_run,
            account=account,
            project=args.project,
        )
    if args.bank:
        bank_status = _upload_bank(
            dry_run=args.dry_run,
            account=account,
            project=args.project,
        )
        if bank_status != 0:
            status = bank_status
    return status


if __name__ == "__main__":
    raise SystemExit(main())
