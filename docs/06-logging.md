# Logging

This project keeps logging simple and visible.

## Log Sources

- app structured JSON logs
- Nginx access log
- Nginx error log
- PostgreSQL container logs in CLI
- Redis container logs in CLI

## App Log Cycle

For one GUI action, trainees should expect to see this log pattern:

1. `request started`
2. route-specific work log
3. `request completed` for success

For a failing request such as `/error`, trainees should expect:

1. `request started`
2. `request failed`
3. Nginx access log entry with `500`

## Where Students Look

### Grafana Explore

Use Grafana Explore for:

- app logs from Loki
- Nginx logs from Loki
- request-by-request correlation after the GUI shows a request ID

Starter queries:

```text
{service="app"}
{service="nginx"}
{service="nginx", log_type="error"}
```

In the trainee-facing version, Grafana Explore becomes fully useful only after:

- `OBS-02` restores the app log path into Promtail
- `OBS-03` restores the Loki datasource in Grafana

## Expected Logs Flow Screenshot

This image is a reference pattern for the request-cycle evidence students should expect once they trigger `/slow` and `/error` and inspect the app logs:

![Expected logs flow](images/vm-log-flow.svg)

It is not a screenshot of Grafana Explore itself.
Use it to understand the correct request sequence while `OBS-02` and `OBS-03` are still incomplete in the trainee-facing version.
After those gaps are completed, students should be able to find the same request pattern in Grafana Explore as well as in CLI logs.

### CLI Logs

Use:

```bash
docker compose logs app --tail=50
docker compose logs nginx --tail=50
docker compose logs postgres --tail=50
docker compose logs redis --tail=50
```

### Nginx File Logs

```bash
tail -f logs/nginx/access.log
tail -f logs/nginx/error.log
```

## Why PostgreSQL and Redis Stay in CLI Logs

This course is not trying to build a full centralized logging platform.

For the guided project:

- app logs and Nginx logs are enough for the main troubleshooting story
- PostgreSQL and Redis stay visible with normal container log commands

## What Loki Is Doing

Loki stores the logs that Grafana Explore reads.

Promtail sends:

- `logs/app/app.log`
- `logs/nginx/access.log`
- `logs/nginx/error.log`

That is enough to correlate:

- slow requests
- 500 errors
- Nginx traffic
- app handling
- the same request ID between GUI output and app logs

In the trainee-facing version, that full path is intentionally incomplete until the guided observability gaps are finished.

## What A Full Request Investigation Looks Like

Example with `GET /slow`:

1. trigger the slow route from the GUI
2. copy the `request_id` from the response panel
3. search the app logs for that `request_id`
4. confirm `request started`
5. confirm `slow request simulation started`
6. confirm `slow request simulation completed`
7. confirm `request completed`
8. check the matching Nginx access log entry
9. confirm the latency spike in Grafana

## Request ID Correlation

The request ID is the simplest way to follow one user action across the stack.

Where it appears:

- in the GUI response panel
- in the `X-Request-Id` response header
- in the structured app log lines for that request

How to use it:

1. trigger one GUI action
2. copy the `request_id`
3. search the app logs for that value
4. confirm the sequence of `request started`, route-specific logs, and `request completed` or `request failed`
5. compare the timestamp and path with the matching Nginx access log entry

What this teaches:

- metrics can show that latency or errors changed
- the request ID helps you identify which exact request explains that change
- this is close to real production debugging, where one request often needs to be followed across several signals

## Component Roles During Log Investigation

- browser tells you which action was triggered
- Nginx tells you whether the request reached the platform and how long it took
- app logs tell you what the route actually did
- PostgreSQL and Redis CLI logs help when the request depends on a backing service
- Grafana Explore helps correlate app and Nginx logs in one place

## Validation Path For Logging

Use:

1. GUI button
2. app logs
3. Nginx access log
4. Grafana Explore
5. `bash scripts/validate-observability.sh`

If the trainee-facing placeholders are still present, treat that validator failure as the expected signal to finish `OBS-01`, `OBS-02`, and `OBS-03`.

## Next Step

Continue to [Monitoring](07-monitoring.md), then run [LAB-05 Metrics and Grafana](../labs/LAB-05-metrics-and-grafana.md).
