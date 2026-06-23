#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${1:-http://localhost:8080}"
EXIT_CODE=0
CREATED_ITEM_NAME=""
HTML_RESPONSE=""

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

request_text() {
  local path="$1"
  local headers_file body_file status_code request_id

  headers_file="$(mktemp)"
  body_file="$(mktemp)"

  status_code="$(
    curl -sS \
      -D "${headers_file}" \
      -o "${body_file}" \
      -w '%{http_code}' \
      "${BASE_URL}${path}"
  )"

  request_id="$(
    awk 'BEGIN {IGNORECASE=1} /^X-Request-Id:/ {gsub("\r", "", $2); print $2}' "${headers_file}" | tail -n 1
  )"

  RESPONSE_STATUS="${status_code}"
  HTML_RESPONSE="$(cat "${body_file}")"
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
    && json_has_key "${RESPONSE_BODY}" "environment" \
    && json_equals "${RESPONSE_BODY}" '.simulation_profile' 'library-circulation' \
    && jq -e '.supported_services | length >= 2' >/dev/null <<<"${RESPONSE_BODY}"; then
    pass "GET /api returned service metadata and simulation context."
  else
    fail "GET /api response is missing expected metadata or simulation keys."
  fi
}

validate_homepage() {
  request_text /

  if [[ "${RESPONSE_STATUS}" == "200" ]]; then
    pass "GET / returned the GUI shell."
  else
    fail "GET / returned HTTP ${RESPONSE_STATUS}."
    return
  fi

  if grep -q "Library Operations Control Panel" <<<"${HTML_RESPONSE}" \
    && grep -q "Live Request Tracker" <<<"${HTML_RESPONSE}" \
    && grep -q "Recent Request Trail" <<<"${HTML_RESPONSE}" \
    && grep -q "Check Health" <<<"${HTML_RESPONSE}" \
    && grep -q "Generate Error" <<<"${HTML_RESPONSE}"; then
    pass "GET / includes the expected GUI sections and action buttons."
  else
    fail "GET / is missing one or more expected GUI sections or buttons."
  fi

  request_text /static/app.js
  if [[ "${RESPONSE_STATUS}" == "200" ]] && grep -q "renderLiveRequestState" <<<"${HTML_RESPONSE}"; then
    pass "GET /static/app.js served the GUI behavior bundle."
  else
    fail "GET /static/app.js is missing or does not contain the expected GUI behavior."
  fi

  request_text /static/styles.css
  if [[ "${RESPONSE_STATUS}" == "200" ]] && grep -q ".status-grid" <<<"${HTML_RESPONSE}"; then
    pass "GET /static/styles.css served the expected GUI styling."
  else
    fail "GET /static/styles.css is missing or does not contain the expected GUI styling."
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
    && json_has_key "${RESPONSE_BODY}" "prometheus_url" \
    && jq -e '.observability_mode == "local-direct" or .observability_mode == "ssh-tunnel" or .observability_mode == "explicit-public-links"' >/dev/null <<<"${RESPONSE_BODY}"; then
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
    && json_has_key "${RESPONSE_BODY}" "summary" \
    && json_number_ge "${RESPONSE_BODY}" '.count' 1 \
    && jq -e '.items[0].book_title and .items[0].borrower_name and .summary.by_status and .summary.by_workflow_area' >/dev/null <<<"${RESPONSE_BODY}"; then
    pass "GET /items returned PostgreSQL-backed library records with circulation summary fields."
  else
    fail "GET /items response did not confirm the richer PostgreSQL-backed library dataset."
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
    && json_has_key "${RESPONSE_BODY}" "summary" \
    && json_has_key "${RESPONSE_BODY}" "recent_items" \
    && json_equals "${RESPONSE_BODY}" '.item.name' "${CREATED_ITEM_NAME}" \
    && jq -e '.item.book_title and .item.borrower_name and .item.workflow_area' >/dev/null <<<"${RESPONSE_BODY}"; then
    pass "POST /items created the requested simulated library circulation record."
  else
    fail "POST /items response did not confirm the richer created-record payload."
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

  if [[ "${RESPONSE_STATUS}" == "501" ]]; then
    pass "GET /cache-demo returned the intentional APP-01 training gap response."
  else
    fail "GET /cache-demo returned HTTP ${RESPONSE_STATUS} instead of the expected APP-01 gap response."
    return
  fi

  assert_request_id "GET /cache-demo"

  if json_has_key "${RESPONSE_BODY}" "error" \
    && jq -e '.error | test("APP-01")' >/dev/null <<<"${RESPONSE_BODY}"; then
    pass "GET /cache-demo clearly explains the APP-01 trainee gap."
  else
    fail "GET /cache-demo did not describe the APP-01 trainee gap clearly."
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

  if json_has_key "${RESPONSE_BODY}" "error" \
    && json_has_key "${RESPONSE_BODY}" "request_id" \
    && json_equals "${RESPONSE_BODY}" '.request_id' "${RESPONSE_REQUEST_ID}"; then
    pass "GET /error returned structured error JSON."
  else
    fail "GET /error response is missing structured error fields."
  fi
}

echo "Deeply validating GUI-backed request flows at ${BASE_URL}..."

require_jq
validate_homepage
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
