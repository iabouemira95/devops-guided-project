# VM Deployment

Use this folder when you are ready to deploy the project to a single Ubuntu VM.

## Files

- `vm-setup.sh` installs Docker and prepares directories on Ubuntu.
- `deploy.sh` pulls the selected app image and starts the VM stack.
- `example.env` shows the non-secret environment values used by the VM stack.
- `example.secrets.env` shows the secret values used by the VM stack when you are not pulling them from Azure Key Vault.

## Simple Flow

1. Copy the repository to the VM.
   - preferred path: `git clone` directly on the VM when the repository is reachable
   - workstation fallback: run `bash scripts/package-vm-source.sh` first, copy the archive to the VM, then extract it
2. Copy `deploy/example.env` to `.env` and update the non-secret values.
3. Choose one secret source:
   - preferred path: let GitHub Actions fetch runtime secrets from Azure Key Vault and pass them into `deploy.sh`
   - fallback path: keep runtime secrets in GitHub Secrets and let `deploy-production.yml` pass them into `deploy.sh`
   - local manual fallback: copy `deploy/example.secrets.env` to `.env.secrets` and fill in the values manually
4. Run:

```bash
bash deploy/vm-setup.sh /opt/devops-guided-project
```

Open a new SSH session after setup if you want Docker access without `sudo`.

5. Deploy:

```bash
bash deploy/deploy.sh sha-<published-short-sha>
```

6. If the VM stack is healthy, open the app on port `80`.

For the guided GitHub Actions path:

1. open a pull request into `main`
2. wait for `PR CI` to pass
3. merge into `main`
4. wait for `Publish Image` to push the image to your chosen container registry
5. approve `Deploy Production`
6. confirm the VM is running the published `sha-<short-sha>` image tag

## SSH Note For The Guided Workflow

The GitHub Actions deploy workflow is intentionally simplified for a controlled lab:

- it accepts the VM host key automatically on the GitHub runner
- it does not maintain a persistent `known_hosts` file between runs

That keeps the trainee path focused on registry publish, approval, deploy, and smoke validation.
For a stricter production implementation, the next improvement would be pinning the VM host key explicitly.

## Post-Deploy Confirmation

After `bash deploy/deploy.sh <tag>` succeeds, it prints:

- the deployed image tag
- the `/version` response
- the `/health` response
- the `/ready` response
- the running compose services
- the next log commands to use

For a simple rollback to a previously known good tag:

```bash
bash deploy/rollback.sh sha-<known-good-sha-tag>
```

## GitHub Secrets Fallback

For full-stack validation without Azure Key Vault, store these GitHub Secrets:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

The deploy workflow passes them to `deploy.sh`, and `deploy.sh` writes them into `.env.secrets` on the VM automatically.

## Azure Key Vault with GitHub Actions

The deploy workflow can fetch runtime secrets from Azure Key Vault before it connects to the VM.

Store these GitHub Secrets:

- `VM_HOST`
- `VM_USER`
- `VM_APP_DIR`
- `VM_SSH_KEY_B64` preferred, or `VM_SSH_KEY`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_KEYVAULT_NAME`

Expected Azure Key Vault secret names:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

`deploy.sh` writes those values into `.env.secrets` on the VM automatically during the deploy run.

## Grafana on the VM

Grafana is localhost-only by default.

Use an SSH tunnel:

```bash
ssh -L 3000:localhost:3000 USER@VM_PUBLIC_IP
```

Then open:

```text
http://localhost:3000
```

## Deployment Validation

After the stack is deployed, run:

```bash
bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP
```
