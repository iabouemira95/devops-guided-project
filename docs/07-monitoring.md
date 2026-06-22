# Monitoring

This project uses:

- Prometheus for metrics
- Grafana for dashboards
- Grafana Explore for logs from Loki

In the trainee-facing version, the Prometheus app scrape target, the Promtail app log path, and the Grafana Loki datasource are intentionally left as guided observability gaps.
Students should complete those before expecting full dashboards and full app logs in Grafana.

## Metrics Teach One Kind of Truth

Metrics answer questions like:

- is the service up?
- are requests increasing?
- are errors rising?
- is latency getting worse?
- is the database ready?
- is Redis ready?

## Expected Metrics Flow Screenshot

This is an example of the metric evidence students should expect when Prometheus is scraping the live app correctly:

![Expected metrics flow](images/vm-prometheus-metrics.png)

This screenshot is from the Prometheus UI, which is the simplest way to show that the raw metric exists and is changing.
In the guided project, students should still use the Grafana dashboard as the main metrics view during the lab, then use Prometheus when they need to confirm the underlying metric directly.

## Logs Teach Another Kind of Truth

Logs answer questions like:

- which request failed?
- which path was slow?
- did the request reach Nginx?
- did the request reach the app?
- what status code was returned?
- which request ID should we search for in logs after the GUI action?

## Main Student Message

- metrics show that something happened
- logs show what request happened and why

## Service Views Students Should Learn

- Grafana dashboard:
  use this first to see whether request rate, errors, latency, or readiness changed
- Grafana Explore:
  use this second to find the exact request and request ID
- CLI logs:
  use this when you need container-specific detail from PostgreSQL or Redis

## Good Monitoring Questions In This Project

- Did request rate change after I clicked a GUI action?
- Did latency rise after `/slow`?
- Did error count rise after `/error`?
- Did readiness fall when Redis or PostgreSQL was unavailable?
- Which logs explain the metric change I just saw?

Useful dashboard panels in this project:

- request rate by path
- error rate by path
- HTTP 500 rate by path
- readiness over time
- slow request latency P95 by path

## Metrics And Logs Together

Students should learn one simple sequence:

1. trigger traffic from the GUI
2. use Grafana dashboards to see whether latency, errors, or readiness changed
3. use Grafana Explore and CLI logs to explain the exact request path
4. rerun the same request after a fix and compare the result

## Validation Path For Monitoring

Use:

1. GUI traffic such as `/slow` or `/error`
2. Grafana dashboard panels
3. Prometheus readiness and request metrics
4. `bash scripts/validate-observability.sh`

## Next Step

Move to [LAB-06 GitHub Actions and Registry Publish](../labs/LAB-06-github-actions-acr.md).
