#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${1:-/opt/devops-guided-project}"

node_major_version() {
  node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true
}

echo "Preparing Ubuntu VM for the guided DevOps project..."
echo "Target project directory: ${APP_DIR}"

sudo apt-get update
sudo apt-get install -y ca-certificates curl git gnupg jq lsb-release

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker Engine and Docker Compose plugin..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! command -v node >/dev/null 2>&1 || [[ "$(node_major_version)" -lt 24 ]]; then
  echo "Installing Node.js 24 LTS for app tests and validation scripts..."
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

sudo systemctl enable docker
sudo systemctl start docker

if getent group docker >/dev/null 2>&1; then
  sudo usermod -aG docker "${USER}"
fi

sudo mkdir -p "${APP_DIR}"
sudo mkdir -p "${APP_DIR}/logs/app" "${APP_DIR}/logs/nginx"
sudo touch "${APP_DIR}/logs/nginx/access.log" "${APP_DIR}/logs/nginx/error.log"
sudo touch "${APP_DIR}/.env.secrets"
sudo chown -R "${USER}:${USER}" "${APP_DIR}"
chmod 600 "${APP_DIR}/.env.secrets"

echo
echo "Required VM ports for this training project:"
echo "- 22 for SSH"
echo "- 80 for the app through Nginx"
echo
echo "Training-only optional local services:"
echo "- 3000 Grafana: keep localhost only, use SSH tunnel"
echo "- 9090 Prometheus: keep localhost only if enabled"
echo "- Loki and Promtail should stay internal only"
echo
echo "Installed helper tools:"
echo "- git for repository operations"
echo "- jq for JSON-friendly validation output"
echo "- Node.js 24 LTS for app tests and project validation"
echo
echo "Docker access:"
echo "- ${USER} was added to the docker group if the group exists."
echo "- Start a new SSH session before using docker without sudo."
echo
echo "Example Grafana tunnel:"
echo "ssh -L 3000:localhost:3000 USER@VM_PUBLIC_IP"
