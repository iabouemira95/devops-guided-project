# LAB-07 Deploy to VM

## Goal

Deploy the selected production image to one Linux VM after it has already passed CI and been published from `main`.

## Why This Lab Matters

Students now move from local proof to a small real deployment target. The main lesson is not cloud complexity. It is understanding how an already-built image, runtime configuration, and simple smoke tests come together on a VM, whether that target is an Azure VM, an EC2 instance, or another Linux host.

This lab is the recommended production-like target path.
If VM access is not available yet, trainees can continue validating the project on the local path and return to this lab later.

## Before You Start

Make sure these are ready:

- a working published image in the chosen registry from `main`
- a merged pull request that passed PR CI
- VM access
- the deployment environment files on the VM
- the required secrets path, using Azure Key Vault or the documented fallback

Read [VM Deployment](../docs/10-vm-deployment.md) before starting the commands.
In the trainee-facing version, complete guided gaps `CICD-02` and `VM-01` from [Trainee Gap Map](../docs/13-trainee-gap-map.md) before expecting `Deploy Production` and `deploy/deploy.sh` to pull the correct image.

## Files Used

- `deploy/vm-setup.sh`
- `deploy/deploy.sh`
- `deploy/example.env`
- `deploy/example.secrets.env`
- `.github/workflows/deploy-production.yml`
- `docker-compose.vm.yml`
- `scripts/package-vm-source.sh`

## Commands to Run

```bash
bash deploy/vm-setup.sh /opt/devops-guided-project
bash deploy/deploy.sh sha-<published-short-sha>
ssh -L 3000:localhost:3000 USER@VM_PUBLIC_IP
bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP
```

## What To Do

1. Prepare the VM with the setup script.
2. If the VM cannot clone the repository directly, package and copy the source with `bash scripts/package-vm-source.sh`.
3. Confirm the runtime environment files exist on the VM.
4. Open the `Deploy Production` workflow and note that automatic deploys pause for `production` environment approval.
5. Deploy a selected image tag, preferably the `sha-<short-sha>` tag created by the publish workflow.
6. Open the deployed app in a browser.
7. Click `Check Health` and `Check Readiness`.
8. Open Grafana through the SSH tunnel and confirm the observability stack is reachable.

## Expected Output

- the app is reachable on port `80`
- `/health` succeeds
- `/ready` succeeds
- the deployment came from a published image tag rather than a VM rebuild
- the production environment approval clearly separated publish from deploy
- Grafana is reachable through the SSH tunnel
- students can explain which image tag is running and where its secrets came from
- manual rollback or redeploy requires an explicit image tag instead of silently using `latest`
- students can explain why the same workflow can target Azure, EC2, or another Linux VM over SSH
- students can explain why the VM path is recommended, while the local path remains available as fallback or parallel practice

Expected browser result:

![Expected VM app result](../docs/images/vm-app-end-state.png)

Expected Grafana tunnel result:

![Expected Grafana over SSH tunnel](../docs/images/vm-grafana-login.png)

## Checkpoint Questions

- Why do we keep only the app public by default?
- Why is Grafana behind an SSH tunnel?
- Why deploy an image tag instead of rebuilding on the VM?
- Why does the production environment approval happen after publish and before deploy?
- Which part of the flow proves that deployment actually succeeded?

## Common Issues

- `.env` missing on the VM
- `.env.secrets` missing when Azure Key Vault and GitHub Secrets fallback are both unavailable
- missing `POSTGRES_PASSWORD` or `GRAFANA_ADMIN_PASSWORD` in fallback mode
- `VM_SSH_KEY_B64` missing or built from the wrong content in GitHub Secrets
- VM firewall missing port `80`
- wrong image tag selected
- Azure Key Vault access not configured or missing keys
- ECR selected without AWS credentials or without a usable registry token path
- `CICD-02` is still unfinished, so `Deploy Production` cannot load `REGISTRY_HOST`
- the deploy workflow waits for approval and students think it is stuck

## Team Task Split

- Student 1 checks the VM app path
- Student 2 checks compose environment files
- Student 3 checks the SSH tunnel and Grafana
- Student 4 checks GitHub Actions approval, secrets, and the selected image tag

## Instructor Checkpoint

Ask each team to explain how the selected image tag reached the VM, why the deploy was allowed only after merge to `main`, how runtime configuration was supplied, and which checks prove the deploy worked.

## Validation

Run:

```bash
bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP
```

## Known Good End State

- Running: the VM app, Nginx, PostgreSQL, Redis, Prometheus, Loki, Promtail, and Grafana containers are up in `docker compose -f docker-compose.vm.yml ps`.
- Endpoint: `/health`, `/ready`, and `/version` respond from the VM app URL.
- Confirm with: `bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP`
- Expected logs: `bash deploy/deploy.sh <tag>` prints the post-deploy summary, including `/version`, `/health`, `/ready`, and running services.
- Common failure: missing `.env`, missing `.env.secrets`, a wrong tag, an approval gate that has not been approved yet, or a wrong SSH secret in the deploy workflow.
- Safe retry: `bash scripts/reset-vm-lab.sh --yes`, confirm env files, then rerun `bash deploy/deploy.sh <tag>`

## Next Step

Open [Troubleshooting](../docs/11-troubleshooting.md), then continue to [LAB-08 Failure and Recovery](LAB-08-failure-and-recovery.md).
