# Request And Data Flow

Use this document after `Architecture`, `Runtime Stack`, and `App GUI`.

It explains how requests move, how data moves, which component is responsible for what, and how trainees validate each part.

## Goal

Help trainees answer four questions clearly:

1. Where does a request start?
2. Which component handles each part of the request?
3. Where does the data go?
4. How do we validate that the path worked?

## Component Roles

### Browser

Role:

- sends user requests
- displays the GUI
- displays API responses

What students should notice:

- the browser always talks to Nginx first
- the GUI is a traffic generator, not a separate frontend platform

### Nginx

Role:

- single public entry point
- forwards requests to the app
- records access and error logs

What students should notice:

- Nginx is the first server-side hop
- Nginx confirms whether the request reached the platform at all
- Nginx shows response status and request timing

### Express App

Role:

- serves the GUI
- serves the API
- coordinates PostgreSQL and Redis access
- emits structured logs
- exposes metrics

What students should notice:

- the app decides whether a request is simple, DB-backed, cache-backed, slow, or failing
- the app is the best place to see request IDs and route-specific details

### PostgreSQL

Role:

- stores persistent relational data for `items`

What students should notice:

- only `/items` read and write routes need PostgreSQL
- `/ready` uses PostgreSQL as part of dependency validation

### Redis

Role:

- supports the cache demo

What students should notice:

- `/cache-demo` is the clearest Redis teaching route
- `/ready` also checks Redis connectivity

In the trainee-facing version, `/cache-demo` starts as guided gap `APP-01`.
That means Redis is present in the stack, but the trainee must finish the app route before the full cache behavior appears.

### Prometheus

Role:

- scrapes and stores metrics from the app

What students should notice:

- Prometheus answers whether traffic, errors, or latency changed
- Prometheus does not explain one request by itself

### Loki

Role:

- stores app logs and Nginx logs

What students should notice:

- Loki helps correlate request-level events
- this course intentionally keeps Loki scope narrow

In the trainee-facing version, Loki integration is intentionally incomplete until `OBS-02` and `OBS-03` are finished.

### Promtail

Role:

- reads log files from the host and ships them to Loki

What students should notice:

- Promtail is glue, not a troubleshooting UI
- if logs are missing in Grafana, Promtail is one of the first places to check

In the trainee-facing version, the app log shipping path starts as guided gap `OBS-02`.

### Grafana

Role:

- main observability UI
- dashboards for metrics
- Explore for logs

What students should notice:

- dashboards answer “did something change?”
- Explore answers “which request changed and why?”

In the trainee-facing version, the Loki datasource starts as guided gap `OBS-03`.

## Request Flow Examples

### `GET /health`

Flow:

1. browser calls Nginx
2. Nginx forwards `/health` to the app
3. app returns process health
4. app logs the request
5. Nginx writes the access log
6. request metrics increase

Validation:

- GUI Health button works
- Nginx access log shows `GET /health`
- app log shows `request started` and `request completed`

### `GET /ready`

Flow:

1. browser calls Nginx
2. Nginx forwards `/ready` to the app
3. app checks PostgreSQL
4. app checks Redis
5. app updates readiness metrics
6. app returns dependency status
7. app and Nginx both log the request

Validation:

- response contains `db_ready` and `redis_ready`
- Grafana readiness panels move
- app log contains `dependency readiness checked`

### `GET /items`

Flow:

1. browser calls Nginx
2. Nginx forwards `/items`
3. app queries PostgreSQL
4. app returns rows
5. app logs database-backed request details
6. Nginx writes the access log

Validation:

- response contains `items`
- app log contains `postgres items loaded`
- PostgreSQL remains healthy in Compose

### `POST /items`

Flow:

1. browser sends POST through Nginx
2. app inserts a new row in PostgreSQL
3. app returns `201`
4. logs and metrics record the write path

Validation:

- response status is `201`
- Nginx access log shows `POST /items`
- reloading `/items` shows the new row

### `GET /cache-demo`

Flow:

1. browser calls Nginx
2. app checks Redis
3. on first call, app creates and stores a value
4. on later calls, app returns the cached value
5. logs show cache miss or cache hit

Validation:

- first response shows app-generated source
- second response shows cache source
- app logs show `redis cache miss` or `redis cache hit`

Trainee note:

- in the trainee-facing version, this full route behavior appears only after completing `APP-01`

### `GET /slow`

Flow:

1. browser calls Nginx
2. app intentionally waits
3. app logs slow-path events
4. Nginx records a longer request time
5. metrics show latency change

Validation:

- response succeeds slowly
- Nginx access log has higher `request_time`
- app logs show slow-request events
- Grafana latency panels move

### `GET /error`

Flow:

1. browser calls Nginx
2. app raises the training error
3. app writes an error-level log
4. Nginx records `500`
5. metrics record the error

Validation:

- GUI shows a failed response
- app logs show `request failed`
- Nginx access log shows `500`
- error metrics move

## Data Flow Summary

Three main data paths exist in this project.

### Request and response data

- browser -> Nginx -> app -> browser

### Persistent business data

- app -> PostgreSQL -> app

### Cache data

- app -> Redis -> app

### Observability data

- app -> metrics -> Prometheus
- app log file -> Promtail -> Loki
- Nginx log files -> Promtail -> Loki
- Prometheus and Loki -> Grafana

## How Students Validate Integration

Use these checkpoints:

### Browser and proxy integration

- open the GUI
- click Health
- confirm Nginx access logs move

### App and dependency integration

- click Readiness
- confirm PostgreSQL and Redis are reported correctly

### Data integration

- load items
- create a demo item
- reload items

### Cache integration

- click Cache Demo twice
- compare the returned source field

### Logging integration

- trigger Slow and Error
- inspect app logs and Nginx logs

### Metrics integration

- trigger Slow and Error
- inspect Grafana panels

### Delivery integration

- inspect CI image tags
- deploy a specific image tag
- verify `/version`

## Main Validation Scripts And What They Prove

- `bash scripts/validate-prerequisites.sh`
  - proves the workstation is ready
- `bash scripts/validate-local-stack.sh foundation`
  - proves the local foundation stack and core routes except the intentional guided gaps
- `bash scripts/validate-local-stack.sh full`
  - proves the local stack including `APP-01`
- `bash scripts/validate-observability.sh`
  - proves the observability gaps are completed and metrics plus logging are wired
- `bash scripts/validate-vm-deployment.sh http://YOUR_VM_OR_LOCAL_URL`
  - proves the deployed runtime is healthy
- `bash scripts/validate-project.sh`
  - quick combined sanity check

## Next Step

Continue to [Logging](06-logging.md), then [Monitoring](07-monitoring.md).
