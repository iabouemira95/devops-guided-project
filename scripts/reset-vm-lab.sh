#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.vm.yml"
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

  printf 'This will stop the VM lab stack, remove its project volume, and clear project log files in %s. Continue? [y/N] ' "${PROJECT_DIR}"
  read -r answer
  [[ "${answer}" == "y" || "${answer}" == "Y" ]]
}

ensure_vm_project_root() {
  [[ -f "${COMPOSE_FILE}" ]] || fail "Could not find ${COMPOSE_FILE}."
  [[ "${PROJECT_DIR}" == *"devops-guided-project" ]] || fail "Refusing to run outside the guided-project directory."
}

clear_logs() {
  find "${APP_LOG_DIR}" -maxdepth 1 -type f -name '*.log' -delete
  : > "${NGINX_LOG_DIR}/access.log"
  : > "${NGINX_LOG_DIR}/error.log"
  pass "Cleared VM project log files."
}

section "VM Lab Reset"
ensure_vm_project_root

info "Project directory: ${PROJECT_DIR}"
info "Compose file: ${COMPOSE_FILE}"
info "This reset only touches the guided-project VM stack in the current project directory."

if ! confirm_reset; then
  info "Reset cancelled."
  exit 0
fi

section "Stopping VM Stack"
docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans
pass "VM stack stopped and project volume removed."

section "Clearing Project Logs"
mkdir -p "${APP_LOG_DIR}" "${NGINX_LOG_DIR}"
clear_logs

section "Reset Complete"
info "Safe retry path:"
info "1. confirm .env and .env.secrets are present"
info "2. bash deploy/deploy.sh <image-tag>"
info "3. bash scripts/validate-vm-deployment.sh http://127.0.0.1"
