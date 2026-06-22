# Azure Key Vault and Secrets Flow

This guided project uses **Azure Key Vault** as the optional preferred runtime secret source for CI/CD deployment.

GitHub Secrets remain the fallback path so classes can still complete the project if Azure Key Vault is not ready yet.

This secret flow sits inside a production-like CI/CD path:

1. a feature branch opens a pull request into `main`
2. PR CI validates the change without publishing or deploying
3. merge to `main` publishes the image to the chosen container registry
4. the production deploy waits for GitHub Environment approval
5. the deploy workflow reads runtime secrets and deploys the selected image tag

## Why This Matters

The app needs runtime values such as:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

These values should not be committed to the repository.

## Preferred Secret Flow

1. GitHub Actions authenticates to Azure with OIDC.
2. GitHub Actions reads runtime secrets from Azure Key Vault.
3. The workflow exports those values to the deployment job environment.
4. `deploy/deploy.sh` writes them into `.env.secrets` on the VM.
5. Docker Compose starts the VM stack with those runtime secrets.

## Fallback Secret Flow

If Azure Key Vault is not configured yet:

1. Store the same values in GitHub Secrets.
2. The deploy workflow loads those GitHub Secrets first.
3. If Azure Key Vault later returns a value for the same key, the Key Vault value overrides the fallback.

This keeps the training path unblocked while still teaching the preferred cloud secret path.

In the trainee-facing version, `CICD-02` intentionally leaves the deploy workflow registry-host mapping unfinished at first.
Students fix that in `.github/workflows/deploy-production.yml` before expecting the deploy workflow to read `REGISTRY_HOST` correctly.

## GitHub Secrets Needed For Azure Login

- `VM_HOST`
- `VM_USER`
- `VM_APP_DIR`
- `VM_SSH_KEY_B64` preferred, or `VM_SSH_KEY`
- `REGISTRY_HOST`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_KEYVAULT_NAME`

These are used by `.github/workflows/deploy-production.yml`.

## GitHub Secrets Kept As Fallback

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

These values let the deployment continue even if Azure Key Vault is not ready yet.

## Required Azure Key Vault Secret Names

Use these exact secret names in Azure Key Vault:

- `POSTGRES_PASSWORD`
- `GRAFANA_ADMIN_PASSWORD`
- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

## Azure Access Requirements

The GitHub Actions identity needs permission to read secrets from the Key Vault.

Typical requirement:

- assign the identity a role such as **Key Vault Secrets User**

## Teaching Message

Students should leave with this mental model:

- application configuration is split into non-secret and secret values
- branch protection and PR CI decide what is safe to merge
- image publish happens after merge, not during the pull request
- deployment approval is separate from build completion
- GitHub Actions can retrieve secrets from a cloud secret manager
- a fallback path can keep delivery moving without changing the app itself
- VM access secrets are separate from runtime app secrets, and both must be configured for the deploy workflow to succeed
- the same workflow can target an Azure VM, an EC2 instance, or another Linux VM as long as SSH and Docker Compose are available

## Next Step

Continue to [VM Deployment](10-vm-deployment.md), then run [LAB-07 Deploy to VM](../labs/LAB-07-deploy-to-vm.md).
