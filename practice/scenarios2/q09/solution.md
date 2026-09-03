# Q9 solution

Reshape the existing Pod file rather than generating from scratch and pasting
the container back in — see `../../EXAM-SPEED.md` for why this beats a fresh
`create deploy` + paste for "convert X into Y" questions.

```bash
cp /course2/9/ares-report-pod.yaml /course2/9/ares-report-deployment.yaml
vim /course2/9/ares-report-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ares-report
  namespace: ares
spec:
  replicas: 2
  selector:
    matchLabels:
      id: ares-report
  template:
    metadata:
      labels:
        id: ares-report
    spec:
      containers:
      - name: report
        image: nginx:1-alpine
        volumeMounts:
        - name: report-config
          mountPath: /etc/report
          readOnly: true
        resources:
          limits:
            cpu: 100m
            memory: 64Mi
      volumes:
      - name: report-config
        configMap:
          name: ares-report-config
```

```bash
k apply -f /course2/9/ares-report-deployment.yaml
k -n ares get pods -l id=ares-report
k -n ares delete pod ares-report --force --grace-period=0
```

Trap: **limits only, no requests** — don't add a `requests:` block just out
of habit; the question is specific. Also: `readOnly: true` on the
volumeMount isn't strictly graded here but is the right instinct for
ConfigMap/Secret mounts you're not meant to write to.
