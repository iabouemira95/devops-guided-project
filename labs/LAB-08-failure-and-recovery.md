# LAB-08 Failure and Recovery

## Goal

Observe failures, gather evidence, and recover the service.

## Why This Lab Matters

This is where the whole project comes together. Students should leave the course knowing how to move from symptom to evidence to recovery instead of restarting services blindly.

## Before You Start

Use either:

- the local stack from the earlier labs
- the VM deployment from LAB-07

Have these ready before creating a failure:

- the GUI
- Grafana dashboards
- Grafana Explore
- CLI logs

## Files Used

- `docker-compose.yml`
- `docker-compose.vm.yml`
- `docker/nginx/nginx.conf`
- `docs/06-logging.md`
- `docs/07-monitoring.md`
- `docs/11-troubleshooting.md`

## Commands to Run

```bash
docker compose ps
docker compose logs app --tail=50
docker compose logs nginx --tail=50
docker compose logs postgres --tail=50
docker compose logs redis --tail=50
```

## What To Do

Work through these failure scenarios one at a time:

1. app container stopped
2. Redis stopped
3. PostgreSQL stopped
4. Nginx config broken
5. app returns `500` from `/error`

For each scenario:

1. observe the symptom in the GUI
2. check metrics
3. check logs
4. identify the most likely root cause
5. recover the service
6. repeat the same request and confirm the result changed

## GUI Actions to Click

- Check Health
- Check Readiness
- Generate Error
- Load Items from PostgreSQL
- Test Redis Cache

## Expected Output

Teams can explain, for at least one scenario:

`symptom -> evidence -> root cause -> recovery -> verification`

They should also be able to say which signal came first:

- GUI symptom
- metric change
- log evidence
- service status

## Checkpoint Questions

- What symptom did the GUI show first?
- What did metrics show?
- What did logs show?
- Which command or action fixed the issue?
- How did you verify the service was healthy again?

## Common Issues

- students restart a service before collecting evidence
- students use only logs or only metrics instead of both
- students fix the symptom but do not rerun the original check

## Team Task Split

- Student 1 observes the GUI symptom
- Student 2 checks metrics
- Student 3 checks logs
- Student 4 performs the recovery step

## Instructor Checkpoint

Every team must explain one full chain:

`symptom -> evidence -> root cause -> recovery`

## Validation

Re-run the milestone validators for the part of the journey you want to confirm:

```bash
bash scripts/validate-local-stack.sh foundation
bash scripts/validate-local-stack.sh full
bash scripts/validate-observability.sh
bash scripts/validate-project.sh
```

If you are validating the VM path, also run:

```bash
bash scripts/validate-vm-deployment.sh http://YOUR_VM_PUBLIC_IP
```

## Known Good End State

- Running: the service returns to a healthy state after the chosen failure is recovered.
- Endpoint: the original failing check now succeeds again, such as `/ready`, `/items`, or the GUI action that first showed the problem.
- Confirm with: rerun the matching validator and the original GUI action.
- Expected logs: recovery steps produce new healthy log lines after the earlier failure evidence.
- Common failure: students restart a service before collecting enough evidence, then cannot explain the root cause.
- Safe retry: create one failure at a time, collect GUI symptom, metrics, logs, and service status first, then recover and rerun the same check

## Next Step

Return to [README](../README.md) for the full project map and use [docs/12-trainee-validation-findings.md](../docs/12-trainee-validation-findings.md) to record any issues you want to improve later.
