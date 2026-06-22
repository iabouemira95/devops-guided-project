#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_PATH="${1:-${PROJECT_DIR}/devops-guided-project-vm-source.tar.gz}"
PROJECT_NAME="$(basename "${PROJECT_DIR}")"

echo "Packaging ${PROJECT_NAME} for VM transfer..."
echo "Output archive: ${OUTPUT_PATH}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"

COPYFILE_DISABLE=1 tar \
  --exclude="${PROJECT_NAME}/.git" \
  --exclude="${PROJECT_NAME}/app/node_modules" \
  --exclude="${PROJECT_NAME}/logs/app/*.log" \
  --exclude="${PROJECT_NAME}/logs/nginx/*.log" \
  --exclude="${PROJECT_NAME}/._*" \
  --exclude="${PROJECT_NAME}/.DS_Store" \
  -czf "${OUTPUT_PATH}" \
  -C "$(dirname "${PROJECT_DIR}")" \
  "${PROJECT_NAME}"

echo "Archive created successfully."
echo "Next step:"
echo "scp ${OUTPUT_PATH} USER@VM:~/"
