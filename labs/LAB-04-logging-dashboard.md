# LAB-04 Logging Dashboard

## Goal

Use Grafana Explore and CLI logs to investigate real requests.

## Why This Lab Matters

Metrics can tell students that something changed, but logs show the exact request. This lab teaches request-level troubleshooting with both the UI and the command line.

## Before You Start

Keep the local stack running.

Complete guided gaps `OBS-01`, `OBS-02`, and `OBS-03` from [Trainee Gap Map](../docs/13-trainee-gap-map.md) before expecting the full Grafana and Loki path to work.

Open:

- the app GUI at `http://localhost:8080`
- Grafana at `http://localhost:3000`

If no requests were sent yet, generate a few from the GUI first so logs exist.

## Files Used

- `monitoring/loki/loki-config.yml`
- `monitoring/promtail/promtail-config.yml`
- `app/src/logger.js`
- `logs/app/app.log`
- `logs/nginx/access.log`
- `logs/nginx/error.log`

## Commands to Run

```bash
docker compose logs app --tail=50
docker compose logs nginx --tail=50
docker compose logs postgres --tail=50
docker compose logs redis --tail=50
tail -f logs/nginx/access.log
tail -f logs/nginx/error.log
bash scripts/validate-observability.sh
```

## What To Do

1. Click `Generate Slow Request`.
2. Click `Generate Error`.
3. Click `Load Library Records`.
4. Click `Test Popular Titles Cache`.
5. In Grafana Explore, find the app logs for `/slow` and `/error`.
6. In Grafana Explore, find the matching Nginx logs.
7. Compare those results with `docker compose logs`.

## Expected Output

- app logs appear in Grafana Explore
- Nginx access and error logs appear in Grafana Explore
- `/error` creates a `500` response
- `/slow` creates visible latency
- students can correlate one request across GUI action, Nginx log, and app log

Expected log investigation pattern reference:

![Expected logs flow](../docs/images/vm-log-flow.svg)

Use this image as the known-good request-cycle pattern.
In the trainee-facing version, if `OBS-02` or `OBS-03` is still incomplete, students should first confirm that same pattern in CLI logs and app log files before expecting the full Grafana Explore path to work.

## Checkpoint Questions

- Which GUI action generated the `500` error?
- Which request was slow?
- Did the request reach Nginx?
- Did the request reach the app?
- What did Grafana Explore make easier than CLI logs?
- What did CLI logs make more precise than the UI?

## Common Issues

- Grafana Explore opens before Promtail catches up
- `logs/app/app.log` does not exist yet because no request was sent
- guided observability placeholders were not completed yet
- students search only one log source and miss the full request cycle

## Team Task Split

- Student 1 generates traffic from the GUI
- Student 2 uses Grafana Explore
- Student 3 uses CLI logs
- Student 4 compares the findings and traces the full request cycle

## Instructor Checkpoint

Ask every team to show one slow request and one `500` request in both the UI and the CLI, then explain why both views are useful.

## Validation

Run:

```bash
bash scripts/validate-observability.sh
```

## Known Good End State

- Running: `grafana`, `loki`, and `promtail` are up, and app plus Nginx logs are being written.
- Endpoint: the GUI still responds and `/slow` plus `/error` create visible log events.
- Confirm with: `bash scripts/validate-observability.sh`
- Expected logs: app logs include `request started`, `request completed`, and `request failed`; Nginx access log includes `/slow` and `/error`.
- Common failure: Grafana is up but no fresh traffic was generated, so the log search looks empty.
- Safe retry: click `Generate Slow Request` and `Generate Error` again, then search by `request_id` in Grafana Explore or `logs/app/app.log`

## Next Step

Read [Monitoring](../docs/07-monitoring.md), then continue to [LAB-05 Metrics and Grafana](LAB-05-metrics-and-grafana.md).
