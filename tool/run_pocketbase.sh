#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_PATH="${PROJECT_ROOT}/backend/bin/pocketbase"

if [[ ! -x "${BIN_PATH}" ]]; then
  echo "PocketBase is not installed. Run ./tool/bootstrap_pocketbase.sh first." >&2
  exit 1
fi

exec "${BIN_PATH}" serve \
  --dir="${PROJECT_ROOT}/backend/pb_data" \
  --migrationsDir="${PROJECT_ROOT}/backend/pb_migrations" \
  --hooksDir="${PROJECT_ROOT}/backend/pb_hooks" \
  --http="127.0.0.1:8090"
