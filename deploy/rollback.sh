#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TARGET_TAG="${1:-}"
CONFIRM_FLAG="${2:-}"

info() {
  printf '[INFO] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  exit 1
}

confirm_rollback() {
  if [[ "${CONFIRM_FLAG}" == "--yes" ]]; then
    return 0
  fi

  printf 'This will redeploy image tag "%s" using deploy/deploy.sh. Continue? [y/N] ' "${TARGET_TAG}"
  read -r answer
  [[ "${answer}" == "y" || "${answer}" == "Y" ]]
}

[[ -n "${TARGET_TAG}" ]] || fail "Usage: bash deploy/rollback.sh <known-image-tag> [--yes]"
[[ -f "${PROJECT_DIR}/deploy/deploy.sh" ]] || fail "Could not find deploy/deploy.sh."

info "Rollback helper"
info "Project directory: ${PROJECT_DIR}"
info "Target image tag: ${TARGET_TAG}"
info "This helper does not guess tags. It only redeploys the tag you provide."

if ! confirm_rollback; then
  info "Rollback cancelled."
  exit 0
fi

bash "${PROJECT_DIR}/deploy/deploy.sh" "${TARGET_TAG}"
