# Registries

In the trainee-facing version, the publish workflow intentionally contains guided gap `CICD-01`.
Students must replace the guided `IMAGE_REPOSITORY` placeholder in `.github/workflows/publish-image.yml` so the workflow pushes the intended app image path.

This project uses a **generic container registry path** in the workflows.

For the main guided path:

- build and publish the app image to the chosen registry
- deploy that image to the VM
- use Azure Key Vault or GitHub Secrets to provide the runtime secrets needed during deployment

## Generic Workflow Contract

The student workflow expects:

- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

For ECR, the workflow also supports:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` optional
- `AWS_REGION`

The guided edit inside `.github/workflows/publish-image.yml` is the placeholder value:

- `TODO-set-your-image-repository`

Typical examples:

- ACR or ECR: `devops-mini-app`
- GHCR: `<owner>/<repo>/devops-mini-app`
- Docker Hub: `<username>/devops-mini-app`

## Tagging Strategy In This Project

The guided path uses two tag styles:

- `latest`
  - a convenience tag for the most recent publish from `main`
  - useful for quick inspection, but not the preferred production deployment tag
- `sha-<short-sha>`
  - an immutable tag tied to one Git commit
  - the preferred tag for deployment, validation, and rollback

For trainee work, treat `sha-<short-sha>` as the trustworthy deployment tag because it is easy to trace back to the exact commit and CI run.

## Azure ACR

Use when:

- the project deploys to Azure-hosted training infrastructure
- you want one consistent registry story for CI and VM deployment

Image format:

```text
<registry>.azurecr.io/devops-mini-app:latest
<registry>.azurecr.io/devops-mini-app:sha-<short-sha>
```

Secrets:

- `REGISTRY_HOST`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

Student verification:

- check the `Publish Image` workflow logs for the final image names
- check the ACR repository tags for `latest` and `sha-<short-sha>`

Trainee note:

- before `CICD-01` is complete, the workflow should stop on the guided repository-name guard instead of silently publishing to the wrong path

Login example:

```yaml
- name: Log in to ACR
  uses: docker/login-action@v3
  with:
    registry: ${{ secrets.REGISTRY_HOST }}
    username: ${{ secrets.REGISTRY_USERNAME }}
    password: ${{ secrets.REGISTRY_PASSWORD }}
```

Pros:

- aligns naturally with Azure VM training
- keeps the registry story consistent with Azure Key Vault usage
- works well for a guided enterprise-style path

Cons:

- requires registry credentials
- is more cloud-specific than GHCR

## GHCR

Use when:

- your code is already in GitHub
- you want a GitHub-native alternative

Image format:

```text
ghcr.io/<owner>/<repo>/devops-mini-app:latest
ghcr.io/<owner>/<repo>/devops-mini-app:sha-<short-sha>
```

Secrets:

- `REGISTRY_HOST=ghcr.io`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

For this repository, keep the workflow contract generic even when the registry is GHCR:

- set `REGISTRY_USERNAME` to the GitHub username or service account that can publish the package
- set `REGISTRY_PASSWORD` to a token that can push packages, such as a PAT with package write access or another approved package-publish token for the trainee repository

Student verification:

- check the `Publish Image` workflow logs for the final image names
- check the repository package page for `latest` and `sha-<short-sha>` tags

Login example:

```yaml
- name: Log in to GHCR
  uses: docker/login-action@v3
  with:
    registry: ${{ secrets.REGISTRY_HOST }}
    username: ${{ secrets.REGISTRY_USERNAME }}
    password: ${{ secrets.REGISTRY_PASSWORD }}
```

Pros:

- simple when the whole course stays inside GitHub

Cons:

- less aligned if the training deployment target and secret story are already Azure-based

## Docker Hub

Use when:

- you want a generic public registry

Image format:

```text
docker.io/<username>/devops-mini-app:latest
```

Secrets:

- `REGISTRY_HOST=docker.io`
- `REGISTRY_USERNAME`
- `REGISTRY_PASSWORD`

For Docker Hub in this repository:

- set `REGISTRY_USERNAME` to the Docker Hub username
- set `REGISTRY_PASSWORD` to the Docker Hub access token

Login example:

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    registry: ${{ secrets.REGISTRY_HOST }}
    username: ${{ secrets.REGISTRY_USERNAME }}
    password: ${{ secrets.REGISTRY_PASSWORD }}
```

Pros:

- widely known
- easy to explain

Cons:

- separate credentials
- public naming conventions can be less convenient for classroom repos

## AWS ECR

Use when:

- you already deploy mostly in AWS

Image format:

```text
<account>.dkr.ecr.<region>.amazonaws.com/devops-mini-app:latest
```

Common secrets:

- `REGISTRY_HOST`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` optional
- `AWS_REGION`

Login step example:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
- name: Log in to ECR
  uses: aws-actions/amazon-ecr-login@v2
```

Pros:

- strong fit for AWS-first teams

Cons:

- more cloud setup than this course needs

## Next Step

Read [Azure Key Vault and Secrets Flow](09-secrets-and-azure-key-vault.md).
