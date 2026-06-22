#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC_DIR="${PROJECT_DIR}/docs"
EXIT_CODE=0

DOC_ORDER=(
  "00-documentation-guide.md"
  "01-prerequisites-and-validation.md"
  "02-architecture.md"
  "03-runtime-stack.md"
  "04-app-gui.md"
  "05-request-and-data-flow.md"
  "06-logging.md"
  "07-monitoring.md"
  "08-registries.md"
  "09-secrets-and-azure-key-vault.md"
  "10-vm-deployment.md"
  "11-troubleshooting.md"
  "12-trainee-validation-findings.md"
  "13-trainee-gap-map.md"
)

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  EXIT_CODE=1
}

check_file() {
  local file="$1"
  if [[ -f "${DOC_DIR}/${file}" ]]; then
    pass "Found ${file}"
  else
    fail "Missing ${file}"
  fi
}

check_link() {
  local file="$1"
  local target="$2"
  if grep -Fq "${target}" "${file}"; then
    pass "$(basename "${file}") references ${target}"
  else
    fail "$(basename "${file}") does not reference ${target}"
  fi
}

echo "Validating documentation journey..."

for file in "${DOC_ORDER[@]}"; do
  check_file "${file}"
done

actual_doc_count="$(find "${DOC_DIR}" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
expected_doc_count="${#DOC_ORDER[@]}"

if [[ "${actual_doc_count}" == "${expected_doc_count}" ]]; then
  pass "Documentation directory contains the expected number of ordered markdown files."
else
  fail "Expected ${expected_doc_count} ordered docs, found ${actual_doc_count}."
fi

check_link "${PROJECT_DIR}/README.md" "docs/00-documentation-guide.md"
check_link "${PROJECT_DIR}/README.md" "docs/02-architecture.md"
check_link "${DOC_DIR}/00-documentation-guide.md" "01-prerequisites-and-validation.md"
check_link "${DOC_DIR}/00-documentation-guide.md" "02-architecture.md"
check_link "${DOC_DIR}/02-architecture.md" "03-runtime-stack.md"
check_link "${DOC_DIR}/05-request-and-data-flow.md" "06-logging.md"
check_link "${DOC_DIR}/08-registries.md" "09-secrets-and-azure-key-vault.md"
check_link "${DOC_DIR}/09-secrets-and-azure-key-vault.md" "10-vm-deployment.md"
check_link "${DOC_DIR}/10-vm-deployment.md" "11-troubleshooting.md"

if [[ "${EXIT_CODE}" -eq 0 ]]; then
  echo "Documentation journey validation completed successfully."
else
  echo "Documentation journey validation found one or more problems."
fi

exit "${EXIT_CODE}"
