#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POCKETBASE_VERSION="${PB_VERSION:-0.40.2}"
BIN_DIR="${PROJECT_ROOT}/backend/bin"
BIN_PATH="${BIN_DIR}/pocketbase"

if [[ ! "${POCKETBASE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid PB_VERSION: ${POCKETBASE_VERSION}" >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin) OS_NAME="darwin" ;;
  Linux) OS_NAME="linux" ;;
  *) echo "Unsupported operating system: $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
  arm64|aarch64) ARCH_NAME="arm64" ;;
  x86_64|amd64) ARCH_NAME="amd64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [[ -x "${BIN_PATH}" ]] && \
  "${BIN_PATH}" --version 2>/dev/null | grep -q "${POCKETBASE_VERSION}"; then
  echo "PocketBase ${POCKETBASE_VERSION} is already installed."
  exit 0
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

ARCHIVE="pocketbase_${POCKETBASE_VERSION}_${OS_NAME}_${ARCH_NAME}.zip"
BASE_URL="https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}"

curl -fsSL "${BASE_URL}/${ARCHIVE}" -o "${TEMP_DIR}/${ARCHIVE}"
curl -fsSL "${BASE_URL}/checksums.txt" -o "${TEMP_DIR}/checksums.txt"

EXPECTED_CHECKSUM="$(grep "  ${ARCHIVE}$" "${TEMP_DIR}/checksums.txt")"
if [[ -z "${EXPECTED_CHECKSUM}" ]]; then
  echo "Checksum for ${ARCHIVE} was not found." >&2
  exit 1
fi

printf '%s\n' "${EXPECTED_CHECKSUM}" > "${TEMP_DIR}/selected_checksum.txt"
(
  cd "${TEMP_DIR}"
  shasum -a 256 -c selected_checksum.txt
)

mkdir -p "${BIN_DIR}"
unzip -oq "${TEMP_DIR}/${ARCHIVE}" pocketbase -d "${BIN_DIR}"
chmod +x "${BIN_PATH}"

"${BIN_PATH}" --version
