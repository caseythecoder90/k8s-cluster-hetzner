# Q4 solution

```bash
helm -n garnet history garnet-api
```

```
REVISION  UPDATED   STATUS      CHART      APP VERSION  DESCRIPTION
1         ...       superseded  api-1.0.0  1.0          Install complete
2         ...       superseded  api-2.0.0  2.0          Upgrade complete
3         ...       deployed    api-2.2.0  2.2          Upgrade complete
```

Helm says revision 3 is "deployed" — Helm only knows the manifests were
accepted, not whether the Pods came up. Confirm with kubectl:

```bash
k -n garnet get pod           # one Pod in ImagePullBackOff, the old ones still serving
k -n garnet describe pod <the bad one> | tail -5
```

Revision 2 is the last one that worked, so:

```bash
helm -n garnet rollback garnet-api 2
helm -n garnet history garnet-api
```

```
...
3   superseded  api-2.2.0  Upgrade complete
4   deployed    api-2.0.0  Rollback to 2
```

```bash
echo 4     > /course4/4/revision
echo 2.0.0 > /course4/4/chart-version
k -n garnet get deploy garnet-api        # 2/2
```

## The trap: a rollback is a new revision

Rolling back to 2 does not make revision 2 current — Helm creates **revision
4** with revision 2's contents. Writing `2` into the file is the mistake this
question is built to catch; `helm ls` or `helm history` shows what's actually
deployed.

Same mental model as `kubectl rollout undo`: undo produces a new ReplicaSet
revision, it doesn't rewind the counter.

## Variants worth knowing

```bash
helm -n garnet rollback garnet-api        # no revision = go back one (to 2 here)
helm -n garnet rollback garnet-api 1      # any earlier revision works
helm -n garnet status garnet-api
helm -n garnet get values garnet-api      # values of the current revision
helm -n garnet get values garnet-api --revision 3
helm -n garnet get manifest garnet-api    # rendered YAML Helm applied
```
