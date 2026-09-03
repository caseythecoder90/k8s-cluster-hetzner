# Exam Set 2 — all tasks (print/read this during a timed run)

Same pace target as Set 1: ~6 min/question average, ≈115 min for all 19.

| # | Topic | Namespace | New vs. Set 1? |
|---|---|---|---|
| q01 | find-by-label, output to file | myth-* | warm-up |
| q02 | ConfigMap as env (`envFrom` + `env`) | athena | variant |
| q03 | CronJob | zeus | **new** |
| q04 | Canary via shared Service selector | hermes | **new** |
| q05 | RBAC: Role + RoleBinding | apollo | **new** |
| q06 | Broken rollout → `rollout undo` | artemis | **new** |
| q07 | Sidecar sharing a volume | poseidon | variant |
| q08 | readinessProbe (exec) | hades | variant |
| q09 | Pod→Deployment + ConfigMap volume + limits | ares | variant |
| q10 | Debug CrashLoopBackOff, fix + document | hera | variant |
| q11 | docker save/load/stop/rm — study card | — | *not reproduced* |
| q12 | NetworkPolicy | demeter | **new** |
| q13 | Static PV (hostPath) + PVC binding | dionysus | variant |
| q14 | StatefulSet + headless Service | olympus | **new** |
| q15 | Secret volume with `defaultMode` | chronos | variant |
| q16 | initContainer wait-for-dependency | atlas | variant |
| q17 | Taints/tolerations + nodeSelector | helios | **new** |
| p1 | Helm: local chart install/upgrade | iris | **new** |
| p2 | Kustomize: overlay patch/labels/images | nike | **new** |

---

```bash
cat q02/TASK.md
```

Same speed kit as Set 1 applies — see `../EXAM-SPEED.md`. Same triage
strategy: first pass on anything doable in <4 min, flag the rest, return.

⚠ q17 taints `lab-worker-1` — see this directory's README for why that's
safe to leave in place for the rest of the session.
