# Trainee Validation Findings

This file captures issues found while walking the project end to end like a fresh trainee.

Use it as the improvement backlog for the next polish pass.

## 2026-06-20 Dry Run

### Confirmed Strengths

- the guided README sequence is much clearer than a flat project README
- the milestone validation scripts create a good sense of progress
- the VM setup script correctly fixes Docker access after a new SSH session
- the app and Nginx logs now show a useful request cycle for teaching
- the VM deployment script succeeds cleanly with a pulled image

### Issues Found

#### 1. Linux Docker access can fail even when Docker is installed

- symptom: `docker ps` failed for `azureuser` even though Docker was running
- root cause: the user was not yet in the `docker` group
- impact: a trainee can believe Docker is broken when the fix is just group membership plus a new shell
- follow-up: keep the Linux `docker` group reminder in prerequisites and troubleshooting

#### 2. VM Node installation is heavier than the docs suggest

- symptom: installing `nodejs` and `npm` on Ubuntu pulled a very large package set
- impact: the setup feels slower and noisier than a beginner expects
- follow-up: consider a tighter guided install path for Node.js on Linux or explain that local laptop testing is the main Node use case

#### 3. Public VM HTTP validation can be distorted by the trainee network

- symptom: external HTTP to the VM returned a middlebox redirect instead of the app response
- impact: a trainee may blame the project when the issue is the local network path
- follow-up: keep SSH tunnel validation steps visible and mention cloud firewall plus ISP or captive-network interception in troubleshooting

#### 4. Observability validator originally disagreed with the intended architecture

- symptom: `scripts/validate-observability.sh` failed because it expected `/metrics` through Nginx
- root cause: `/metrics` is intentionally private, so Prometheus should be queried instead
- impact: the script taught the wrong expectation
- follow-up: keep the validator aligned with the private-metrics design

#### 5. Nginx error log emptiness is not a failure by itself

- symptom: the validator failed when `logs/nginx/error.log` existed but was empty
- impact: a healthy deployment looked partially broken
- follow-up: validate that the file exists, and only expect entries after an error scenario

### GitHub Journey Blocker At The Time

- local GitHub CLI authentication was expired during the first dry run
- impact then: the full GitHub repository creation, Actions secret setup, and workflow trigger path could not be completed from this workstation without re-authentication
- current status: this blocker was cleared later, and the repository plus CI workflow were validated successfully

## 2026-06-20 GitHub Actions Follow-Up

### Confirmed Working

- the GitHub repository was created successfully at `iabouemira95/devops-guided-project`
- `CI Build Push` succeeded on `main`
- the workflow path itself is valid for test and publish stages

These workflow names reflect the earlier CI/CD shape at the time of that validation pass. The current repository now uses `PR CI`, `Publish Image`, and `Deploy Production`.

### Remaining Gaps

#### 6. `deploy-vm.yml` had a workflow parser defect

- symptom: workflow dispatch failed with `Unrecognized named-value: 'secrets'`
- root cause: step `if:` expressions referenced `secrets` directly
- status: fixed in the workflow

#### 7. GitHub-hosted VM deploy is still blocked by SSH authentication

- symptom: the deploy workflow now dispatches and reaches the SSH step, but the GitHub-hosted runner receives `Permission denied (publickey)`
- evidence: local SSH from the instructor machine works with the same VM key, while the GitHub workflow runner does not
- impact: the full trainee GitHub deploy path is not yet complete
- likely next checks:
  - verify the exact private key format expected by the VM against the stored GitHub secret
  - verify whether the VM or cloud environment applies any SSH restrictions that differ for GitHub-hosted runners
  - test with a dedicated deployment key generated specifically for GitHub Actions

#### 8. The registry story was split between GHCR and ACR during validation

- symptom: earlier CI used GHCR, while the manually validated VM runtime used ACR credentials and an ACR image path
- impact: the core student story felt inconsistent
- status: default course direction changed to ACR
- follow-up: confirm the ACR-first wording and examples remain consistent in future edits

## 2026-06-20 Fresh VM Reset And Trainee Rebuild

### Confirmed Working

- a full reset of `/opt/devops-guided-project` followed by a clean redeploy worked
- `deploy/vm-setup.sh` still prepared the VM correctly from a trainee-style starting point
- `deploy/deploy.sh validation-20260620` logged into ACR, pulled the app image, and brought the stack up successfully
- `scripts/validate-vm-deployment.sh http://127.0.0.1` passed on the VM
- the public browser path responded with `HTTP/1.1 200 OK` at `http://devops-lab-001.swedencentral.cloudapp.azure.com/`
- `/ui-config` returned the expected SSH-tunnel observability shortcuts for the VM path

### Remaining Gaps

#### 9. The prerequisite validator accepted an unsupported Node.js version

- symptom: the VM passed `scripts/validate-prerequisites.sh` with Node.js `v18.19.1`
- root cause: the script checked that Node existed, but did not enforce the documented Node.js baseline
- impact: a trainee could pass preflight and hit avoidable warnings or edge cases later
- status: fixed by enforcing the documented Node.js LTS baseline in the prerequisite validator

#### 10. A fresh VM clone path can fail if the GitHub repository is not accessible from the VM

- symptom: `git clone https://github.com/iabouemira95/devops-guided-project.git` prompted for credentials on the VM
- impact: the clean trainee story of "clone the repo on the VM and continue" breaks unless repository visibility or GitHub authentication is prepared first
- status: improved by documenting the private-repository access requirement and adding `scripts/package-vm-source.sh` as the clean fallback

#### 11. Cross-platform source copy can inject macOS metadata files that break Linux runtime components

- symptom: copying the repository from macOS to the VM produced `._*` files such as `._dashboards.yml`
- root cause: AppleDouble metadata files were included in the transfer
- impact: Grafana provisioning failed with a YAML parse error even though the real dashboard file was correct
- status:
  - repository validation still checks for `._*` and `.DS_Store`
  - `scripts/package-vm-source.sh` now creates a metadata-clean archive for VM transfer

#### 12. `scripts/validate-project.sh` assumed optional local tooling too aggressively

- symptom: the sanity validator failed on the VM because `ruby` and `rg` were not installed
- root cause: the script treated optional helper tools as hard requirements
- impact: a clean trainee environment looked broken even though the project files were valid
- status:
  - `rg` dependency removed by using a `grep` fallback
  - missing `ruby` now skips YAML parse validation with a warning instead of a hard failure

#### 13. `scripts/validate-project.sh` treated a clean checkout as a failure if `npm ci` had not run yet

- symptom: the script failed because `app/node_modules` was absent on a fresh VM checkout
- impact: the validation felt more like a maintainer-only script than a trainee-friendly project check
- status: changed to a warning that clearly tells the trainee to run `cd app && npm ci && npm test` for the full app validation path

#### 14. Reusing one Linux host for both the local lab stack and the VM stack needs an explicit stop step

- symptom: the local stack had to be stopped before the `/opt` VM deployment layout could safely reuse the same ports
- impact: a trainee using one Linux machine for both paths could run into port conflicts or confusing half-working behavior
- follow-up: keep the VM deployment document explicit about running `docker compose down -v` before starting the `/opt` deployment path on the same host

#### 15. GitHub-hosted deploy SSH authentication was too fragile to diagnose quickly

- symptom: the workflow could fail with `Permission denied (publickey)` even though local SSH worked
- root cause: the workflow only accepted one key format path and gave limited diagnostics before the SSH step
- status:
  - the deploy workflow now validates VM settings early
  - it supports both `VM_SSH_KEY_B64` and `VM_SSH_KEY`
  - it validates the decoded key before attempting the SSH connection

## Next Review Focus

- finish the GitHub-hosted VM deploy path by resolving runner-to-VM SSH authentication
- verify the app from a browser on a network path that does not rewrite plain HTTP
- re-run all milestone validators after the final deploy path is stable

## 2026-06-22 Deep Trainee Review

### Confirmed Working

- the document journey is now ordered and validated by `scripts/validate-doc-journey.sh`
- the trainee gap model is visible early enough in LAB-01, LAB-04, LAB-06, and LAB-07
- the VM path is now described as the recommended production-like target, while local remains the fallback or parallel path
- `scripts/validate-project.sh` now fails on the intentional guided gaps instead of failing first on unrelated tooling assumptions

### New Issues Found

#### 16. Docker image Node version drift caused an avoidable trust gap

- symptom: the docs, prerequisite validator, and `app/package.json` required Node.js 24 or later, but `docker/app.Dockerfile` still used `node:20-bookworm-slim`
- impact: a trainee could reasonably question which runtime contract was actually correct
- status: fixed by aligning the Dockerfile base image with the documented Node.js 24 baseline

#### 17. CI/CD gap wording did not match the actual YAML syntax trainees edit

- symptom: the docs described the publish placeholder as `IMAGE_REPOSITORY=TODO-set-your-image-repository`, while the workflow file uses YAML with `IMAGE_REPOSITORY: ...`
- impact: a trainee could search for the wrong text and lose confidence before making the intended change
- status: fixed by documenting the placeholder value directly instead of showing shell-style syntax

#### 18. README local usage list had a numbering glitch

- symptom: the local usage flow repeated step number `5`
- impact: small, but it makes the first-read experience feel less polished than the rest of the journey
- status: fixed by correcting the ordered list
