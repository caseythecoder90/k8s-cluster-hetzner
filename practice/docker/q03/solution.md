# q03 solution

```bash
docker run -d --name ckad-web -p 18080:80 -e APP_ENV=exam nginx:1-alpine

curl -s localhost:18080 >/dev/null          # or: docker exec ckad-web wget -qO- localhost
docker logs ckad-web > work/q03/logs.txt

docker exec ckad-web printenv APP_ENV > work/q03/env.txt
```

## Why

**`-p HOST:CONTAINER`, host side first.** `-p 18080:80` publishes the
container's 80 at `localhost:18080`. Reversing it is a classic 30-second loss.
`docker port ckad-web 80` tells you what a running container is actually
published on, which beats re-reading your own command.

**Logs come from stdout/stderr.** nginx's official image symlinks its access and
error logs to stdout/stderr precisely so `docker logs` works. `docker logs
<name> > file` is the literal shape of the killer.sh question — it wants a file,
so redirect; `-f` would hang forever and `--tail 20` trims.

**`docker exec` runs in the *existing* container.** `docker run ... printenv`
would start a second one. Use `printenv VAR` rather than `echo $VAR`: in
`docker exec ckad-web echo $APP_ENV`, your own shell expands `$APP_ENV` before
Docker ever sees it, and you get an empty line. If you want the shell form, it
has to run inside: `docker exec ckad-web sh -c 'echo $APP_ENV'`.

The Kubernetes equivalents are the same three ideas: `k logs`, `k exec -it pod
-- sh`, and `env:` in the Pod spec.
