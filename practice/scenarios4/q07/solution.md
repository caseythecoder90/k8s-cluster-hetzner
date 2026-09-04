# Q7 solution

Start with the Pods, like any broken workload:

```bash
k -n quartz get pod                       # ImagePullBackOff
k -n quartz describe pod <one of them> | tail -8
```

```
Failed to pull image "nginx:1.27-alpin": ... manifest unknown
```

A typo in the image tag. Confirm where it comes from:

```bash
helm -n quartz get values quartz-api      # tag: 1.27-alpin  <- the values file
cat /course4/7/values.yaml
```

Fix the file, then push the file through an upgrade:

```bash
vim /course4/7/values.yaml                # tag: 1.27-alpine
helm -n quartz upgrade quartz-api hk-charts/api --version 2.2.0 -f /course4/7/values.yaml
k -n quartz get pod                       # 2/2 Running after the pull
helm -n quartz history quartz-api         # revision 2
```

## Why the file, and why `-f` on the upgrade

Editing the file alone changes nothing — Helm read it once at install time
and stored a copy in the release. An upgrade is what re-reads it. And the
upgrade must pass `-f` again: `helm upgrade quartz-api hk-charts/api` with no
values would "fix" the tag by falling back to the chart default
(`1-alpine`) while also silently resetting replicas to 1 and the Service to
ClusterIP. Every upgrade re-renders from scratch.

`--set image.tag=1.27-alpine` would fix the Pods too, but then the file and
the release disagree, which is exactly what "single source of truth" forbids
— and the next person to run `helm upgrade -f values.yaml` re-breaks it.

## Quick reference

```bash
helm -n quartz get values quartz-api          # user-supplied values
helm -n quartz get values quartz-api --all    # merged with chart defaults
helm -n quartz get manifest quartz-api        # what Helm actually applied
helm -n quartz status quartz-api
```
