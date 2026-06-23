#!/usr/bin/env bash
set -Eeuo pipefail

VM_HOST="${1:-${VM_HOST:-}}"
VM_USER="${2:-${VM_USER:-}}"
KEY_PATH="${3:-${VM_SSH_KEY_PATH:-}}"

if [[ -z "${VM_HOST}" || -z "${VM_USER}" ]]; then
  echo "Usage: bash scripts/print-vm-access.sh <vm-host> <vm-user> [ssh-key-path]"
  echo "You can also set VM_HOST, VM_USER, and optionally VM_SSH_KEY_PATH in the environment."
  exit 1
fi

echo "Public app URL:"
echo "  http://${VM_HOST}/"
echo
echo "SSH tunnel command for Grafana and Prometheus:"

if [[ -n "${KEY_PATH}" ]]; then
  echo "  ssh -i ${KEY_PATH} -L 3000:localhost:3000 -L 9090:localhost:9090 ${VM_USER}@${VM_HOST}"
else
  echo "  ssh -L 3000:localhost:3000 -L 9090:localhost:9090 ${VM_USER}@${VM_HOST}"
fi

echo
echo "After the tunnel is up, open:"
echo "  http://localhost:3000"
echo "  http://localhost:9090"
