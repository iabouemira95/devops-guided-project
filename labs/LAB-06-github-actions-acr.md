# LAB-06 GitHub Actions and Registry Publish

## Goal

See how a feature branch change moves through PR validation, image publishing, and production-ready tagging in a container registry.

## Why This Lab Matters

Running locally proves the app works on one machine. CI/CD turns that into a repeatable build and publish path that teams can trust and reuse for deployment or recovery.

## Before You Start

Make sure students already understand:

- what the app image contains
- why we want tagged images
- why deployment should consume an image instead of rebuilding on the VM

Read [Registries](../docs/08-registries.md) before or during this lab.
In the trainee-facing version, complete guided gap `CICD-01` from [Trainee Gap Map](../docs/13-trainee-gap-map.md) before expecting `Publish Image` to succeed.

## Files Used

- `.github/workflows/ci.yml`
- `.github/workflows/publish-image.yml`
- `docker/app.Dockerfile`
- `docs/08-registries.md`

## Commands to Run

```bash
git status
```

Then do these guided checks:

1. Create or inspect a feature-branch pull request into `main`.
2. Open the Actions tab and inspect the latest `PR CI` and `Publish Image` runs.
3. If you have registry access, inspect the `devops-mini-app` repository in your chosen registry.

## What To Do

1. Read the trigger for `.github/workflows/ci.yml` and confirm it runs only for pull requests into `main`.
2. Open the PR CI run and identify what each required check proves:
   - `test-and-validate`
   - `dependency-scan`
   - `workflow-and-compose-check`
3. Confirm that PR CI also proves the application image can build before merge.
4. Read the trigger for `.github/workflows/publish-image.yml` and confirm it runs after merge to `main`.
5. Open a successful publish run and find the final pushed image names.
6. Find one `sha-<short-sha>` tag that could be redeployed later.
7. Confirm that the app image is scanned after publish, not during the VM deploy.

## Expected Output

- pull requests into `main` run required CI checks only
- the publish workflow runs after merge to `main`
- image tags include `latest` and `sha-<short-sha>`
- students can point to one run that only validated and one run that published
- students can explain why the SHA tag is the safer deployment tag
- students can identify the exact SHA tag that would be used for recovery

## Checkpoint Questions

- Why do pull requests validate but not push?
- What does each required PR check prove?
- Why is it useful to prove the Docker image builds before merge?
- Why is the SHA tag useful for recovery?
- Why scan dependencies before merge and scan the image after publish?
- Where in the workflow logs do you confirm the final pushed image names?
- Where in your registry do you confirm that the image was actually published?

## Common Issues

- registry credentials missing or incomplete
- ECR selected without AWS credentials or a usable registry token
- workflow not running on the expected branch
- pull request opened against the wrong base branch
- students read the YAML but never verify the real workflow outcome
- students confuse a successful test run with a published image
- students deploy `latest` mentally even though the safer promotion tag is `sha-<short-sha>`

## Team Task Split

- Student 1 explains the feature branch and pull request path
- Student 2 explains the required PR checks
- Student 3 verifies the published image names from the publish run
- Student 4 verifies the matching image tags in the chosen registry and explains which secrets make the publish path work

## Instructor Checkpoint

Have teams explain the difference between validation, publishing, and deployment readiness, then show:

- one workflow run that validated a pull request only
- one workflow run that published
- one SHA tag they could redeploy later

## Validation

There is no separate lab-only script here.

Validation for this lab is:

- a successful `PR CI` workflow run
- a successful `Publish Image` workflow run on `main`
- visible image tags in the chosen registry
- a team explanation of which tag should be deployed next and why

## Known Good End State

- Running: the repository has one successful PR validation run and one successful publish run on `main`.
- Endpoint: not applicable for this lab; the artifact is the published image tag.
- Confirm with: the `PR CI` workflow logs, the `Publish Image` workflow logs, and the matching image tags in the chosen registry.
- Expected logs: PR logs show the required checks; publish logs show the final pushed image names, including `latest` and `sha-<short-sha>`.
- Common failure: students stop after seeing PR tests pass and never confirm that merge to `main` published a deployable image.
- Safe retry: update the feature branch, rerun the PR checks, merge again, then recheck the chosen registry

## Next Step

Read [Registries](../docs/08-registries.md), then [Azure Key Vault and Secrets Flow](../docs/09-secrets-and-azure-key-vault.md), then continue to [LAB-07 Deploy to VM](LAB-07-deploy-to-vm.md).
