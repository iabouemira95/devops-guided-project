#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${1:-http://localhost:8080}"
EXIT_CODE=0
CREATED_ITEM_NAME=""

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
}

require_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi

  fail "jq is required for deep GUI request validation."
  echo "Install jq first, then rerun this script."
  exit "${EXIT_CODE}"
}

json_has_key() {
  local json="$1"
  local key="$2"
  jq -e "has(\"${key}\")" >/dev/null <<<"${json}"
}

json_equals() {
  local json="$1"
  local expr="$2"
  local expected="$3"
  [[ "$(jq -r "${expr}" <<<"${json}")" == "${expected}" ]]
}

json_bool_true() {
  local json="$1"
  local expr="$2"
  [[ "$(jq -r "${expr}" <<<"${json}")" == "true" ]]
}

json_number_ge() {
  local json="$1"
  local expr="$2"
  local minimum="$3"
  awk "BEGIN {exit !($(jq -r "${expr}" <<<"${json}") >= ${minimum})}"
}

request() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local headers_file body_file status_code request_id

  headers_file="$(mktemp)"
  body_file="$(mktemp)"

  if [[ -n "${body}" ]]; then
    status_code="$(
      curl -sS -X "${method}" \
        -H "Content-Type: application/json" \
        -D "${headers_file}" \
        -o "${body_file}" \
        -w '%{http_code}' \
        "${BASE_URL}${path}" \
        --data "${body}"
    )"
  else
    status_code="$(
      curl -sS -X "${method}" \
        -D "${headers_file}" \
        -o "${body_file}" \
        -w '%{http_code}' \
        "${BASE_URL}${path}"
    )"
  fi

  request_id="$(
    awk 'BEGIN {IGNORECASE=1} /^X-Request-Id:/ {gsub("\r", "", $2); print $2}' "${headers_file}" | tail -n 1
  )"

  RESPONSE_STATUS="${status_code}"
  RESPONSE_BODY="$(cat "${body_file}")"
  RESPONSE_REQUEST_ID="${request_id}"

  rm -f "${headers_file}" "${body_file}"
}

assert_request_id() {
  local path="$1"

  if [[ -n "${RESPONSE_REQUEST_ID}" ]]; then
    pass "${path} returned X-Request-Id."
  else
    fail "${path} did not return X-Request-Id."
  fi
}

validate_api() {
  request GET /api

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /api returned HTTP 200."
  else
    fail "GET /api returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /api"

  if json_has_key "${RESPONSE_BODY}" "service_name" \
    && json_has_key "${RESPONSE_BODY}" "version" \
    && json_has_key "${RESPONSE_BODY}" "environment"; then
    pass "GET /api returned service metadata."
  else
    fail "GET /api response is missing expected metadata keys."
  fi
}

validate_ui_config() {
  request GET /ui-config

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /ui-config returned HTTP 200."
  else
    fail "GET /ui-config returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /ui-config"

  if json_has_key "${RESPONSE_BODY}" "observability_mode" \
    && json_has_key "${RESPONSE_BODY}" "hint" \
    && json_has_key "${RESPONSE_BODY}" "grafana_url" \
    && json_has_key "${RESPONSE_BODY}" "prometheus_url"; then
    pass "GET /ui-config returned observability shortcut metadata."
  else
    fail "GET /ui-config response is missing observability shortcut keys."
  fi
}

validate_health() {
  request GET /health

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /health returned HTTP 200."
  else
    fail "GET /health returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /health"

  if json_equals "${RESPONSE_BODY}" '.status' 'ok'; then
    pass "GET /health reported status ok."
  else
    fail "GET /health did not report status ok."
  fi
}

validate_ready() {
  request GET /ready

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /ready returned HTTP 200."
  else
    fail "GET /ready returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /ready"

  if json_bool_true "${RESPONSE_BODY}" '.db_ready' && json_bool_true "${RESPONSE_BODY}" '.redis_ready'; then
    pass "GET /ready confirmed PostgreSQL and Redis are ready."
  else
    fail "GET /ready did not confirm both PostgreSQL and Redis readiness."
  fi
}

validate_version() {
  request GET /version

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /version returned HTTP 200."
  else
    fail "GET /version returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /version"

  if json_has_key "${RESPONSE_BODY}" "app_version" \
    && json_has_key "${RESPONSE_BODY}" "git_sha" \
    && json_has_key "${RESPONSE_BODY}" "image_tag" \
    && json_has_key "${RESPONSE_BODY}" "environment"; then
    pass "GET /version returned deployment metadata."
  else
    fail "GET /version response is missing deployment metadata."
  fi
}

validate_get_items() {
  request GET /items

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /items returned HTTP 200."
  else
    fail "GET /items returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /items"

  if json_equals "${RESPONSE_BODY}" '.source' 'postgres' \
    && json_has_key "${RESPONSE_BODY}" "items" \
    && json_number_ge "${RESPONSE_BODY}" '.count' 1; then
    pass "GET /items returned PostgreSQL-backed items."
  else
    fail "GET /items response did not confirm PostgreSQL-backed items."
  fi
}

validate_create_item() {
  CREATED_ITEM_NAME="validation-item-$(date +%s)"
  request POST /items "{\"name\":\"${CREATED_ITEM_NAME}\"}"

  if [[ "${RESPONSE_STATUS}" == "201" ]]; then
    pass "POST /items returned HTTP 201."
  else
    fail "POST /items returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "POST /items"

  if json_has_key "${RESPONSE_BODY}" "item" \
    && json_equals "${RESPONSE_BODY}" '.item.name' "${CREATED_ITEM_NAME}"; then
    pass "POST /items created the requested item."
  else
    fail "POST /items response did not confirm the created item."
  fi
}

validate_created_item_visible() {
  request GET /items

  if [[ "${RESPONSE_STATUS}" != "200" ]]; then
    fail "GET /items after POST returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  if jq -e --arg item_name "${CREATED_ITEM_NAME}" '.items[] | select(.name == $item_name)' >/dev/null <<<"${RESPONSE_BODY}"; then
    pass "Created item is visible in a follow-up GET /items call."
  else
    fail "Created item was not visible in a follow-up GET /items call."
  fi
}

validate_cache_demo() {
  request GET /cache-demo

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "First GET /cache-demo returned HTTP 200."
  else
    fail "First GET /cache-demo returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "First GET /cache-demo"

  if json_has_key "${RESPONSE_BODY}" "source" && json_has_key "${RESPONSE_BODY}" "value"; then
    pass "First GET /cache-demo returned cache payload."
  else
    fail "First GET /cache-demo response is missing cache payload fields."
  fi

  request GET /cache-demo

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "Second GET /cache-demo returned HTTP 200."
  else
    fail "Second GET /cache-demo returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "Second GET /cache-demo"

  if json_equals "${RESPONSE_BODY}" '.source' 'redis-cache'; then
    pass "Second GET /cache-demo confirmed the Redis cache hit path."
  else
    fail "Second GET /cache-demo did not show a Redis cache hit."
  fi
}

validate_slow() {
  local start end elapsed
  start="$(date +%s)"
  request GET /slow
  end="$(date +%s)"
  elapsed="$((end - start))"

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET /slow returned HTTP 200."
  else
    fail "GET /slow returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  assert_request_id "GET /slow"

  if json_number_ge "${RESPONSE_BODY}" '.delay_ms' 2000; then
    pass "GET /slow reported an intentional delay."
  else
    fail "GET /slow response did not report the expected delay."
  fi

  if [[ "${elapsed}" -ge 2 ]]; then
    pass "GET /slow took at least two seconds end to end."
  else
    fail "GET /slow completed faster than expected."
  fi
}

validate_error() {
  request GET /error

  if [[ "${RESPONSE_STATUS}" == "500" ]]; then
    pass "GET /error returned HTTP 500 as expected."
  else
    fail "GET /error returned HTTP ${RESPONSE_STATUS} instead of 500."
    return
  fi

  assert_request_id "GET /error"

  if json_has_key "${RESPONSE_BODY}" "error" && json_has_key "${RESPONSE_BODY}" "request_id"; then
    pass "GET /error returned structured error JSON."
  else
    fail "GET /error response is missing structured error fields."
  fi
}

echo "Deeply validating GUI-backed request flows at ${BASE_URL}..."

require_jq
validate_api
validate_ui_config
validate_health
validate_ready
validate_version
validate_get_items
validate_create_item
validate_created_item_visible
validate_cache_demo
validate_slow
validate_error

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "GUI request validation completed successfully."
else
  echo "GUI request validation found one or more problems."
fi

exit "${EXIT_CODE}"
