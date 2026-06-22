# Prerequisites and Validation

Use this document before LAB-01.

## Goal

Make sure the trainee laptop is ready before the guided project starts.

## Required Tools

- Docker Engine with the Docker Compose v2 plugin
- Git
- Node.js 24 LTS or later
- npm
- curl

## Supported Install Paths

Use one of the paths below.

The goal is not to teach package management in this project.
The goal is to get to a known-good workstation state quickly and verify it with one script.

### macOS and Windows

Use:

1. Docker Desktop
2. Git
3. Node.js 24 LTS

Suggested steps:

1. Install Docker Desktop from the official Docker site.
2. Start Docker Desktop and wait until it reports that Docker is running.
3. Install Git from the official Git site if it is not already available.
4. Install Node.js 24 LTS from the official Node.js site.
5. Open a new terminal after installation.

### Ubuntu or other Linux distributions

Use:

1. Docker Engine
2. Docker Compose v2 plugin
3. Git
4. curl
5. Node.js 24 LTS

Recommended Ubuntu steps:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git
```

Install Docker Engine and Compose plugin:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"
```

Install Node.js 24 LTS:

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
```

After adding your Linux user to the `docker` group, open a new terminal or SSH session before running the validation script.

### Training VM Path

If you are preparing the Ubuntu VM used later in the course, use the project setup script instead of doing the Docker steps manually:

```bash
bash deploy/vm-setup.sh /opt/devops-guided-project
```

That script:

- installs Docker if needed
- installs `git`, `jq`, and Node.js 24 LTS if needed
- enables the Docker service
- prepares the project directory
- creates log directories
- adds the current user to the `docker` group

## Preflight Commands

Run:

```bash
docker --version
docker compose version
docker ps
git --version
node --version
npm --version
curl --version
```

What good looks like:

- Docker is installed
- Docker Compose v2 is available
- Docker daemon is reachable
- Git is installed
- Node and npm are installed
- curl is installed

Expected versions:

- Docker: any recent stable version is fine
- Docker Compose: v2
- Node.js: `v24.x` or later
- npm: installed with Node.js
- Git: any recent stable version is fine

## Validation Script

Run:

```bash
bash scripts/validate-prerequisites.sh
```

This script checks:

- Docker
- Docker Compose
- Docker daemon reachability
- Git
- Node
- npm
- curl

It also checks that the installed Node.js major version is `24` or later, because the app and test flow are written against that baseline.

If the script passes, the workstation is ready for LAB-01.

## If Something Fails

- if `docker compose version` fails, install Docker Compose v2 or Docker Desktop
- if `docker ps` fails, start Docker Desktop or the Docker service
- on Linux, if Docker is running but `docker ps` still fails, add your user to the `docker` group and start a new shell
- on Linux, if Docker starts working only after `deploy/vm-setup.sh`, reconnect your SSH session before rerunning the script
- if `node --version` fails, install Node.js 24 LTS or later
- if `node --version` shows `v22.x` or older, upgrade to Node.js 24 LTS before continuing
- if `curl --version` fails, install curl
- if `npm --version` fails but `node --version` works, reinstall Node.js 24 LTS cleanly

## Why These Tools Matter Here

- Docker runs the full stack locally and on the VM
- Docker Compose starts the multi-container system in one command
- Git is used for source control and GitHub Actions
- Node.js and npm are used for the app tests and local app tooling
- curl is used in milestone validation and deployment smoke tests

Do not continue to LAB-01 until the prerequisite script passes.

## Next Step

Move to [LAB-00 Course Map](../labs/LAB-00-course-map.md).
