# Q3 solution

Look before you leap — what was the release installed with?

```bash
helm -n coral ls
helm -n coral get values coral-web          # the user-supplied values only
```

```yaml
USER-SUPPLIED VALUES:
replicaCount: 4
service:
  nodePort: 30403
  type: NodePort
```

Those are the values that must survive. Now the upgrade:

```bash
helm repo update
helm search repo hk-charts/nginx --versions          # newest is 1.2.0
helm -n coral upgrade coral-web hk-charts/nginx --reuse-values --set image.tag=1.27-alpine
helm -n coral ls                                     # REVISION 2, CHART nginx-1.2.0
echo 2 > /course4/3/revision
```

No `--version` means the newest chart version, which is what step 1 asks for.

## The trap: `helm upgrade` forgets your previous `--set`s

`helm upgrade` renders the chart from its default `values.yaml` plus **only
what you pass this time**. Running

```bash
helm -n coral upgrade coral-web hk-charts/nginx --set image.tag=1.27-alpine   # WRONG
```

silently resets `replicaCount` to 1 and the Service to ClusterIP — step 3
fails even though the upgrade "worked". Two ways to keep the old values:

- `--reuse-values` — carry the previous release's values forward, then apply
  the new `--set`s on top (what the solution above does)
- pass everything again explicitly (`--set replicaCount=4 --set service.type=...`),
  or better, keep a values file and always upgrade with `-f`

`helm get values` is how you find out what "everything" is.

## Check

```bash
helm -n coral history coral-web
k -n coral get deploy coral-web -o wide        # 4/4, nginx:1.27-alpine
k -n coral get svc coral-web                   # NodePort 30403
```

If you got it wrong, `helm rollback coral-web 1 -n coral` returns to the
original state (and creates revision 3 — see the next question).
