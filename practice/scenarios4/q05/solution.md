# Q5 solution

## 1. Uninstall

```bash
helm -n onyx ls
helm -n onyx uninstall onyx-legacy
```

## 2. Upgrade, keeping values

```bash
helm -n onyx get values onyx-web            # replicaCount: 2 — must survive
helm repo update
helm -n onyx upgrade onyx-web hk-charts/nginx --reuse-values
helm -n onyx ls                              # nginx-1.2.0
```

Same trap as Q3: without `--reuse-values` (or re-passing `--set
replicaCount=2`) the upgrade quietly drops back to 1 replica.

## 3. The stuck release

```bash
helm ls -A            # nothing looks wrong...
helm ls -A -a         # -a = --all: also pending-*, superseded, failed
```

```
NAME              NAMESPACE  REVISION  STATUS           CHART
...
report-generator  opal       2         pending-upgrade  api-2.1.0
```

`helm ls` only shows `deployed` and `failed` releases. Anything `pending-*`
(a helm process that was killed mid-operation) is invisible without `-a`.
`-A` (`--all-namespaces`) is the other half: the task said "somewhere in the
cluster", so don't restrict to the Namespaces you were told about.

```bash
echo opal/report-generator > /course4/5/stuck
helm -n opal uninstall report-generator
```

## 4. Count

```bash
helm -n jade ls    # jade-api, jade-cache
helm -n onyx ls    # onyx-web
echo 3 > /course4/5/count
```

## Flags to keep straight

| Flag | Meaning |
|---|---|
| `-A` / `--all-namespaces` | every Namespace |
| `-a` / `--all` | every status, including pending and superseded |
| `--pending` | only pending-install / pending-upgrade / pending-rollback |
| `--failed` | only failed |
| `--uninstalled` | releases removed with `--keep-history` |

`helm ls -A -a` is the one to remember: it shows everything, everywhere.
