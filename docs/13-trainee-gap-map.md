# Trainee Gap Map

This repository is the trainee-facing version of the project.

It intentionally includes a small number of guided gaps so students can complete meaningful work instead of only reading a finished implementation.

## How To Use This File

Treat each gap as a milestone.

The intended pattern is:

1. read the matching document or lab
2. inspect the file listed here
3. fill the gap
4. rerun the matching validation script
5. compare the result with the expected runtime behavior

## Gap Order

### DOCKER-01 Start The App Container Correctly

Goal:

- make the app container start successfully in the local stack
- make `docker compose up --build` bring up a healthy `app` service

Files:

- `docker/app.Dockerfile`
- `docs/03-runtime-stack.md`
- `labs/LAB-01-run-locally-and-use-gui.md`

What to implement:

- replace `TODO-start-script` with the correct app entrypoint path
- keep the Dockerfile readable and keep the same non-root runtime pattern

What good looks like:

- the app container stops exiting immediately
- `docker compose ps` shows `app` running
- the GUI opens through Nginx

Validation:

- `bash scripts/validate-local-stack.sh foundation`

### APP-01 Popular Titles Cache Demo

Goal:

- make the GUI `Test Popular Titles Cache` button work
- show a clear cache miss on the first request
- show a clear cache hit on the second request

Files:

- `app/src/server.js`
- `docs/04-app-gui.md`
- `docs/05-request-and-data-flow.md`

What to implement:

- restore the `GET /cache-demo` route
- read from Redis first
- if the key exists, return a cache-hit response
- if the key is missing, generate the payload, store it in Redis, and return it
- log whether the route was a cache hit or cache miss

What good looks like:

- first request returns `source: "app-generated"`
- second request returns `source: "redis-cache"`
- the GUI button stops returning `501`

Validation:

- `bash scripts/validate-local-stack.sh full`
- `bash scripts/validate-gui-requests.sh http://localhost:8080`

### OBS-01 Prometheus App Scrape Target

Goal:

- make Prometheus scrape the app metrics endpoint correctly

Files:

- `monitoring/prometheus/prometheus.yml`
- `docs/07-monitoring.md`

What to implement:

- replace the placeholder app target with the real internal app target and port

What good looks like:

- Prometheus target becomes healthy
- request metrics appear in Prometheus and Grafana

Validation:

- `bash scripts/validate-observability.sh`

### OBS-02 Promtail App Log Path

Goal:

- ship app logs into Loki so they appear in Grafana Explore

Files:

- `monitoring/promtail/promtail-config.yml`
- `docs/06-logging.md`
- `docs/07-monitoring.md`

What to implement:

- replace the placeholder app log file path with the real mounted path

What good looks like:

- app logs appear in Grafana Explore
- request IDs from GUI traffic can be searched in Grafana logs

Validation:

- `bash scripts/validate-observability.sh`

### OBS-03 Grafana Loki Datasource

Goal:

- make Grafana Explore connect to Loki correctly

Files:

- `monitoring/grafana/provisioning/datasources/datasources.yml`
- `docs/06-logging.md`
- `docs/07-monitoring.md`

What to implement:

- replace the placeholder Loki datasource URL with the real internal Loki service URL

What good looks like:

- Grafana Explore can query app and Nginx logs from Loki
- the observability validator stops failing on the Loki datasource placeholder

Validation:

- `bash scripts/validate-observability.sh`

### CICD-01 Publish The Correct App Image

Goal:

- make the publish workflow push the intended app image name

Files:

- `.github/workflows/publish-image.yml`
- `docs/08-registries.md`

What to implement:

- replace the `TODO-set-your-image-repository` placeholder with the correct repository path
- keep the same image naming pattern used by deployment
- make sure the chosen path matches your registry style, such as ACR, ECR, GHCR, or Docker Hub

What good looks like:

- `Publish Image` no longer stops at the trainee image-name guard
- image tags are clear and traceable

Validation:

- GitHub Actions `Publish Image`

### CICD-02 Load The Registry Host In Deploy Production

Goal:

- make the deploy workflow load the registry host correctly from the secret source
- keep the deploy path aligned with the publish path

Files:

- `.github/workflows/deploy-production.yml`
- `docs/09-secrets-and-azure-key-vault.md`
- `docs/10-vm-deployment.md`

What to implement:

- replace `TODO_REGISTRY_HOST` with the correct `REGISTRY_HOST` secret name
- fix both the GitHub Secrets fallback mapping and the Azure Key Vault fetch name

What good looks like:

- `Deploy Production` stops failing on missing `REGISTRY_HOST`
- the deploy workflow can pass the registry host into `deploy/deploy.sh`

Validation:

- GitHub Actions `Deploy Production`

### VM-01 Point Deployment At The Real Registry Image

Goal:

- make VM deployment pull the real published image

Files:

- `deploy/example.env`
- `deploy/deploy.sh`
- `docs/10-vm-deployment.md`

What to implement:

- replace the placeholder `APP_IMAGE` with the actual registry image path in `.env`
- keep the image path aligned with the publish workflow
- use a full image path that works for your VM target, whether that target is Azure, EC2, or another Linux host

What good looks like:

- `deploy/deploy.sh` stops failing on the guided VM image placeholder
- the VM can pull and run the published image

Validation:

- `bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP`
- `bash scripts/validate-runtime-contract.sh vm http://127.0.0.1`

## Recommended Team Split

- Student 1: DOCKER-01 and APP-01
- Student 2: OBS-01, OBS-02, and OBS-03
- Student 3: CICD-01
- Student 4: CICD-02 and VM-01

Then rotate and review each other’s work before the final full-stack validation.

## Final Check

When all guided gaps are complete, rerun:

- `bash scripts/validate-project.sh`
- `bash scripts/validate-doc-journey.sh`
- `bash scripts/validate-local-stack.sh foundation`
- `bash scripts/validate-local-stack.sh full`
- `bash scripts/validate-gui-requests.sh http://localhost:8080`
- `bash scripts/validate-observability.sh`
- `bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP`
