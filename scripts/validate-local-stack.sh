#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="foundation"
BASE_URL="http://localhost:8080"
EXIT_CODE=0

if [[ "${1:-}" == "foundation" || "${1:-}" == "full" ]]; then
  MODE="$1"
  BASE_URL="${2:-http://localhost:8080}"
elif [[ -n "${1:-}" ]]; then
  BASE_URL="$1"
fi

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
}

compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return 0
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
    return 0
  fi

  return 1
}

http_json() {
  local path="$1"
  curl -fsS "${BASE_URL}${path}"
}

require_json_key() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    jq -e "has(\"${key}\")" >/dev/null <<<"${json}"
  else
    grep -q "\"${key}\"" <<<"${json}"
  fi
}

echo "Validating local guided-project stack in ${MODE} mode at ${BASE_URL}..."

if COMPOSE_CMD="$(compose_cmd)"; then
  pass "Using Compose command: ${COMPOSE_CMD}"
  if ${COMPOSE_CMD} -f "${PROJECT_DIR}/docker-compose.yml" ps >/dev/null 2>&1; then
    pass "Compose services are inspectable."
  else
    fail "Compose services are not inspectable. Start the stack before running this check."
    echo "Run: cp .env.example .env && docker compose up --build"
    echo "Then rerun: bash scripts/validate-local-stack.sh"
    exit "${EXIT_CODE}"
  fi
else
  fail "Docker Compose is not available."
  echo "Fix prerequisites first with: bash scripts/validate-prerequisites.sh"
  exit "${EXIT_CODE}"
fi

health_json="$(http_json /health)" || {
  fail "GET /health did not succeed."
  echo "The local stack does not appear to be running at ${BASE_URL}."
  if grep -Fq 'TODO-start-script' "${PROJECT_DIR}/docker/app.Dockerfile"; then
    echo "If this is the trainee-facing version, complete guided gap DOCKER-01 first."
  fi
  echo "Start it with: docker compose up --build"
  health_json=""
  exit "${EXIT_CODE}"
}

if [[ -n "${health_json}" ]] && require_json_key "${health_json}" "status"; then
  pass "GET /health returned health JSON."
else
  fail "GET /health response did not contain the expected status field."
fi

ready_json="$(http_json /ready)" || {
  fail "GET /ready did not succeed."
  ready_json=""
}

if [[ -n "${ready_json}" ]] \
  && require_json_key "${ready_json}" "db_ready" \
  && require_json_key "${ready_json}" "redis_ready"; then
  pass "GET /ready returned dependency readiness JSON."
else
  fail "GET /ready response did not contain db_ready and redis_ready."
fi

version_json="$(http_json /version)" || {
  fail "GET /version did not succeed."
  version_json=""
}

if [[ -n "${version_json}" ]] \
  && require_json_key "${version_json}" "app_version" \
  && require_json_key "${version_json}" "git_sha" \
  && require_json_key "${version_json}" "image_tag"; then
  pass "GET /version returned deployment metadata."
else
  fail "GET /version response did not contain the expected metadata keys."
fi

items_json="$(http_json /items)" || {
  fail "GET /items did not succeed."
  items_json=""
}

if [[ -n "${items_json}" ]] \
  && require_json_key "${items_json}" "items" \
  && require_json_key "${items_json}" "summary"; then
  pass "GET /items returned PostgreSQL-backed data with summary fields."
else
  fail "GET /items response did not contain items and summary."
fi

if [[ "${MODE}" == "full" ]]; then
  cache_json="$(http_json /cache-demo)" || {
    fail "GET /cache-demo did not succeed."
    echo "If this is the trainee-facing version, complete guided gap APP-01 first."
    cache_json=""
  }

  if [[ -n "${cache_json}" ]] && require_json_key "${cache_json}" "source"; then
    pass "GET /cache-demo returned cache data."
  else
    fail "GET /cache-demo response did not contain source."
  fi
else
  echo "[INFO] Skipping GET /cache-demo in foundation mode."
  echo "[INFO] Use: bash scripts/validate-local-stack.sh full"
  echo "[INFO] Run the full mode after completing guided gap APP-01."
fi

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "Local stack validation completed successfully."
else
  echo "Local stack validation found one or more problems."
fi

exit "${EXIT_CODE}"
