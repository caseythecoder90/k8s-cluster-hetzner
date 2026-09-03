# CKAD practice — Exam Set 2 (original questions)

A second full 19-question set, built to the same difficulty and CKAD topic
weighting as killer.sh — but **not copied from it**. Original scenarios,
generated to fill gaps Exam Set 1 (`../scenarios/`) never touched: RBAC,
NetworkPolicy, StatefulSets/headless Services, rollback, canary deployments,
taints/tolerations, Helm, and Kustomize.

Same framework, same conventions as Set 1: `setup.sh` / `TASK.md` /
`verify.sh` / `solution.md` per question, run against the same lab cluster.
Uses `/course2/N/...` for file-output tasks (Set 1 uses `/course/N/...`) so
both sets' fixtures never collide if you ever ran both in one session.

## Workflow

```bash
./setup-all.sh          # build all 19 starting states
cat TASKS-ALL.md         # read the questions
# ...solve on the control plane, exam-style...
./verify-all.sh          # score yourself
```

## One question mutates real node state

**q17** taints `lab-worker-1` (`dedicated=helios:NoSchedule`) to test
tolerations. This is safe to leave in place for the rest of your session —
all other questions' pods carry no matching requirement, so they schedule
freely on either node (both nodes are schedulable in this lab; the taint
only blocks *new* pods without a toleration from landing on the worker,
and the pods here are tiny). It disappears when the lab cluster is
destroyed. If you want it gone sooner:

```bash
ssh -i ~/.ssh/hetzner_k8s deploy@<cp-ip> "kubectl taint nodes lab-worker-1 dedicated=helios:NoSchedule-"
```

## Topic map (vs. curriculum weight)

| # | Topic | Weight area |
|---|---|---|
| q01 | find-by-label across namespaces, output to file | warm-up |
| q02 | ConfigMap as env (`envFrom` + explicit `env`) | Config/Security |
| q03 | CronJob: schedule, concurrencyPolicy, history limits | Deployment |
| q04 | Canary via shared Service selector | Services/Networking |
| q05 | RBAC: Role + RoleBinding, `auth can-i` | Config/Security |
| q06 | Broken rollout → `rollout undo` | Deployment |
| q07 | Sidecar sharing a volume (log shipper) | Design/Build |
| q08 | readinessProbe (exec, file marker) | Observability |
| q09 | Pod→Deployment + ConfigMap volume + resource limits | Design/Build, Config |
| q10 | Debug CrashLoopBackOff, fix command, document root cause | Observability |
| q11 | Docker build/tag/push — study card, not reproduced | Design/Build |
| q12 | NetworkPolicy: allow one app, deny the rest | Services/Networking |
| q13 | Static PV (hostPath) + PVC binding, no provisioner | Config/Security |
| q14 | StatefulSet + headless Service DNS | Services/Networking |
| q15 | Secret volume with `defaultMode` | Config/Security |
| q16 | initContainer: wait-for-dependency pattern | Design/Build |
| q17 | Taints/tolerations + nodeSelector | Deployment |
| p1 | Helm: install/upgrade a local chart | Design/Build |
| p2 | Kustomize: overlay patch + common label + image tag | Design/Build |
