# Q3 solution

```bash
k -n zeus create cronjob zeus-backup --image=busybox:1 --schedule="*/5 * * * *" \
  $do -- sh -c "echo backup run" > cj.yaml
vim cj.yaml
```

```yaml
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 1
  jobTemplate:
    ...
```

```bash
k apply -f cj.yaml
k -n zeus get cronjob zeus-backup
```

Trap: `concurrencyPolicy` and both history-limit fields live at the
**CronJob's own `spec`** level — a sibling of `schedule` and `jobTemplate` —
not inside `jobTemplate.spec`. Easy to nest one level too deep by mistake.

To force an immediate run without waiting for the schedule (useful to sanity
check it works): `k create job --from=cronjob/zeus-backup zeus-backup-manual -n zeus`.
