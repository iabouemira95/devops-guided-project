# Troubleshooting

## App GUI Does Not Open

- check `docker --version`
- check `docker compose version`
- check `docker ps`
- check `docker compose ps`
- check `docker compose logs nginx --tail=50`
- check `docker compose logs app --tail=50`

If `docker compose version` fails, install Docker Compose v2.

If `docker ps` fails, start Docker Desktop or the Docker daemon first.

If Docker is already running on Linux but `docker ps` still fails, add your user to the `docker` group, open a new shell or SSH session, and rerun the prerequisite validation script.

## `/ready` Fails

- check PostgreSQL logs
- check Redis logs
- check app logs

If `/ready` succeeds but `Test Redis Cache` still fails in the trainee-facing version, check whether `APP-01` is still unfinished.

## Grafana Has No Data

- wait 15 to 30 seconds
- check `docker compose logs prometheus --tail=50`
- check `docker compose logs grafana --tail=50`
- check `docker compose logs promtail --tail=50`

Also check whether guided gaps `OBS-01`, `OBS-02`, or `OBS-03` are still unfinished.

## Loki Logs Missing

- check `docker compose logs promtail --tail=50`
- check that `logs/app/app.log` exists
- check that `logs/nginx/access.log` exists
- check whether `monitoring/promtail/promtail-config.yml` still contains the `OBS-02` placeholder
- check whether `monitoring/grafana/provisioning/datasources/datasources.yml` still contains the `OBS-03` placeholder

## GitHub Actions Build Fails

- confirm `app/package.json` and lockfile are in sync
- confirm `REGISTRY_HOST`, `REGISTRY_USERNAME`, and `REGISTRY_PASSWORD` are set
- confirm the workflow ran on the branch you expected
- confirm whether the run was the `PR CI` workflow or the `Publish Image` workflow
- remember that the publish workflow image scan focuses on application libraries, not base-image OS packages
- if the PR is blocked, check which required status check failed:
  - `test-and-validate`
  - `dependency-scan`
  - `workflow-and-compose-check`

If `Publish Image` stops on the guided image-name guard, complete `CICD-01` first.

## VM Deploy Fails

- rerun `bash deploy/deploy.sh sha-<known-good-short-sha>`
- inspect:
  - `docker compose -f docker-compose.vm.yml logs app --tail=50`
  - `docker compose -f docker-compose.vm.yml logs nginx --tail=50`

If the VM works locally but your laptop browser does not reach port `80`, check the cloud firewall or security group first.

If your local network or ISP redirects plain HTTP before it reaches the VM, validate the app from another network or use an SSH tunnel to reach the VM services directly.

If the GitHub-hosted deploy workflow fails before the SSH connection starts:

- confirm `VM_HOST`, `VM_USER`, and `VM_APP_DIR` exist in GitHub Secrets
- confirm `VM_SSH_KEY_B64` was created from the PEM file content, not from the file path
- if you stored `VM_SSH_KEY` instead, make sure the secret contains the full multi-line private key text
- confirm the `production` environment approval was granted if the workflow is waiting
- rerun the workflow and check whether the failure happened during key validation or during the SSH connection step

If the deploy script fails immediately on the image path placeholder, complete `VM-01` first.

## Observability Shortcut Confusion

- if Grafana and Prometheus are on the VM, use the app from the VM hostname or public IP so `/ui-config` switches into SSH tunnel mode
- if you are already on the VM itself, the shortcuts should point to `127.0.0.1`
- if Grafana is healthy but a shortcut still fails, create the tunnel manually:
  - `ssh -L 3000:localhost:3000 USER@VM_PUBLIC_IP`
  - `ssh -L 9090:localhost:9090 USER@VM_PUBLIC_IP`

## Azure Key Vault Secret Fetch Fails

- confirm `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, and `AZURE_KEYVAULT_NAME` exist in GitHub Secrets
- confirm the GitHub Actions identity can read the Key Vault secrets
- confirm the Key Vault secret names match the documented names exactly
- if Azure Key Vault is temporarily unavailable, rely on the GitHub Secrets fallback or create `.env.secrets` from `deploy/example.secrets.env`

## Grafana Provisioning Fails After Copying Source To The VM

- check for macOS metadata files:
  - `find . -name '._*' -o -name '.DS_Store'`
- if they exist, remove them and restart Grafana:
  - `find . -name '._*' -delete`
  - `find . -name '.DS_Store' -delete`
  - `docker compose restart grafana`
- for the next transfer, create the VM source archive with `bash scripts/package-vm-source.sh`

## Safe Reset Commands

If the local lab state is too messy to reason about:

- `bash scripts/reset-local-lab.sh`

If the VM project state is too messy to reason about:

- `bash scripts/reset-vm-lab.sh`

Use these only for the guided-project stack, not as a general Docker cleanup habit.

## Next Step

Return to the lab you were running and repeat the matching milestone validation script.
