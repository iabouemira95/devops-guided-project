#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
SECRETS_FILE="${PROJECT_DIR}/.env.secrets"
IMAGE_TAG_INPUT="${1:-}"

section() {
  printf '\n== %s ==\n' "$1"
}

info() {
  printf '[INFO] %s\n' "$1"
}

pass() {
  printf '[PASS] %s\n' "$1"
}

compose_ps() {
  docker compose -f docker-compose.vm.yml ps
}

sync_runtime_metadata_file() {
  local image_tag_value="$1"
  local git_sha_value="${2:-}"

  if grep -q '^IMAGE_TAG=' "${ENV_FILE}"; then
    sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=${image_tag_value}/" "${ENV_FILE}"
  else
    printf '\nIMAGE_TAG=%s\n' "${image_tag_value}" >> "${ENV_FILE}"
  fi

  if [[ -n "${git_sha_value}" ]]; then
    if grep -q '^GIT_SHA=' "${ENV_FILE}"; then
      sed -i "s/^GIT_SHA=.*/GIT_SHA=${git_sha_value}/" "${ENV_FILE}"
    else
      printf 'GIT_SHA=%s\n' "${git_sha_value}" >> "${ENV_FILE}"
    fi
  fi
}

show_post_deploy_summary() {
  local version_json health_json ready_json

  section "Post-Deploy Summary"
  info "Deployed image tag: ${IMAGE_TAG}"
  info "App image: ${APP_IMAGE}:${IMAGE_TAG}"

  version_json="$(curl -fsS http://127.0.0.1/version || true)"
  health_json="$(curl -fsS http://127.0.0.1/health || true)"
  ready_json="$(curl -fsS http://127.0.0.1/ready || true)"

  if [[ -n "${version_json}" ]]; then
    info "/version response:"
    printf '%s\n' "${version_json}"
  else
    info "/version response was not available."
  fi

  if [[ -n "${health_json}" ]]; then
    info "/health response:"
    printf '%s\n' "${health_json}"
  else
    info "/health response was not available."
  fi

  if [[ -n "${ready_json}" ]]; then
    info "/ready response:"
    printf '%s\n' "${ready_json}"
  else
    info "/ready response was not available."
  fi

  info "Running compose services:"
  compose_ps || true

  info "Where to check logs next:"
  info "- docker compose -f docker-compose.vm.yml logs app --tail=50"
  info "- docker compose -f docker-compose.vm.yml logs nginx --tail=50"
  info "- tail -f logs/app/app.log"
  info "- tail -f logs/nginx/access.log"
}

write_runtime_secrets_file() {
  local wrote_secret=0
  local registry_host_value="${REGISTRY_HOST:-${REGISTRY_LOGIN_SERVER:-}}"

  for key in POSTGRES_PASSWORD GRAFANA_ADMIN_PASSWORD REGISTRY_USERNAME REGISTRY_PASSWORD; do
    if [[ -n "${!key:-}" ]]; then
      if [[ "${wrote_secret}" -eq 0 ]]; then
        : > "${SECRETS_FILE}"
      fi
      printf '%s=%s\n' "${key}" "${!key}" >> "${SECRETS_FILE}"
      if [[ "${key}" == "GRAFANA_ADMIN_PASSWORD" ]]; then
        printf 'GF_SECURITY_ADMIN_PASSWORD=%s\n' "${!key}" >> "${SECRETS_FILE}"
      fi
      wrote_secret=1
    fi
  done

  if [[ -n "${registry_host_value}" ]]; then
    if [[ "${wrote_secret}" -eq 0 ]]; then
      : > "${SECRETS_FILE}"
    fi
    printf 'REGISTRY_HOST=%s\n' "${registry_host_value}" >> "${SECRETS_FILE}"
    wrote_secret=1
  fi

  if [[ -n "${GRAFANA_ADMIN_USER:-}" ]]; then
    if [[ "${wrote_secret}" -eq 0 ]]; then
      : > "${SECRETS_FILE}"
      wrote_secret=1
    fi
    printf 'GF_SECURITY_ADMIN_USER=%s\n' "${GRAFANA_ADMIN_USER}" >> "${SECRETS_FILE}"
  fi

  if [[ "${wrote_secret}" -eq 1 ]]; then
    chmod 600 "${SECRETS_FILE}"
    echo "Wrote runtime secrets to ${SECRETS_FILE}."
    return
  fi

  if [[ ! -f "${SECRETS_FILE}" ]]; then
    touch "${SECRETS_FILE}"
    chmod 600 "${SECRETS_FILE}"
  fi
}

load_registry_settings_from_secrets_file() {
  local key
  local value

  [[ -f "${SECRETS_FILE}" ]] || return 0

  while IFS='=' read -r key value; do
    case "${key}" in
      REGISTRY_HOST|REGISTRY_LOGIN_SERVER|REGISTRY_USERNAME|REGISTRY_PASSWORD)
        if [[ "${key}" == "REGISTRY_LOGIN_SERVER" ]]; then
          if [[ -z "${REGISTRY_HOST:-}" && -n "${value}" ]]; then
            export "REGISTRY_HOST=${value}"
          fi
        elif [[ -z "${!key:-}" && -n "${value}" ]]; then
          export "${key}=${value}"
        fi
        ;;
    esac
  done < "${SECRETS_FILE}"
}

validate_required_values() {
  local missing=0

  for required in APP_IMAGE IMAGE_TAG POSTGRES_DB POSTGRES_USER POSTGRES_HOST POSTGRES_PORT REDIS_HOST REDIS_PORT GRAFANA_ADMIN_USER; do
    if [[ -z "${!required:-}" ]]; then
      echo "Missing required value: ${required}"
      missing=1
    fi
  done

  for required_secret in POSTGRES_PASSWORD GRAFANA_ADMIN_PASSWORD; do
    if ! grep -q "^${required_secret}=" "${SECRETS_FILE}" 2>/dev/null && [[ -z "${!required_secret:-}" ]]; then
      echo "Missing required secret value: ${required_secret}"
      missing=1
    fi
  done

  if [[ "${APP_IMAGE:-}" == TODO-set-your-registry-host/* ]]; then
    echo "Training gap VM-01: replace APP_IMAGE in .env with your real registry image path."
    echo "Start from deploy/example.env, then update APP_IMAGE before running deploy/deploy.sh."
    missing=1
  fi

  if [[ "${missing}" -eq 1 ]]; then
    echo "Update ${ENV_FILE}, ${SECRETS_FILE}, or the calling environment and try again."
    exit 1
  fi
}

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy deploy/example.env or .env.example to .env first."
  exit 1
fi

write_runtime_secrets_file

set -a
source "${ENV_FILE}"
set +a

load_registry_settings_from_secrets_file

if [[ -n "${IMAGE_TAG_INPUT}" ]]; then
  export IMAGE_TAG="${IMAGE_TAG_INPUT}"
fi

DEPLOY_GIT_SHA=""
if [[ "${IMAGE_TAG}" == sha-* ]]; then
  DEPLOY_GIT_SHA="${IMAGE_TAG#sha-}"
fi

sync_runtime_metadata_file "${IMAGE_TAG}" "${DEPLOY_GIT_SHA}"

validate_required_values

section "Deploy"
info "Deploying ${APP_IMAGE}:${IMAGE_TAG}"

section "Host Directories"
info "Preparing writable log directories for the app and nginx..."
mkdir -p "${PROJECT_DIR}/logs/app" "${PROJECT_DIR}/logs/nginx"
chmod 0777 "${PROJECT_DIR}/logs/app" "${PROJECT_DIR}/logs/nginx"
pass "Log directories are ready."

if [[ -n "${REGISTRY_HOST:-}" && -n "${REGISTRY_USERNAME:-}" && -n "${REGISTRY_PASSWORD:-}" ]]; then
  info "Logging in to container registry ${REGISTRY_HOST}..."
  printf '%s' "${REGISTRY_PASSWORD}" | docker login "${REGISTRY_HOST}" --username "${REGISTRY_USERNAME}" --password-stdin
fi

cd "${PROJECT_DIR}"
docker compose -f docker-compose.vm.yml pull app
docker compose -f docker-compose.vm.yml up -d

section "Database Bootstrap"
info "Applying repeatable database bootstrap..."
docker compose -f docker-compose.vm.yml exec -T postgres \
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f /docker-entrypoint-initdb.d/init.sql
pass "Database bootstrap applied."

section "Smoke Tests"
info "Running health and readiness checks against http://127.0.0.1 ..."
for attempt in 1 2 3 4 5 6; do
  if curl -fsS http://127.0.0.1/health >/dev/null && curl -fsS http://127.0.0.1/ready >/dev/null; then
    pass "Deployment succeeded."
    show_post_deploy_summary
    exit 0
  fi
  info "Smoke test attempt ${attempt} failed. Waiting for services..."
  sleep 5
done

section "Deployment Failure"
info "Deployment smoke test failed. Showing recent logs..."
docker compose -f docker-compose.vm.yml logs app --tail=50 || true
docker compose -f docker-compose.vm.yml logs nginx --tail=50 || true
exit 1
