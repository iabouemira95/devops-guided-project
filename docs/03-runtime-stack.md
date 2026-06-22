# Runtime Stack

Use this document when you want a simple technical explanation of how the app, Dockerfile, and Compose stack fit together.

## Goal

Explain the runtime pieces clearly enough that a trainee can:

- open the right file
- understand why the file exists
- predict what will happen when the stack starts
- troubleshoot one layer at a time

## App Layer

Main app files:

- `app/src/server.js`
- `app/src/db.js`
- `app/src/redis.js`
- `app/src/logger.js`
- `app/src/metrics.js`
- `app/src/public/index.html`
- `app/src/public/app.js`

What the app does:

- serves the GUI at `/`
- serves JSON APIs such as `/health`, `/ready`, `/version`, `/items`, and `/cache-demo`
- logs each request with structured JSON
- exposes Prometheus metrics at `/metrics`
- connects to PostgreSQL for item storage
- connects to Redis for the cache demo

In the trainee-facing version, some of that runtime behavior is intentionally incomplete at first:

- `DOCKER-01` leaves the app container start command unfinished
- `APP-01` leaves the Redis cache demo route unfinished
- `OBS-01`, `OBS-02`, and `OBS-03` leave parts of the full observability path unfinished

Use [13-trainee-gap-map](13-trainee-gap-map.md) when you want to understand which runtime pieces are intentionally missing in the starter version.

Why this app is intentionally small:

- students should spend time on runtime and delivery behavior
- students should not lose time on backend business logic
- every route exists to teach one operational concept

## Dockerfile

Main file:

- `docker/app.Dockerfile`

What it does:

1. starts from a Node.js 24 LTS image
2. copies the package files first
3. runs `npm ci`
4. copies the application source
5. prepares the log directory
6. runs the app as the container process

In the trainee-facing version, `DOCKER-01` intentionally leaves the final app start command unfinished.
Students complete that first so the local stack can become usable before the later runtime and CI/CD labs.

Why the file is structured this way:

- package files are copied first so Docker layer caching works better
- `npm ci` gives repeatable installs from the lockfile
- the app image stays focused on one service only

## Compose Files

Main files:

- `docker-compose.yml`
- `docker-compose.vm.yml`

### `docker-compose.yml`

Purpose:

- local guided learning stack
- builds the app image from local source

When to use it:

- LAB-01 to LAB-05
- local troubleshooting
- local milestone validation

### `docker-compose.vm.yml`

Purpose:

- VM deployment stack
- pulls the app image from a registry

When to use it:

- LAB-07 VM deployment
- deployment smoke tests
- redeploying an older image tag

## Services in Compose

### `app`

Purpose:

- runs the Node.js service
- serves the GUI and API
- writes structured logs
- exposes `/metrics` internally

Important details:

- depends on PostgreSQL and Redis health
- mounts `./logs/app` to keep app logs visible on the host

### `postgres`

Purpose:

- stores the `items` table

Important details:

- uses `db/init.sql`
- stores persistent data in a named volume
- is checked by `/ready`

### `redis`

Purpose:

- supports the cache demo route

Important details:

- used only for simple cache teaching
- is checked by `/ready`

### `nginx`

Purpose:

- one public entry point
- forwards browser traffic to the app
- writes access and error logs

Important details:

- exposes `8080` locally and `80` on the VM
- blocks public access to `/metrics`
- makes request flow visible in access logs

### `prometheus`

Purpose:

- scrapes and stores metrics from the app

Important details:

- scrapes the app on the internal network
- is public locally
- is localhost-only on the VM by default

### `grafana`

Purpose:

- main observability UI
- dashboards for metrics
- Explore view for logs

Important details:

- uses provisioned data sources and dashboards
- is public locally
- is localhost-only on the VM by default

### `loki`

Purpose:

- stores app and Nginx logs

Important details:

- not public
- queried through Grafana

### `promtail`

Purpose:

- reads the log files and ships them to Loki

Important details:

- reads:
  - `logs/app/app.log`
  - `logs/nginx/access.log`
  - `logs/nginx/error.log`

## Networks, Volumes, and Log Paths

The Compose stack uses one default internal network.

That means:

- containers talk to each other by service name
- the browser should reach the stack through Nginx, not the app container directly

Important storage paths:

- app logs: `logs/app/app.log`
- Nginx access log: `logs/nginx/access.log`
- Nginx error log: `logs/nginx/error.log`
- PostgreSQL data: named Docker volume

## Environment Variables

Main files:

- `.env.example`
- `deploy/example.env`
- `deploy/example.secrets.env`

The project separates:

- stable configuration
- secret values

Examples of stable configuration:

- app name
- environment
- image tag
- database host
- Redis host

Examples of secret values:

- PostgreSQL password
- Grafana admin password
- registry credentials

## How a Normal Request Moves

Example: `GET /items`

1. browser calls Nginx
2. Nginx forwards the request to the app
3. app logs `request started`
4. app queries PostgreSQL
5. app returns JSON
6. app logs route-specific details and `request completed`
7. Nginx writes the access log entry
8. Prometheus request metrics update
9. Promtail ships app and Nginx logs to Loki
10. Grafana can show both the metric trend and the request logs

## How to Read the Stack During Troubleshooting

If the GUI does not load:

- check `nginx`
- check `app`

If `/ready` fails:

- check `postgres`
- check `redis`
- check app logs

If metrics are missing:

- check `prometheus`
- check app `/metrics`

If logs are missing in Grafana:

- check `promtail`
- check `loki`
- check whether the log files exist on disk

## Next Step

Return to [Architecture](02-architecture.md), then continue to [App GUI](04-app-gui.md).
