# Q2 solution

```bash
k -n athena create deploy athena-web --image=nginx:1-alpine --replicas=2 $do > d.yaml
vim d.yaml
```

```yaml
    spec:
      containers:
      - name: web                 # renamed from generated default
        image: nginx:1-alpine
        envFrom:
        - configMapRef:
            name: athena-config
        env:
        - name: CACHE_TTL
          value: "60"
```

```bash
k apply -f d.yaml
```

`envFrom` loads **every key** in the ConfigMap as an env var automatically —
use it when the question says "all keys" or "every key." `env` is for naming
one specific var explicitly. Both can coexist on the same container; if a
name collides, the explicit `env:` entry wins over `envFrom`.
