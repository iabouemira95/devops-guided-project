# VM Deployment

This project deploys to one Linux VM with Docker Compose.

That VM can be:

- an Azure VM
- an EC2 instance
- another Linux VM that you can reach over SSH

The VM deployment is intentionally image-based only:

1. GitHub Actions validates the change in a pull request
2. merge to `main` publishes the app image to the chosen registry
3. the deploy workflow waits for `production` environment approval
4. the VM pulls the selected image tag
5. the VM never rebuilds the application

This is the recommended target environment when it is available.
It is not a replacement for the local environment, but it is the preferred production-like path in the course.

Use the VM path when you want to practice:

- image-based deployment
- SSH-based operational access
- environment approval in GitHub Actions
- smoke testing a remote target

Stay on the local path when you want:

- faster iteration
- easier log and config inspection
- app and observability learning without remote infrastructure

## Runtime Configuration Model

Keep non-secret VM settings in `.env`.

Keep secret values in `.env.secrets`, or let GitHub Actions create that file automatically from Azure Key Vault data during deployment.

Use these files:

- `.env` from `deploy/example.env`
- `.env.secrets` from `deploy/example.secrets.env` only when you are not using Azure Key Vault or GitHub Secrets fallback

In the trainee-facing version, `deploy/example.env` intentionally contains guided gap `VM-01`.
Students must replace the placeholder `APP_IMAGE` value before expecting VM deployment to succeed.

In the trainee-facing version, `.github/workflows/deploy-production.yml` also contains guided gap `CICD-02`.
Students must restore the correct `REGISTRY_HOST` secret name before expecting the GitHub Actions deploy path to supply registry settings correctly.

`deploy/deploy.sh` uses `.env` for the stable runtime settings and `.env.secrets` for sensitive values such as:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

## Preferred Secret Source: Azure Key Vault

For the guided project, keep the VM connection values in GitHub Secrets:

- `VM_HOST`
- `VM_USER`
- `VM_SSH_KEY_B64` preferred
- `VM_SSH_KEY` optional fallback
- `VM_APP_DIR`

`VM_SSH_KEY_B64` should contain the base64-encoded PEM file content with line breaks removed.

Use Azure Key Vault for the runtime secrets by configuring these GitHub Secrets for Azure login:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_KEYVAULT_NAME`

The workflow can log into Azure with OIDC, read the required secrets from Azure Key Vault, then pass them into `deploy/deploy.sh`.

Expected Azure Key Vault secret names:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

## GitHub Secrets Fallback

For immediate validation, GitHub Actions can still supply the runtime secrets directly without Azure Key Vault.

Store these GitHub Secrets:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

The deploy workflow passes them to `deploy/deploy.sh`, which writes `.env.secrets` on the VM automatically during deployment.

If the chosen registry is ECR, the workflow can also generate a temporary registry password from AWS credentials before it connects to the VM.

The VM deployment workflow is `.github/workflows/deploy-production.yml`.

- automatic path: runs after `Publish Image` succeeds on `main`
- manual path: `workflow_dispatch` for rollback, recovery, or instructor demos

## SSH Trust Model In This Training Repo

The deploy workflow currently uses a convenience SSH configuration for the guided lab:

- it accepts the VM host key automatically
- it does not maintain a persistent `known_hosts` file on the GitHub runner

Why it is done this way here:

- it removes one more setup dependency from the trainee path
- it keeps the deploy workflow focused on image-based delivery, not SSH key distribution mechanics

Operational trade-off:

- this is acceptable for a controlled training environment
- this is not the hardened pattern you would normally keep for a long-lived production system
- a stricter production follow-up would pin the VM host key in `known_hosts` and fail on unexpected host-key changes

## Public and Private Services

Public by default:

- app through Nginx on port `80`

Private by default:

- Grafana
- Prometheus
- Loki
- Promtail
- PostgreSQL
- Redis

## Guided Validation

After the VM deployment completes, run:

```bash
bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP
```

That validation confirms:

- `/health`
- `/ready`
- `/version` deployment metadata

The `/version` response should match the published image metadata so students can trace the running VM back to a commit and image tag.

If you are not using the VM path yet, keep using:

- `bash scripts/validate-local-stack.sh foundation`
- `bash scripts/validate-local-stack.sh full`
- `bash scripts/validate-observability.sh`

The local and VM paths reuse the same app behavior and core validation ideas, but the VM route remains the recommended deployment path for the full course story.

In the trainee-facing version, run this only after `VM-01` is complete.
Before that, the deployment path is expected to stop on the guided placeholder rather than pull an image successfully.

If you used the same Linux machine earlier for the local training stack, stop that stack before the VM deployment path so ports `80`, `3000`, and `9090` are free for the VM runtime layout:

```bash
docker compose down -v
```

If you are cloning this repository directly onto the VM, make sure the VM has access to the repository first. A private repository will require either GitHub authentication on the VM or a source copy step from a workstation.

If you need the source-copy path, create a clean archive from your workstation first so macOS metadata files do not break Linux services such as Grafana provisioning:

```bash
bash scripts/package-vm-source.sh
```

If you need to redeploy a previously known good image tag, use:

```bash
bash deploy/rollback.sh sha-<known-good-sha-tag>
```

## Next Step

After deployment is working, review [Troubleshooting](11-troubleshooting.md), then move to [LAB-08 Failure and Recovery](../labs/LAB-08-failure-and-recovery.md).

## SSH Tunnel for Grafana

Use:

```bash
ssh -L 3000:localhost:3000 USER@VM_PUBLIC_IP
```

Then open:

```text
http://localhost:3000
```

## Important Reminder

This is a controlled training VM.

It is not a hardened production platform.

Do not expose Grafana, Prometheus, Loki, or Promtail publicly unless you are doing that intentionally for a supervised class demo.
The same principle applies to SSH trust in the deploy workflow: the repo currently favors trainee simplicity over strict host-key verification.
