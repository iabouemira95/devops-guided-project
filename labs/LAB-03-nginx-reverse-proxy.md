# LAB-03 Nginx Reverse Proxy

## Goal

Understand Nginx as the single public entry point.

## Why This Lab Matters

Students have already used the app. Now they need to understand how traffic actually enters the system and why we avoid exposing every service directly.

## Before You Start

Keep the local stack running from LAB-01 and LAB-02.

Read [Logging](../docs/06-logging.md) after this lab, not before. First understand the request path.

## Files Used

- `docker/nginx/nginx.conf`
- `docker-compose.yml`
- `logs/nginx/access.log`
- `logs/nginx/error.log`

## Commands to Run

```bash
docker compose logs nginx --tail=50
tail -f logs/nginx/access.log
```

## What To Do

1. Open the GUI through `http://localhost:8080`.
2. Click `Check Health`.
3. Click `Load Items from PostgreSQL`.
4. Watch the Nginx access log while the requests happen.
5. Open `docker/nginx/nginx.conf` and identify where requests are forwarded.

## Expected Output

- requests come through `http://localhost:8080`
- Nginx access log entries appear in `logs/nginx/access.log`
- students can explain that Nginx receives the request first and forwards it to the app

## Checkpoint Questions

- What problem does Nginx solve here?
- Why do we want one public entry point?
- Why is `/metrics` not exposed publicly through Nginx?
- Which evidence shows that the request reached Nginx?

## Common Issues

- Nginx started before the app was healthy
- Nginx config was edited incorrectly
- students inspect the app first and forget to confirm the proxy path

## Team Task Split

- Student 1 uses the GUI
- Student 2 tails the Nginx access log
- Student 3 reads the Nginx config
- Student 4 explains the request path from browser to app

## Instructor Checkpoint

Have one team narrate the full path of a request from browser to Nginx to the app, and point to both the config and the access log while explaining it.

## Validation

Re-run:

```bash
bash scripts/validate-local-stack.sh foundation
```

## Known Good End State

- Running: `nginx` stays healthy and is the only public entry point.
- Endpoint: `http://localhost:8080/version` responds through Nginx, not a direct app port.
- Confirm with: `docker compose logs nginx --tail=20`
- Expected logs: Nginx access logs show the request path and response status for GUI traffic.
- Common failure: students use port `3000` directly and skip the reverse proxy path.
- Safe retry: return to `http://localhost:8080`, repeat one GUI action, then inspect `logs/nginx/access.log`

## Next Step

Read [Logging](../docs/06-logging.md), then continue to [LAB-04 Logging Dashboard](LAB-04-logging-dashboard.md).
