# Documentation Guide

This file shows the recommended reading order for the project documentation.

Use it when you are new to the repository and want to understand what to read first, what each document explains, and how the documents support the labs.

## 1. Before You Start

- this repository is the guided training version
- create your own repository from the public template first
- do not run the labs directly in the shared template repository
- [Prerequisites and Validation](01-prerequisites-and-validation.md)

Use this first.
It explains what to install, what to check before LAB-01, and which validation script to run.
The root README explains how to use `Use this template`, create your own repository, and keep your own secrets and CI/CD history separate from the course template.

## 2. Understand the Stack

- [Architecture](02-architecture.md)
- [Runtime Stack](03-runtime-stack.md)
- [App GUI](04-app-gui.md)
- [Request And Data Flow](05-request-and-data-flow.md)

Read these before or during LAB-00 and LAB-01.
They explain the service layout, the Compose files, the role of each component, how requests and data move, what each GUI request does, and how the technical design answers the opening team request.

## 3. Follow the Observability Story

- [Logging](06-logging.md)
- [Monitoring](07-monitoring.md)

Read these during LAB-04 and LAB-05.
They explain how logs, metrics, request IDs, and the request cycle fit together.

## 4. Learn the Delivery Path

- [Registries](08-registries.md)
- [Azure Key Vault and Secrets Flow](09-secrets-and-azure-key-vault.md)
- [VM Deployment](10-vm-deployment.md)

Read these during LAB-06 and LAB-07.
They explain image publishing, how Azure Key Vault feeds the deployment workflow, and how the Linux VM target works when you want the production-like path.

## 5. Use When Something Breaks

- [Troubleshooting](11-troubleshooting.md)

Keep this open during LAB-08 and during instructor checkpoints.

## 6. Review Improvement Notes

- [Trainee Validation Findings](12-trainee-validation-findings.md)

Use this after a full dry run.
It captures real friction points found while following the project like a student.

## 7. Fill The Guided Gaps

- [Trainee Gap Map](13-trainee-gap-map.md)

Use this before you start editing the trainee version.
It explains which parts are intentionally incomplete and which file each team should change first.

## Milestone Validation Scripts

Run these at the matching points in the journey:

- `bash scripts/validate-prerequisites.sh`
- `bash scripts/validate-local-stack.sh foundation`
- `bash scripts/validate-local-stack.sh full`
- `bash scripts/validate-observability.sh`
- `bash scripts/validate-vm-deployment.sh http://YOUR_VM_OR_LOCAL_URL`
- `bash scripts/validate-runtime-contract.sh local`
- `bash scripts/validate-runtime-contract.sh vm http://127.0.0.1`
- `bash scripts/validate-doc-journey.sh`
- `bash scripts/validate-project.sh`

Run the runtime contract validator only after the matching stack is already up.

Think of the environment choice this way:

- use the VM validator when you are practicing the recommended image-based deployment path
- use the local validators when you are learning or troubleshooting quickly
- treat the local path as the fallback or parallel path when the VM route is not available yet
- these are two aligned target environments, with the VM route remaining the recommended one

Reset helpers for safe retries:

- `bash scripts/reset-local-lab.sh`
- `bash scripts/reset-vm-lab.sh`
