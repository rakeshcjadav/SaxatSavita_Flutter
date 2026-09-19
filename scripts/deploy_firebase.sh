#!/usr/bin/env bash
# Deploy Firestore rules / quizzes only as farenidham.dev@gmail.com.
set -euo pipefail

REQUIRED_ACCOUNT="farenidham.dev@gmail.com"
PROJECT="saxat-savita-crashanalytics"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/.nvm/versions/node/v25.9.0/bin:${HOME}/Downloads/google-cloud-sdk/bin:${PATH}"

firebase_cmd() {
  npx --yes firebase-tools@latest \
    --account "$REQUIRED_ACCOUNT" \
    --project "$PROJECT" \
    --non-interactive \
    "$@"
}

require_account() {
  local listing
  listing="$(npx --yes firebase-tools@latest login:list --non-interactive 2>&1)" || true
  if ! grep -Fq "$REQUIRED_ACCOUNT" <<<"$listing"; then
    echo "error: Firebase CLI is not logged in as ${REQUIRED_ACCOUNT}" >&2
    echo "$listing" >&2
    echo "Run: npx firebase-tools login" >&2
    echo "Then: npx firebase-tools login:use ${REQUIRED_ACCOUNT}" >&2
    exit 1
  fi
  if ! npx --yes firebase-tools@latest login:use "$REQUIRED_ACCOUNT" --non-interactive >/dev/null 2>&1; then
    listing="$(npx --yes firebase-tools@latest login:list --non-interactive 2>&1)" || true
    if ! grep -Fq "Logged in as ${REQUIRED_ACCOUNT}" <<<"$listing"; then
      echo "error: could not switch Firebase CLI to ${REQUIRED_ACCOUNT}" >&2
      echo "$listing" >&2
      exit 1
    fi
  fi
  listing="$(npx --yes firebase-tools@latest login:list --non-interactive 2>&1)" || true
  if ! grep -Fq "Logged in as ${REQUIRED_ACCOUNT}" <<<"$listing"; then
    echo "error: could not switch Firebase CLI to ${REQUIRED_ACCOUNT}" >&2
    echo "$listing" >&2
    exit 1
  fi
  echo "Using Firebase account ${REQUIRED_ACCOUNT} on ${PROJECT}"
}

require_gcloud_account() {
  if ! gcloud auth print-access-token --account="$REQUIRED_ACCOUNT" >/dev/null 2>&1; then
    echo "error: gcloud is not logged in as ${REQUIRED_ACCOUNT}" >&2
    echo "Quiz upload/verify uses gcloud. Run:" >&2
    echo "  gcloud auth login ${REQUIRED_ACCOUNT}" >&2
    exit 1
  fi
}

usage() {
  cat <<EOF
Usage: scripts/deploy_firebase.sh <rules|quizzes|all|verify> [--seed]

Always deploys as ${REQUIRED_ACCOUNT} to ${PROJECT}.
Other Firebase / gcloud accounts are refused.

  rules     Deploy firestore.rules
  quizzes   Upload quiz JSON (pass --seed for the bundled bank)
  all       rules + quizzes
  verify    List kiranQuizzes docs and check the seed bank
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
  rules|quizzes|all|verify) ;;
  -h|--help|help|"")
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

require_account

case "$cmd" in
  rules)
    firebase_cmd deploy --only firestore:rules
    ;;
  quizzes)
    require_gcloud_account
    python3 "$ROOT/scripts/upload_kiran_quizzes.py" --project "$PROJECT" --seed "$@"
    ;;
  all)
    require_gcloud_account
    firebase_cmd deploy --only firestore:rules
    python3 "$ROOT/scripts/upload_kiran_quizzes.py" --project "$PROJECT" --seed "$@"
    python3 "$ROOT/scripts/upload_kiran_quizzes.py" --project "$PROJECT" --verify --seed
    ;;
  verify)
    require_gcloud_account
    python3 "$ROOT/scripts/upload_kiran_quizzes.py" --project "$PROJECT" --verify --seed
    ;;
esac
