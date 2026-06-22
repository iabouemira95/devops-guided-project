#!/usr/bin/env bash
set -Eeuo pipefail

EXIT_CODE=0
MIN_NODE_MAJOR=24

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
}

node_major_version() {
  node -p 'process.versions.node.split(".")[0]' 2>/dev/null
}

check_command() {
  local name="$1"
  if command -v "${name}" >/dev/null 2>&1; then
    pass "Found ${name}: $(command -v "${name}")"
  else
    fail "Missing required command: ${name}"
  fi
}

detect_compose() {
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

echo "Checking guided-project prerequisites..."

check_command git
check_command curl
check_command docker
check_command node
check_command npm

if COMPOSE_CMD="$(detect_compose)"; then
  pass "Docker Compose is available via: ${COMPOSE_CMD}"
else
  fail "Docker Compose v2 plugin is not available."
fi

if docker ps >/dev/null 2>&1; then
  pass "Docker daemon is reachable."
else
  fail "Docker daemon is not reachable. Start Docker Desktop or the Docker service."
  if [[ "$(uname -s)" == "Linux" ]]; then
    echo "       Linux hint: if Docker is running but access still fails, add your user to the docker group,"
    echo "       start a new shell or SSH session, and rerun this script."
  fi
fi

if node --version >/dev/null 2>&1; then
  NODE_VERSION="$(node --version)"
  NODE_MAJOR="$(node_major_version || true)"

  if [[ -n "${NODE_MAJOR}" && "${NODE_MAJOR}" -ge "${MIN_NODE_MAJOR}" ]]; then
    pass "Node.js version: ${NODE_VERSION}"
  else
    fail "Node.js version is ${NODE_VERSION}. Install Node.js ${MIN_NODE_MAJOR} or later."
  fi
fi

if npm --version >/dev/null 2>&1; then
  pass "npm version: $(npm --version)"
fi

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "Prerequisite validation completed successfully."
else
  echo "Prerequisite validation found one or more problems."
  echo "Fix the failed items before starting LAB-01."
fi

exit "${EXIT_CODE}"
