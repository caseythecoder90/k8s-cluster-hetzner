# Docker study sheet (CKAD)

You already know `run`, `pull`, `ps`, compose. This sheet is the delta — the
parts the exam tests that day-to-day local development never makes you learn.

**Compose is not on the exam.** Nothing below uses it.

## What the exam actually asks

Every image question is assembled from the same five moves:

1. **Edit** a given Dockerfile (change `FROM`, add `ENV`, fix `CMD`)
2. **Build** it with a specific tag — usually `registry.host:5000/name:version`
3. **Move** it — `push`, or `save` to a tar, or `load` one you were given
4. **Run** it detached with a specific name, port, or env
5. **Write** something to a file — usually `docker logs <name> > /course/N/logs`

It is pure recall, worth full marks, and fast if you have the verbs cold.

## Dockerfile directives

| Directive | What to remember |
|---|---|
| `FROM img:tag` | first line; `FROM x AS build` names a stage |
| `ENV K=V` | baked into the image, visible at run time |
| `ARG K=V` | **build time only** — gone in the running container |
| `WORKDIR /app` | cd for every later instruction; creates the dir |
| `COPY src dst` | the default choice |
| `ADD src dst` | `COPY` + auto-untars local tarballs + fetches URLs. Prefer `COPY` |
| `RUN cmd` | runs at build time, makes a layer |
| `CMD [...]` | **default arguments**, replaceable at run time |
| `ENTRYPOINT [...]` | **the binary**, not replaceable without `--entrypoint` |
| `EXPOSE 8080` | documentation only — it publishes nothing |
| `USER 1001` | everything after it, and the container, runs as that UID |

`ARG` vs `ENV` and `EXPOSE`-publishes-nothing are the two the exam likes.

## CMD vs ENTRYPOINT — learn this one properly

```dockerfile
ENTRYPOINT ["ping"]     # the command
CMD ["-c", "3", "localhost"]   # its default arguments
```

| You run | It executes |
|---|---|
| `docker run img` | `ping -c 3 localhost` |
| `docker run img 8.8.8.8` | `ping 8.8.8.8` — args **replace CMD**, append to ENTRYPOINT |
| `docker run --entrypoint sh img -c 'echo hi'` | `sh -c 'echo hi'` — flag replaces ENTRYPOINT, args replace CMD |

**Exec form vs shell form.** `CMD ["nginx","-g","daemon off;"]` execs directly:
your process is PID 1 and receives SIGTERM. `CMD nginx -g "daemon off;"` is
wrapped in `/bin/sh -c`, so **sh** is PID 1, signals don't reach your process,
and the container ignores `docker stop` until the 10s timeout. Always use the
JSON exec form.

### The Kubernetes mapping (this is the graded part)

| Dockerfile | Pod spec |
|---|---|
| `ENTRYPOINT` | `command:` |
| `CMD` | `args:` |

```yaml
containers:
  - name: app
    image: app:v1
    command: ["python"]        # overrides ENTRYPOINT
    args: ["-u", "main.py"]    # overrides CMD
```

**The trap:** setting `command:` alone silently discards the image's `CMD`.
If you only want to change the arguments, set `args:` and leave `command:` out.

## Build

```bash
docker build -t name:tag .                    # the dot is the build context
docker build -t name:tag -f docker/Dockerfile .
docker build --build-arg VER=2 -t name:tag .
docker build --target build -t name:tag .     # stop at a named stage
docker build --no-cache -t name:tag .
```

The final argument is the **context** — the directory sent to the daemon.
`COPY` paths are relative to it, and nothing outside it can be copied. Cut it
down with `.dockerignore`.

### Layer caching

Every instruction is a layer. Change one and every layer after it rebuilds.
So put what changes rarely first:

```dockerfile
COPY package.json .        # dependencies: changes rarely
RUN npm install            # ...so this stays cached
COPY . .                   # source: changes every commit
```

Copying source before installing dependencies is the classic wrong answer, and
an exam question phrased as "make rebuilds faster" always means this.

### Multi-stage

```dockerfile
FROM golang:1.23 AS build
WORKDIR /src
COPY . .
RUN go build -o /out/app

FROM alpine:3.20           # final image starts empty of the toolchain
COPY --from=build /out/app /usr/local/bin/app
CMD ["app"]
```

Only the last stage ships. This is the answer to "reduce the image size" —
along with using an `-alpine` or `-slim` base tag.

## Images: the verbs, and the trap

```bash
docker images                      # list local images (docker image ls)
docker tag src:v1 host:5000/x:v1   # a second name for the SAME image, no rebuild
docker push host:5000/x:v1         # the tag decides where it goes
docker pull x:v1
docker rmi x:v1                    # fails while any container still refers to it
docker history x:v1                # layers, and the instruction that made each
docker inspect x:v1
```

**The trap the exam reuses:**

| Verb | Direction | Operates on | Keeps |
|---|---|---|---|
| `docker save -o f.tar img` | image → tar | **image** | layers, tags, history, CMD |
| `docker load -i f.tar` | tar → image | **image** | all of it, tag included |
| `docker export -o f.tar ctr` | container → tar | **container** | flat filesystem only |
| `docker import f.tar new:v1` | tar → image | container→image | one layer, **no CMD, no ENV** |

`save`/`load` is the pair for "move this image intact". `export`/`import`
flattens and throws the config away — an image imported that way won't start,
because it no longer knows what to run. The question always gives you one pair
and hopes you reach for the other.

## Containers: the verbs

```bash
docker run -d --name web -p 8080:80 -e APP=x nginx:alpine
docker run --rm -it alpine sh          # interactive, deleted on exit
docker run --user 1001 img             # ≙ securityContext.runAsUser
docker ps            /  docker ps -a   # -a includes stopped ones
docker logs web      /  docker logs -f --tail 20 web
docker exec -it web sh
docker stop web  /  docker start web  /  docker restart web
docker rm web    /  docker rm -f web   # -f = stop and remove
docker cp web:/etc/nginx/nginx.conf .  # in or out, no volume needed
docker inspect -f '{{.State.Status}}' web
docker port web 80                     # what host port is it published on
```

`-p HOST:CONTAINER` — host port first. `-p 8080:80` means "reach the
container's 80 at localhost:8080".

## Registries

A tag that starts with a host is what makes a push go somewhere private:

```bash
docker tag app:v1 registry.killer.sh:5000/app:v1
docker push registry.killer.sh:5000/app:v1
docker login registry.killer.sh:5000        # only if it asks
```

No host prefix means Docker Hub. `localhost:5000` is exempt from the TLS
requirement, which is why a throwaway `registry:2` container just works.

## Docker → Kubernetes translation

| Docker | Kubernetes |
|---|---|
| `docker run -d --name x img` | `k run x --image=img` |
| `-p 8080:80` | Service (+ `containerPort` as documentation) |
| `-e KEY=val` | `env:` / `envFrom:` |
| `--user 1001` | `securityContext.runAsUser: 1001` |
| `--entrypoint` / trailing args | `command:` / `args:` |
| `-v /host:/ctr` | `volumes:` + `volumeMounts:` |
| `--restart=always` | `restartPolicy: Always` (the default) |
| `docker logs x` | `k logs x` |
| `docker exec -it x sh` | `k exec -it x -- sh` |
| `docker ps` | `k get po` |
| `docker inspect x` | `k describe po x` |

## On a real node there is no docker

Kubernetes nodes run containerd. `docker ps` on the lab's control plane just
says command not found. The equivalents:

```bash
sudo crictl ps            # containers   (crictl pods for sandboxes)
sudo crictl images
sudo crictl logs <id>
sudo nerdctl build -t x . # nerdctl is a docker-compatible CLI for containerd
```

CKAD rarely asks this — but knowing *why* `docker` is missing on your lab node,
and present on the exam's build host, is the difference between a confident
30 seconds and a panicked five minutes.

## Traps, collected

- `EXPOSE` publishes nothing. Only `-p` does.
- `ARG` is not available at run time; `ENV` is.
- Shell-form `CMD` makes `sh` your PID 1 and breaks graceful shutdown.
- Setting only `command:` in a Pod discards the image's `CMD`.
- `docker rmi` fails while a **stopped** container still references the image —
  `docker rm` the container first.
- `save`/`load` for images; `export`/`import` for containers, and it loses CMD.
- `docker tag` copies nothing — both names point at one image ID.
- Forgetting the trailing `.` on `docker build -t x` is the single most common
  syntax error under time pressure.
- On the exam host you are not root: `sudo docker`.
