# Q15 solution

```bash
k -n chronos create deploy chronos-app --image=nginx:1-alpine $do > d.yaml
vim d.yaml
```

```yaml
    spec:
      containers:
      - name: app                       # renamed
        image: nginx:1-alpine
        volumeMounts:
        - name: creds
          mountPath: /etc/creds
      volumes:
      - name: creds
        secret:
          secretName: chronos-creds
          defaultMode: 0400              # YAML accepts octal directly
```

```bash
k apply -f d.yaml
k -n chronos exec deploy/chronos-app -- ls -l /etc/creds
```

`defaultMode` is a **file permission mode for the mounted files**, written in
YAML as a plain octal number (`0400`) — but `kubectl get -o jsonpath` (and
`describe`) will show it back as **decimal 256**, because JSON has no octal
literal and Kubernetes stores/serializes it as a plain integer. `256 == 0400`
in octal — don't be thrown by the base change when reading it back.

`0400` = owner read-only, nothing for group/other — appropriate for
credential files a container shouldn't accidentally let other processes in
the same filesystem namespace read or modify.

Same pattern applies to ConfigMap volumes (`configMap.defaultMode`) — the
field name and behavior are identical, just under a different volume source.
