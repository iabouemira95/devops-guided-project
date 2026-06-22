# LAB-02 Compose Layers DB Cache

## Goal

Understand how the app depends on PostgreSQL and Redis.

## Why This Lab Matters

Students already know the app responds. Now they need to see that a real service usually depends on more than one container, and that readiness means more than “the process started.”

## Before You Start

Keep the local stack running from LAB-01.

Before expecting the Redis cache button to work, complete guided gap `APP-01` from [Trainee Gap Map](../docs/13-trainee-gap-map.md).

If the stack was stopped, restart it:

```bash
docker compose up --build
```

## Files Used

- `docker-compose.yml`
- `db/init.sql`
- `app/src/db.js`
- `app/src/redis.js`

## Commands to Run

```bash
docker compose ps
docker compose logs postgres --tail=30
docker compose logs redis --tail=30
```

## What To Do

1. Click `Load Items from PostgreSQL`.
2. Click `Create Demo Item`.
3. Click `Test Redis Cache` twice.
4. Click `Check Readiness`.
5. Read the PostgreSQL and Redis logs while you repeat one of those actions.

## Expected Output

- seed items load from PostgreSQL
- a new item is created in PostgreSQL
- the cache demo first shows an app-generated value, then a cached value
- readiness confirms DB and Redis reachability

## Checkpoint Questions

- What does `/ready` check that `/health` does not?
- Which GUI action touched PostgreSQL?
- Which GUI action demonstrated Redis?
- Why do we want both direct API behavior and dependency checks?

## Common Issues

- PostgreSQL is still starting and not healthy yet
- Redis is not ready yet
- students click too early before the stack finishes settling

## Team Task Split

- Student 1 uses the GUI
- Student 2 explains the database flow
- Student 3 explains the cache flow
- Student 4 verifies readiness and service health

## Instructor Checkpoint

Ask teams to explain one request that touched PostgreSQL and one that touched Redis, then explain why readiness is more meaningful than health for this lab.

## Validation

Re-run:

```bash
bash scripts/validate-local-stack.sh full
```

## Known Good End State

- Running: `postgres` and `redis` are healthy and the app remains healthy.
- Endpoint: `http://localhost:8080/ready` returns `db_ready` and `redis_ready`.
- Confirm with: `bash scripts/validate-local-stack.sh full`
- Expected logs: `docker compose logs postgres --tail=20` and `docker compose logs redis --tail=20` show recent activity after GUI actions.
- Common failure: students click before PostgreSQL or Redis is fully healthy.
- Safe retry: wait for `docker compose ps`, then rerun `Load Items`, `Test Redis Cache`, and `Check Readiness`

## Next Step

Continue to [LAB-03 Nginx Reverse Proxy](LAB-03-nginx-reverse-proxy.md).
