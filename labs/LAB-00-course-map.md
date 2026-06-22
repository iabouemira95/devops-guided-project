# LAB-00 Course Map

## Goal

Understand the full project story before you start running commands.

## Working Scenario

Treat this project like a real request arriving to a DevOps team:

> "Take this small service, make it runnable in containers, expose it through one safe entry point, add logs and metrics, publish it through CI, deploy it to a VM, and make recovery straightforward."

LAB-00 helps students translate that request into a technical delivery plan.

## Why This Lab Matters

This project is not mainly about app code. It is about learning how one small service moves through a realistic DevOps journey:

`code -> run -> observe -> package -> push -> deploy -> verify -> recover`

If students understand that story first, the later labs feel connected instead of scattered.

The important learning point is that the service can be validated in two target environments:

- on a Linux VM, as the recommended production-like deployment path
- locally, as the fast-feedback fallback or parallel path

## Before You Start

Have the root [README](../README.md) open.

If you have not checked your machine yet, read [Prerequisites and Validation](../docs/01-prerequisites-and-validation.md) before moving into LAB-01.

## Files Used

- `README.md`
- `docs/02-architecture.md`
- `docs/03-runtime-stack.md`
- `docs/05-request-and-data-flow.md`

## What To Review

Read these in order:

1. [Architecture](../docs/02-architecture.md)
2. [Runtime Stack](../docs/03-runtime-stack.md)
3. [Request And Data Flow](../docs/05-request-and-data-flow.md)

As you read, make sure you can point to:

- what the incoming team request is really asking for
- where the browser connects first
- where the app runs
- where PostgreSQL and Redis fit
- where logs go
- where metrics go
- how the image reaches the VM later

## Expected Output

Students can explain the project in one short sentence, for example:

`A small app runs behind Nginx, uses PostgreSQL and Redis, sends logs and metrics to the observability stack, then gets packaged and deployed to a VM.`

They should also be able to explain why that design answers the original team request.

## Checkpoint Questions

- Why do we have both logs and metrics?
- Why is Nginx the public entry point?
- Why do we keep the app simple?
- Why does the course teach local validation before VM deployment?
- When would you stay on the local path, and when would you switch to the VM path?

## Common Issues

- students jump into commands before understanding the stack
- students treat Grafana, Prometheus, Loki, and Nginx as separate tools instead of one system
- students do not yet know which components are public and which stay private

## Team Task Split

- Student 1 explains the app and GUI
- Student 2 explains Docker Compose, PostgreSQL, and Redis
- Student 3 explains Nginx, logs, and metrics
- Student 4 explains CI/CD, registry, and VM deployment

## Instructor Checkpoint

Ask each team to restate the incoming request in their own words, then describe the full system story in one sentence while pointing to the architecture diagram.

## Validation

Before LAB-01, complete the prerequisite validator:

```bash
bash scripts/validate-prerequisites.sh
```

## Known Good End State

- Running: no project services need to be running yet.
- Endpoint: not applicable in this lab because this step is about understanding the system before execution.
- Confirm with: `bash scripts/validate-prerequisites.sh`
- Expected output: students can explain the system story and identify the public entry point, app, database, cache, logs, metrics, and deployment path.
- Common failure: students skip the architecture reading and jump straight into commands.
- Safe retry: reopen [README](../README.md), [02-architecture](../docs/02-architecture.md), and [03-runtime-stack](../docs/03-runtime-stack.md), then restate the request and system flow in one sentence.

## Next Step

Read [Architecture](../docs/02-architecture.md), then continue to [LAB-01 Run Locally and Use GUI](LAB-01-run-locally-and-use-gui.md).
