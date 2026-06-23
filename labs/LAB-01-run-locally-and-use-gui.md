# LAB-01 Run Locally and Use GUI

## Goal

Start the local stack and use the GUI as the main traffic generator.

## Why This Lab Matters

Before students inspect logs, metrics, CI, or deployment, they need one stable way to interact with the system. The GUI gives them a simple operational entry point and a repeatable way to generate requests.

## Before You Start

Complete:

- [Prerequisites and Validation](../docs/01-prerequisites-and-validation.md)
- `bash scripts/validate-prerequisites.sh`

In the trainee-facing version, complete guided gap `DOCKER-01` from [Trainee Gap Map](../docs/13-trainee-gap-map.md) before expecting the app container to stay up.

Keep the root [README](../README.md) open for URLs and high-level context.

## Files Used

- `.env.example`
- `docker-compose.yml`
- `docker/app.Dockerfile`
- `app/src/server.js`
- `app/src/public/index.html`
- `app/src/public/app.js`

## Commands to Run

First confirm the local container tools are ready:

```bash
docker --version
docker compose version
docker ps
```

Then start the stack:

```bash
cp .env.example .env
docker compose up --build
```

After the containers start, check service state:

```bash
docker compose ps
bash scripts/validate-local-stack.sh foundation
```

## What To Do

1. Open `docker/app.Dockerfile` and restore the correct app entrypoint command.
2. Start the stack with `docker compose up --build`.
3. Open the GUI at `http://localhost:8080`.
4. Click `Check Health`.
5. Click `Show Version`.
6. Compare what you see in the browser with `docker compose ps`.

## Expected Output

- the GUI opens at `http://localhost:8080`
- `Check Health` returns `ok`
- `Show Version` returns service metadata such as version, environment, and image tag
- `docker compose ps` shows healthy `postgres`, `redis`, `app`, and `nginx`

## Checkpoint Questions

- Which container is the public entry point?
- Why is the app not exposed directly on a public port?
- What is the difference between `health` and `version`?
- Which checks tell you the issue is laptop setup versus the project itself?

## Common Issues

- `.env` file missing
- image still building on the first run
- `DOCKER-01` is still unfinished, so the app container exits immediately
- Docker Desktop or Docker daemon not started
- Docker Compose plugin not installed
- students open port `3000` directly instead of using Nginx on `8080`

## Team Task Split

- Student 1 opens the GUI and checks responses
- Student 2 confirms compose services are healthy
- Student 3 explains Nginx's role
- Student 4 records the URLs and status results

## Instructor Checkpoint

Each team should show the GUI, explain the difference between `/health` and `/version`, and point out which service is public.

## Validation

Run:

```bash
bash scripts/validate-local-stack.sh foundation
```

## Known Good End State

- Running: `postgres`, `redis`, `app`, and `nginx` are healthy in `docker compose ps`.
- Endpoint: `http://localhost:8080/health` returns a healthy JSON response.
- Confirm with: `bash scripts/validate-local-stack.sh foundation`
- Expected logs: `docker compose logs nginx --tail=20` shows `GET /health` after the GUI check.
- Common failure: Docker is not running, `.env` is missing, or `DOCKER-01` is still unfinished.
- Safe retry: `bash scripts/reset-local-lab.sh --yes` then `cp .env.example .env && docker compose up --build`

## Next Step

Continue to [LAB-02 Compose Layers DB Cache](LAB-02-compose-layers-db-cache.md).
