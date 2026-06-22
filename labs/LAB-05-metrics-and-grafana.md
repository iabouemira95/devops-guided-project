# LAB-05 Metrics and Grafana

## Goal

Use metrics to understand service behavior over time.

## Why This Lab Matters

Logs explain one request. Metrics help students see patterns across many requests, such as rising latency, repeated errors, or failing dependencies.

## Before You Start

Complete LAB-04 first so students already know how to inspect the same events in logs.
In the trainee-facing version, confirm `OBS-01` is complete before expecting Prometheus-backed panels to move correctly.

Open Grafana before starting this lab.

## Files Used

- `monitoring/prometheus/prometheus.yml`
- `monitoring/grafana/dashboards/devops-overview.json`
- `app/src/metrics.js`

## Commands to Run

```bash
docker compose logs prometheus --tail=30
docker compose logs grafana --tail=30
```

## What To Do

1. Click `Generate Slow Request` a few times.
2. Click `Generate Error`.
3. Click `Check Readiness`.
4. Watch the Grafana dashboard and identify which panels changed.
5. Compare one metric change with the matching logs from LAB-04.

## Expected Output

- request rate increases after traffic is generated
- error count changes after `/error`
- latency rises after `/slow`
- DB and Redis readiness gauges show current state

Expected raw metrics reference:

![Expected metrics flow](../docs/images/vm-prometheus-metrics.png)

This screenshot shows the underlying metric in Prometheus, not the final Grafana dashboard layout.
Use it as proof of what a healthy metric signal looks like, while keeping Grafana as the primary dashboard surface for this lab.

## Checkpoint Questions

- What can the dashboard tell you quickly?
- What can the dashboard not tell you without logs?
- Which metric changed after `/slow`?
- Which metric changed after `/error`?

## Common Issues

- dashboard looks empty because no traffic was generated
- students expect metrics to explain the exact request without checking logs

## Team Task Split

- Student 1 generates traffic
- Student 2 reads the dashboard
- Student 3 correlates metrics with logs
- Student 4 explains readiness gauges

## Instructor Checkpoint

Teams must explain one thing they learned from metrics and one thing they still needed logs to understand.

## Validation

Run:

```bash
bash scripts/validate-observability.sh
```

## Known Good End State

- Running: Prometheus and Grafana are reachable and the dashboard panels move after traffic.
- Endpoint: `/slow`, `/error`, and `/ready` all create metric changes you can see.
- Confirm with: `bash scripts/validate-observability.sh`
- Expected logs: logs still show the request-level detail that explains the metric change.
- Common failure: the dashboard looks static because only one request was sent or no new traffic was generated.
- Safe retry: generate `/slow` a few times, trigger `/error`, then refresh the dashboard range

## Next Step

Continue to [LAB-06 GitHub Actions and Registry Publish](LAB-06-github-actions-acr.md).
