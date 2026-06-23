# App GUI

The GUI is called **Library Operations Control Panel**.

It is not a frontend project.

It is a simple helper for:

- generating traffic
- checking service behavior
- creating logs
- creating metrics
- explaining how each request is processed

## Buttons

- Check Health
- Check Readiness
- Show Version
- Load Library Records
- Create Demo Checkout
- Test Popular Titles Cache
- Generate Slow Request
- Generate Error
- Open Grafana Dashboard
- Open Grafana Logs
- Open Prometheus

## Request Types in the GUI

| Button | Route | Main Teaching Point | Dependencies |
| --- | --- | --- | --- |
| Check Health | `GET /health` | process health only | none |
| Check Readiness | `GET /ready` | dependency readiness | PostgreSQL, Redis |
| Show Version | `GET /version` | deployment metadata | none |
| Load Library Records | `GET /items` | read path through database | PostgreSQL |
| Create Demo Checkout | `POST /items` | write path through database | PostgreSQL |
| Test Popular Titles Cache | `GET /cache-demo` | cache miss vs cache hit | Redis |
| Generate Slow Request | `GET /slow` | latency in logs and metrics | none |
| Generate Error | `GET /error` | 500 response and error logs | none |

## What the GUI Is Technically

The GUI is:

- a server-rendered HTML page
- styled with plain CSS
- powered by plain browser-side JavaScript
- served by the same Express app as the API

This matters because students can inspect one service and still learn:

- browser traffic
- API requests
- reverse proxy behavior
- logs
- metrics

without adding a separate frontend build system.

## Request Flow Panel

Each traffic button now explains:

- which route is called
- whether Nginx, PostgreSQL, or Redis are involved
- which logs should change
- which metrics should move
- what students should inspect next

This keeps the GUI focused on DevOps reasoning instead of only showing raw JSON responses.

## Why Each Request Type Exists

### `/health`

Use it to answer:

- is the app process alive?
- can Nginx reach the app?

### `/ready`

Use it to answer:

- can the app reach PostgreSQL?
- can the app reach Redis?
- is the service ready for real traffic?

### `/version`

Use it to answer:

- what version is running?
- what image tag is deployed?
- what environment is this?

### `/items`

Use it to answer:

- is PostgreSQL reachable?
- can the app read and write believable library circulation data?

### `/cache-demo`

Use it to answer:

- is Redis reachable?
- what does a cache miss look like for popular titles?
- what does a cache hit look like?

### `/slow`

Use it to answer:

- how does a slow request appear in logs?
- how does latency appear in metrics?

### `/error`

Use it to answer:

- how does a 500 error look in logs?
- how do error counts move in metrics?

## Full Request Cycle In Logs

Each request now creates a clearer cycle in the app logs:

1. `request started`
2. route-specific events such as:
   - `dependency readiness checked`
   - `postgres items loaded`
   - `postgres item created`
   - `redis cache hit`
   - `redis cache miss`
   - `slow request simulation started`
   - `slow request simulation completed`
3. `request completed` or `request failed`

This makes it easier for trainees to follow one full request from entry to outcome.

## How the GUI Fits the Course Story

The GUI is not the lesson by itself.

It is the easiest way to generate predictable traffic so students can then inspect:

- Nginx behavior
- app behavior
- database behavior
- cache behavior
- logs
- metrics
- deployment metadata

## Observability Shortcuts

The shortcut behavior changes with where the app is running:

- local stack: Grafana and Prometheus open directly on the current machine
- VM path: the shortcuts point to `localhost` so they work after the SSH tunnel is created

## Why the GUI Matters

Students can use one simple page instead of writing curl commands for every action.

That keeps the focus on:

- traffic
- logs
- metrics
- deployment

## Next Step

Read [Request And Data Flow](05-request-and-data-flow.md), then start [LAB-01 Run Locally and Use GUI](../labs/LAB-01-run-locally-and-use-gui.md).
