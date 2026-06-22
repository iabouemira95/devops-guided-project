#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_REPO="devops-guided-project"
TARGET="${1:-}"

if [[ -z "${TARGET}" ]]; then
  echo "Usage: bash scripts/bootstrap-github.sh OWNER/REPO"
  echo "Example: bash scripts/bootstrap-github.sh your-org/${DEFAULT_REPO}"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Missing GitHub CLI. Install gh first."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run: gh auth login -h github.com"
  exit 1
fi

cd "${PROJECT_DIR}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This project is not inside a git repository."
  exit 1
fi

if ! gh repo view "${TARGET}" >/dev/null 2>&1; then
  echo "Creating GitHub repository ${TARGET}..."
  gh repo create "${TARGET}" --private --source=. --remote=origin --push
else
  echo "GitHub repository ${TARGET} already exists."

  if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo set-default "${TARGET}"
    git remote add origin "git@github.com:${TARGET}.git"
  fi

  echo "Pushing local main branch..."
  git push -u origin main
fi

set_secret_if_present() {
  local key="$1"
  local value="${!key:-}"

  if [[ -n "${value}" ]]; then
    printf '%s' "${value}" | gh secret set "${key}" --repo "${TARGET}" --body -
    echo "Set GitHub secret: ${key}"
  else
    echo "Skipped GitHub secret: ${key} (not set in local environment)"
  fi
}

set_secret_from_file_if_present() {
  local key="$1"
  local file_path="${2:-}"

  if [[ -n "${file_path}" && -f "${file_path}" ]]; then
    gh secret set "${key}" --repo "${TARGET}" < "${file_path}"
    echo "Set GitHub secret from file: ${key}"
  else
    echo "Skipped GitHub secret: ${key} (source file not provided)"
  fi
}

echo
echo "Setting GitHub Actions secrets when values are available..."

for key in \
  VM_HOST \
  VM_USER \
  VM_APP_DIR \
  POSTGRES_PASSWORD \
  GRAFANA_ADMIN_PASSWORD \
  REGISTRY_HOST \
  REGISTRY_USERNAME \
  REGISTRY_PASSWORD \
  AWS_ACCESS_KEY_ID \
  AWS_SECRET_ACCESS_KEY \
  AWS_SESSION_TOKEN \
  AWS_REGION \
  AZURE_CLIENT_ID \
  AZURE_TENANT_ID \
  AZURE_SUBSCRIPTION_ID \
  AZURE_KEYVAULT_NAME; do
  set_secret_if_present "${key}"
done

if [[ -n "${VM_SSH_KEY:-}" ]]; then
  printf '%s' "${VM_SSH_KEY}" | gh secret set VM_SSH_KEY --repo "${TARGET}" --body -
  printf '%s' "${VM_SSH_KEY}" | base64 | tr -d '\n' | gh secret set VM_SSH_KEY_B64 --repo "${TARGET}" --body -
  echo "Set GitHub secrets: VM_SSH_KEY and VM_SSH_KEY_B64"
elif [[ -n "${VM_SSH_KEY_FILE:-}" ]]; then
  set_secret_from_file_if_present "VM_SSH_KEY" "${VM_SSH_KEY_FILE}"
  base64 < "${VM_SSH_KEY_FILE}" | tr -d '\r\n' | gh secret set VM_SSH_KEY_B64 --repo "${TARGET}" --body -
  echo "Set GitHub secret from file: VM_SSH_KEY_B64"
else
  echo "Skipped GitHub secrets: VM_SSH_KEY and VM_SSH_KEY_B64 (not set in local environment)"
fi

echo
echo "GitHub bootstrap complete."
echo "Next steps:"
echo "1. Open https://github.com/${TARGET}/actions"
echo "2. Open a feature branch pull request and confirm PR CI passes."
echo "3. Merge to main and confirm Publish Image pushes the app image to your chosen container registry."
echo "4. Approve Deploy Production or run it manually with the image tag you want to validate."
echo "5. If the deploy workflow needs SSH authentication, prefer VM_SSH_KEY_B64 generated from the PEM file."
