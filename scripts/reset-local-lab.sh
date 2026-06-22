#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
APP_LOG_DIR="${PROJECT_DIR}/logs/app"
NGINX_LOG_DIR="${PROJECT_DIR}/logs/nginx"
CONFIRM_FLAG="${1:-}"

section() {
  printf '\n== %s ==\n' "$1"
}

info() {
  printf '[INFO] %s\n' "$1"
}

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  exit 1
}

confirm_reset() {
  if [[ "${CONFIRM_FLAG}" == "--yes" ]]; then
    return 0
  fi

  printf 'This will stop the local lab stack, remove its project volumes, and clear project log files. Continue? [y/N] '
  read -r answer
  [[ "${answer}" == "y" || "${answer}" == "Y" ]]
}

ensure_project_root() {
  [[ -f "${COMPOSE_FILE}" ]] || fail "Could not find ${COMPOSE_FILE}."
  [[ -d "${PROJECT_DIR}/app" ]] || fail "Could not find the app directory. Run this script from the project repository."
}

clear_logs() {
  find "${APP_LOG_DIR}" -maxdepth 1 -type f -name '*.log' -delete
  : > "${NGINX_LOG_DIR}/access.log"
  : > "${NGINX_LOG_DIR}/error.log"
  pass "Cleared project log files."
}

section "Local Lab Reset"
ensure_project_root

info "Project directory: ${PROJECT_DIR}"
info "Compose file: ${COMPOSE_FILE}"
info "This reset only touches the local guided-project stack and project log files."

if ! confirm_reset; then
  info "Reset cancelled."
  exit 0
fi

section "Stopping Local Stack"
docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans
pass "Local stack stopped and project volumes removed."

section "Clearing Project Logs"
mkdir -p "${APP_LOG_DIR}" "${NGINX_LOG_DIR}"
clear_logs

section "Reset Complete"
info "Safe retry path:"
info "1. cp .env.example .env"
info "2. docker compose up --build"
info "3. bash scripts/validate-local-stack.sh"
