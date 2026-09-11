# Docker drills for CKAD

Ten short questions plus a study sheet, for the one exam topic your cluster
can't teach you: building and moving container **images**.

`CHEATSHEET.md` is the thing to re-read — one page, built to go through in ten
minutes. The questions are there to make the commands stick.

## Why this set doesn't run on the lab

The lab (and every real kubeadm node) runs **containerd**. There is no Docker
daemon on it, so `docker build` isn't a thing you can practise there — which is
exactly why `scenarios/q11` and `scenarios2/q11` are study cards rather than
runnable questions.

The exam host is different: killer.sh and the CKAD "define, build and modify
container images" objective give you a machine **with** Docker (sometimes
podman) and a private registry. Your laptop already is that machine.

So: **this set runs against Docker Desktop on your own machine.**

```bash
docker version        # must print a Server section — if not, start Docker Desktop
```

Run it from WSL or Git Bash, either works — with one Git Bash caveat:

**MSYS path mangling.** Git Bash rewrites arguments that look like Unix
absolute paths (`/bin/sh`, `/etc/nginx/nginx.conf`) into Windows paths before
Docker sees them, and you get
`stat C:/Program Files/Git/usr/bin/sh: no such file or directory`. It bites
`--entrypoint`, `docker cp`, `-v`, and any command you pass to `exec`. Either

```bash
docker run --rm --entrypoint sh img -c 'echo hi'    # drop the leading slash
MSYS_NO_PATHCONV=1 docker run ... /bin/sh ...       # or turn it off per command
```

WSL and the exam host have no such problem, so this is the one place where a
command that works on the exam does not work here.

## Workflow

```bash
cd practice/docker
./setup-all.sh            # writes starting files into work/, starts a local registry
cat TASKS-ALL.md          # the questions
# ...solve, working inside work/qNN/...
./verify-all.sh           # score yourself
./cleanup.sh              # remove every ckad-* container/image and work/
```

Single question:

```bash
./setup-all.sh q04
cat q04/TASK.md
./verify-all.sh q04
```

Re-running a question's `setup.sh` resets it. Read `qNN/solution.md` only after
attempting — each one explains *why*, not just which flag.

## Ground rules that keep your machine safe

- Everything created here is named `ckad-*` or `localhost:5000/ckad-*`.
  `cleanup.sh` only ever removes those.
- **`cleanup.sh` never runs `docker system prune`.** On the exam host, prune is
  a fine way to reclaim disk. On your laptop it deletes your own project
  images, build cache, and unused volumes. Don't build the habit here.
- q05 starts a throwaway registry (`registry:2`) on **port 5000**. If something
  already owns that port, run everything with `REG_PORT=5555` set — the scripts
  honour it; the task text says 5000.
- Host ports used: **18080** (q03), **18081** (q09), **5000** (q05).

## What it downloads

`alpine:3.20`, `busybox:1`, `nginx:1-alpine`, `registry:2` — about 40 MB total.
q06 additionally installs a compiler *inside a build* (~100 MB of apk packages,
roughly a minute on a first run); that's the point of the question.

## One difference from the exam

On the exam host you are not root, so every command is `sudo docker ...`.
Locally you don't need sudo. Type it anyway if you want the muscle memory —
it costs nothing and forgetting it on the exam costs a minute of confusion.

If the exam gives you **podman** instead, every verb in this set is identical:
`podman build|run|logs|save|load|push|tag|rm|images`.
