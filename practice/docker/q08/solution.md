# q08 solution

```bash
docker inspect -f '{{.Config.ExposedPorts}}' nginx:1-alpine   # map[80/tcp:{}]
docker inspect -f '{{.Config.Entrypoint}}'   nginx:1-alpine   # [/docker-entrypoint.sh]
docker inspect -f '{{len .RootFS.Layers}}'   nginx:1-alpine
docker inspect -f '{{.Config.User}}'         nginx:1-alpine   # empty ⇒ root
```

```
1: 80
2: /docker-entrypoint.sh
3: <whatever the layer count printed>
4: root
```

## Why

**`-f` takes a Go template**, the same language as `kubectl -o go-template`.
`{{.Config.X}}` walks the JSON; `{{len .X}}` counts; `{{json .X}}` prints raw
JSON when the default formatting is ambiguous. Without `-f` you get the whole
document — fine with `| grep`, slow to read under time pressure.

**Empty `.Config.User` means root.** That is why "run this container as
non-root" is a real exam task: unless the image sets `USER`, it starts as UID 0.
In Kubernetes you fix it with `securityContext.runAsUser` (or
`runAsNonRoot: true`, which makes the kubelet *refuse* an image that would run
as root — a useful assertion, not a fix).

**nginx has both an ENTRYPOINT and a CMD** — `/docker-entrypoint.sh` (which
does template substitution, then `exec`s its arguments) and
`["nginx","-g","daemon off;"]`. That combination is why overriding a Pod's
`command:` on an nginx image skips the entrypoint script entirely, and why
overriding only `args:` keeps it. This is the practical payoff of q02.

`docker history nginx:1-alpine` shows the instruction behind each layer, which
is how you work out what an image you didn't build actually does.
