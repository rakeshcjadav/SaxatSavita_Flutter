#!/usr/bin/env python3
"""Pin Firestore admin calls to farenidham.dev@gmail.com.

Uses gcloud --account only. Never falls back to the default gcloud user.
"""

from __future__ import annotations

import json
import subprocess

REQUIRED_ACCOUNT = "farenidham.dev@gmail.com"
DEFAULT_PROJECT = "saxat-savita-crashanalytics"


def assert_account(account: str | None) -> str:
    resolved = (account or REQUIRED_ACCOUNT).strip().lower()
    if resolved != REQUIRED_ACCOUNT:
        raise SystemExit(
            f"Refusing account {resolved!r}. Deploys must use {REQUIRED_ACCOUNT}."
        )
    return REQUIRED_ACCOUNT


def access_token(account: str = REQUIRED_ACCOUNT) -> str:
    account = assert_account(account)
    try:
        token = subprocess.check_output(
            ["gcloud", "auth", "print-access-token", f"--account={account}"],
            text=True,
            stderr=subprocess.PIPE,
        ).strip()
    except FileNotFoundError as error:
        raise SystemExit("gcloud is not installed or not on PATH.") from error
    except subprocess.CalledProcessError:
        raise SystemExit(
            f"gcloud is not logged in as {account}.\n"
            f"  gcloud auth login {account}\n"
            f"Firebase CLI deploys already use --account {account}."
        )
    if not token:
        raise SystemExit(f"gcloud returned an empty token for {account}.")
    return token


def http_json(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: bytes | str | None = None,
) -> dict:
    """HTTPS JSON via curl so macOS Python 3.14 cert issues do not block deploy."""
    command = ["curl", "-sS", "-X", method, url]
    for key, value in (headers or {}).items():
        command.extend(["-H", f"{key}: {value}"])
    stdin = None
    if data is not None:
        command.extend(["--data-binary", "@-"])
        stdin = data.decode("utf-8") if isinstance(data, bytes) else data
    command.extend(["-w", "\n%{http_code}"])
    completed = subprocess.run(
        command,
        input=stdin,
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "curl failed")
    body, _, status = completed.stdout.rpartition("\n")
    if status not in {"200", "201"}:
        raise RuntimeError(f"{status} {body}")
    return json.loads(body) if body.strip() else {}
