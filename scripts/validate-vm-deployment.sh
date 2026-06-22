#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${1:-http://127.0.0.1}"
EXIT_CODE=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
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

echo "Validating deployed target stack at ${BASE_URL}..."

health_json="$(curl -fsS "${BASE_URL}/health")" || {
  fail "GET /health failed."
  health_json=""
}

if [[ -n "${health_json}" ]] && require_json_key "${health_json}" "status"; then
  pass "GET /health returned health JSON."
else
  fail "GET /health response did not contain the expected status field."
fi

ready_json="$(curl -fsS "${BASE_URL}/ready")" || {
  fail "GET /ready failed."
  ready_json=""
}

if [[ -n "${ready_json}" ]] \
  && require_json_key "${ready_json}" "db_ready" \
  && require_json_key "${ready_json}" "redis_ready"; then
  pass "GET /ready returned dependency readiness JSON."
else
  fail "GET /ready response did not contain db_ready and redis_ready."
fi

version_json="$(curl -fsS "${BASE_URL}/version")" || {
  fail "GET /version failed."
  version_json=""
}

if [[ -n "${version_json}" ]] \
  && require_json_key "${version_json}" "app_version" \
  && require_json_key "${version_json}" "git_sha" \
  && require_json_key "${version_json}" "image_tag" \
  && require_json_key "${version_json}" "environment"; then
  pass "GET /version returned deployment metadata."
else
  fail "GET /version response did not contain the expected deployment metadata keys."
fi

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "Target deployment validation completed successfully."
else
  echo "Target deployment validation found one or more problems."
fi

exit "${EXIT_CODE}"
