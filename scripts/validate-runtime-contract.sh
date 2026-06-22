#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-local}"
BASE_URL="${2:-}"
EXIT_CODE=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
}

relative_path() {
  local path="$1"
  printf '%s\n' "${path#"${PROJECT_DIR}/"}"
}

check_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    pass "Found $(relative_path "${path}")"
  else
    fail "Missing $(relative_path "${path}")"
  fi
}

check_dir() {
  local path="$1"
  if [[ -d "${path}" ]]; then
    pass "Found $(relative_path "${path}")"
  else
    fail "Missing $(relative_path "${path}")"
  fi
}

check_env_key() {
  local file="$1"
  local key="$2"
  if grep -Eq "^${key}=" "${file}"; then
    pass "$(basename "${file}") defines ${key}"
  else
    fail "$(basename "${file}") does not define ${key}"
  fi
}

check_port_mapping() {
  local file="$1"
  local mapping="$2"
  if grep -Fq "\"${mapping}\"" "${file}"; then
    pass "$(basename "${file}") includes port mapping ${mapping}"
  else
    fail "$(basename "${file}") is missing port mapping ${mapping}"
  fi
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

validate_endpoints() {
  local base_url="$1"
  local health_json ready_json version_json

  health_json="$(curl -fsS "${base_url}/health")" || {
    fail "GET /health failed at ${base_url}. Start the matching stack before rerunning this validator."
    health_json=""
  }
  ready_json="$(curl -fsS "${base_url}/ready")" || {
    fail "GET /ready failed at ${base_url}. Start the matching stack before rerunning this validator."
    ready_json=""
  }
  version_json="$(curl -fsS "${base_url}/version")" || {
    fail "GET /version failed at ${base_url}. Start the matching stack before rerunning this validator."
    version_json=""
  }

  if [[ -n "${health_json}" ]]; then
    if require_json_key "${health_json}" "status"; then
      pass "GET /health returned status JSON."
    else
      fail "GET /health response is missing the status field."
    fi
  fi

  if [[ -n "${ready_json}" ]]; then
    if require_json_key "${ready_json}" "db_ready" && require_json_key "${ready_json}" "redis_ready"; then
      pass "GET /ready returned dependency readiness JSON."
    else
      fail "GET /ready response is missing db_ready or redis_ready."
    fi
  fi

  if [[ -n "${version_json}" ]]; then
    if require_json_key "${version_json}" "app_version" && require_json_key "${version_json}" "image_tag" && require_json_key "${version_json}" "environment"; then
      pass "GET /version returned deployment metadata JSON."
    else
      fail "GET /version response is missing required metadata."
    fi
  fi
}

echo "Validating runtime contract for mode: ${MODE}"

case "${MODE}" in
  static)
    check_file "${PROJECT_DIR}/.env.example"
    check_file "${PROJECT_DIR}/deploy/example.env"
    check_file "${PROJECT_DIR}/deploy/example.secrets.env"
    check_env_key "${PROJECT_DIR}/.env.example" "APP_NAME"
    check_env_key "${PROJECT_DIR}/.env.example" "APP_ENV"
    check_env_key "${PROJECT_DIR}/.env.example" "POSTGRES_PASSWORD"
    check_env_key "${PROJECT_DIR}/.env.example" "GRAFANA_ADMIN_PASSWORD"
    check_env_key "${PROJECT_DIR}/deploy/example.env" "APP_IMAGE"
    check_env_key "${PROJECT_DIR}/deploy/example.env" "IMAGE_TAG"
    check_env_key "${PROJECT_DIR}/deploy/example.env" "POSTGRES_DB"
    check_env_key "${PROJECT_DIR}/deploy/example.env" "REDIS_HOST"
    check_env_key "${PROJECT_DIR}/deploy/example.secrets.env" "POSTGRES_PASSWORD"
    check_env_key "${PROJECT_DIR}/deploy/example.secrets.env" "GRAFANA_ADMIN_PASSWORD"
    check_file "${PROJECT_DIR}/docker-compose.yml"
    check_file "${PROJECT_DIR}/docker-compose.vm.yml"
    check_port_mapping "${PROJECT_DIR}/docker-compose.yml" "8080:80"
    check_port_mapping "${PROJECT_DIR}/docker-compose.yml" "3000:3000"
    check_port_mapping "${PROJECT_DIR}/docker-compose.yml" "9090:9090"
    check_port_mapping "${PROJECT_DIR}/docker-compose.vm.yml" "80:80"
    check_port_mapping "${PROJECT_DIR}/docker-compose.vm.yml" "127.0.0.1:3000:3000"
    check_port_mapping "${PROJECT_DIR}/docker-compose.vm.yml" "127.0.0.1:9090:9090"
    ;;
  local)
    [[ -n "${BASE_URL}" ]] || BASE_URL="http://localhost:8080"
    check_file "${PROJECT_DIR}/.env"
    check_env_key "${PROJECT_DIR}/.env" "APP_NAME"
    check_env_key "${PROJECT_DIR}/.env" "APP_ENV"
    check_env_key "${PROJECT_DIR}/.env" "PORT"
    check_env_key "${PROJECT_DIR}/.env" "POSTGRES_DB"
    check_env_key "${PROJECT_DIR}/.env" "POSTGRES_USER"
    check_env_key "${PROJECT_DIR}/.env" "POSTGRES_PASSWORD"
    check_env_key "${PROJECT_DIR}/.env" "REDIS_HOST"
    check_env_key "${PROJECT_DIR}/.env" "GRAFANA_ADMIN_USER"
    check_file "${PROJECT_DIR}/docker-compose.yml"
    check_port_mapping "${PROJECT_DIR}/docker-compose.yml" "8080:80"
    check_port_mapping "${PROJECT_DIR}/docker-compose.yml" "3000:3000"
    check_port_mapping "${PROJECT_DIR}/docker-compose.yml" "9090:9090"
    ;;
  vm)
    [[ -n "${BASE_URL}" ]] || BASE_URL="http://127.0.0.1"
    check_file "${PROJECT_DIR}/.env"
    check_file "${PROJECT_DIR}/.env.secrets"
    check_env_key "${PROJECT_DIR}/.env" "APP_IMAGE"
    check_env_key "${PROJECT_DIR}/.env" "IMAGE_TAG"
    check_env_key "${PROJECT_DIR}/.env" "POSTGRES_DB"
    check_env_key "${PROJECT_DIR}/.env" "POSTGRES_USER"
    check_env_key "${PROJECT_DIR}/.env" "REDIS_HOST"
    check_env_key "${PROJECT_DIR}/.env.secrets" "POSTGRES_PASSWORD"
    check_env_key "${PROJECT_DIR}/.env.secrets" "GRAFANA_ADMIN_PASSWORD"
    check_file "${PROJECT_DIR}/docker-compose.vm.yml"
    check_port_mapping "${PROJECT_DIR}/docker-compose.vm.yml" "80:80"
    check_port_mapping "${PROJECT_DIR}/docker-compose.vm.yml" "127.0.0.1:3000:3000"
    check_port_mapping "${PROJECT_DIR}/docker-compose.vm.yml" "127.0.0.1:9090:9090"
    ;;
  *)
    fail "Unsupported mode: ${MODE}. Use static, local, or vm."
    exit "${EXIT_CODE}"
    ;;
esac

check_dir "${PROJECT_DIR}/logs/app"
check_dir "${PROJECT_DIR}/logs/nginx"

if [[ "${MODE}" != "static" ]]; then
  check_file "${PROJECT_DIR}/logs/nginx/access.log"
  check_file "${PROJECT_DIR}/logs/nginx/error.log"
  validate_endpoints "${BASE_URL}"
fi

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "Runtime contract validation completed successfully."
else
  echo "Runtime contract validation found one or more problems."
fi

exit "${EXIT_CODE}"
