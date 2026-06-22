#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_URL="${1:-http://localhost:8080}"
GRAFANA_URL="${2:-http://localhost:3000}"
PROMETHEUS_URL="${3:-http://localhost:9090}"
METRICS_QUERY='http_requests_total'
EXIT_CODE=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
}

echo "Validating observability milestone..."

if curl -fsS "${PROMETHEUS_URL}/-/ready" >/dev/null; then
  pass "Prometheus readiness endpoint is reachable."
else
  fail "Prometheus readiness endpoint is not reachable."
  echo "Start the local stack first, then rerun this script."
  exit "${EXIT_CODE}"
fi

if curl -fsS "${GRAFANA_URL}/api/health" >/dev/null; then
  pass "Grafana health endpoint is reachable."
else
  fail "Grafana health endpoint is not reachable."
  echo "Start the local stack first, then rerun this script."
  exit "${EXIT_CODE}"
fi

if grep -Fq 'TODO_APP_PORT' "${PROJECT_DIR}/monitoring/prometheus/prometheus.yml"; then
  fail "Prometheus scrape target still contains the OBS-01 placeholder."
fi

if grep -Fq 'TODO-app-log-path.log' "${PROJECT_DIR}/monitoring/promtail/promtail-config.yml"; then
  fail "Promtail app log path still contains the OBS-02 placeholder."
fi

if grep -Fq 'http://TODO-loki:3100' "${PROJECT_DIR}/monitoring/grafana/provisioning/datasources/datasources.yml"; then
  fail "Grafana Loki datasource still contains the OBS-03 placeholder."
fi

curl -fsS "${APP_URL}/health" >/dev/null || {
  fail "Could not generate /health traffic."
  echo "Confirm the app is reachable at ${APP_URL} before validating observability."
  exit "${EXIT_CODE}"
}

curl -fsS "${APP_URL}/slow" >/dev/null || {
  fail "Could not generate /slow traffic."
  echo "Confirm the app is reachable at ${APP_URL} before validating observability."
  exit "${EXIT_CODE}"
}
curl -sS "${APP_URL}/error" >/dev/null || true

if [[ -s "${PROJECT_DIR}/logs/app/app.log" ]]; then
  pass "App log file exists and is not empty."
else
  fail "App log file is missing or empty."
fi

if [[ -s "${PROJECT_DIR}/logs/nginx/access.log" ]]; then
  pass "Nginx access log exists and is not empty."
else
  fail "Nginx access log is missing or empty."
fi

if [[ -f "${PROJECT_DIR}/logs/nginx/error.log" ]]; then
  pass "Nginx error log file exists."
else
  fail "Nginx error log file is missing."
fi

if grep -q '"message":"request started"' "${PROJECT_DIR}/logs/app/app.log"; then
  pass "App logs include request start events."
else
  fail "App logs do not include request start events."
fi

if grep -q '"message":"request completed"' "${PROJECT_DIR}/logs/app/app.log"; then
  pass "App logs include request completion events."
else
  fail "App logs do not include request completion events."
fi

if grep -q '"message":"request failed"' "${PROJECT_DIR}/logs/app/app.log"; then
  pass "App logs include error request events."
else
  fail "App logs do not include request failure events."
fi

if grep -q '/slow' "${PROJECT_DIR}/logs/nginx/access.log"; then
  pass "Nginx access logs captured /slow traffic."
else
  fail "Nginx access logs did not capture /slow traffic."
fi

if grep -q '/error' "${PROJECT_DIR}/logs/nginx/access.log"; then
  pass "Nginx access logs captured /error traffic."
else
  fail "Nginx access logs did not capture /error traffic."
fi

if curl -fsS "${PROMETHEUS_URL}/api/v1/query?query=${METRICS_QUERY}" | grep -q "\"${METRICS_QUERY}\""; then
  pass "Prometheus can query app request metrics."
else
  fail "Prometheus could not query the expected app request metrics."
fi

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "Observability milestone validation completed successfully."
else
  echo "Observability milestone validation found one or more problems."
fi

exit "${EXIT_CODE}"
