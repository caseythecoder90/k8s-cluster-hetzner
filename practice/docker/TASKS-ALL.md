# Docker drills — all questions

Setup first (`./setup-all.sh`), score with `./verify-all.sh`. Files you create
go in `work/qNN/`. Study sheet: `CHEATSHEET.md`.

Assume `docker` without `sudo` locally; on the exam host every command needs
`sudo`. If your exam gives you podman, every verb here is the same.

| q | Topic |
|---|---|
| q01 | ENV in a Dockerfile, build context, tagging one image twice |
| q02 | ENTRYPOINT vs CMD, and `--entrypoint` |
| q03 | detached run: name, published port, env, logs to a file, exec |
| q04 | save/load vs export/import |
| q05 | tag, push and pull against a private registry |
| q06 | multi-stage build to drop the toolchain |
| q07 | layer cache ordering |
| q08 | reading an image with `docker inspect -f` |
| q09 | triage: port conflict, stopped containers, `rmi` refusing |
| q10 | Dockerfile → Pod spec (`command:` / `args:` / `runAsUser`) |

---

# q01 — edit a Dockerfile, build it, tag it twice

Files are in `work/q01/` (a `Dockerfile` and `run.sh`).

1. Make the image set an environment variable `MOON_CIPHER_ID` to the hardcoded
   value `8f4c2a`. Do it **in the image**, not at run time.
2. Build it from that directory, tagged `localhost:5000/moon-cipher:v1`.
3. Give the same image a second name, `ckad-moon:latest`, **without building
   again**.

Sanity check when you're done: `docker run --rm ckad-moon:latest` should print
`moon-cipher reporting, id=8f4c2a`.

---

# q02 — ENTRYPOINT vs CMD

`work/q02/Dockerfile` is three lines. Build it as `ckad-q02:v1`.

Now, **without editing the Dockerfile**, produce three files by running that
image three different ways:

| File | Must contain |
|---|---|
| `work/q02/a.txt` | `hello` — a plain run |
| `work/q02/b.txt` | `goodbye` — same entrypoint, different argument |
| `work/q02/c.txt` | `overridden` — printed by `/bin/sh` instead of `echo` |

Redirect each run's output into its file.

---

# q03 — run it detached, then get things out of it

Run `nginx:1-alpine` as a container named **ckad-web**:

- detached
- reachable on **host port 18080** (nginx listens on 80)
- with environment variable `APP_ENV=exam`

Then, without stopping it:

1. Make one HTTP request to it, so it logs something, and save the container's
   log output to `work/q03/logs.txt`.
2. Print `APP_ENV` **from inside the running container** and save that to
   `work/q03/env.txt` (the file should contain just `exam`).

---

# q04 — save, load, export, import

The image `ckad-q04:v1` already exists locally. It prints `hydra payload` when
you run it.

1. Archive the **image** to `work/q04/img.tar`.
2. Delete `ckad-q04:v1` from the local image store, then restore it from that
   archive. `docker images` must show the `ckad-q04:v1` tag again.
3. Create a container from it named `ckad-q04c` (it exits straight away, that's
   expected), archive **that container's filesystem** to `work/q04/ctr.tar`,
   and turn that archive into an image tagged `ckad-q04-flat:v1`.
4. Try to run `ckad-q04-flat:v1` with no arguments. Then write **one word** into
   `work/q04/answer.txt`: which archive kept the image's `CMD` — `save` or
   `export`?

---

# q05 — push to a private registry, and get it back

A private registry is running at **localhost:5000** (no login required).
Source files are in `work/q05/`.

1. Build the image so that it can be pushed to that registry, as
   `ckad-hydra` version `v2`.
2. Push it.
3. Delete every local copy of the image, then pull it back from the registry
   and confirm it runs (it prints `hydra v2`).

---

# q06 — make the image smaller with a multi-stage build

`work/q06/` builds a tiny C program with a compiler that the finished image
does not need.

1. Build the Dockerfile as it stands, tagged `ckad-q06:fat`. Look at
   `docker images` — that size is the problem.
2. Rewrite it as a **multi-stage** build so the final image ships the compiled
   binary and nothing else. Tag it `ckad-q06:slim`. It must still print
   `hydra v2 ok`.
3. Put both sizes in `work/q06/sizes.txt`, any format you like.

Target: under 20 MB.

---

# q07 — stop rebuilding what didn't change

Every time anyone touches `app.sh` in `work/q07/`, the build reinstalls `curl`.
Fix that.

1. Reorder the Dockerfile so a change to `app.sh` no longer invalidates the
   `apk add` layer.
2. Prove it. Build it as `ckad-q07:v1`, edit `app.sh` (change the version it
   echoes), build again — and save the **second** build's output to
   `work/q07/build2.log`. The `apk add` step must show as cached in that log.

---

# q08 — read an image without running it

Answer four questions about the local image `nginx:1-alpine` using
`docker inspect` / `docker history`. **Do not start a container.**

Write `work/q08/answers.txt` with exactly four lines, in this order:

```
1: <the port number the image EXPOSEs>
2: <the image's ENTRYPOINT — the script/binary it runs, or NONE if it has none>
3: <how many layers the image has>
4: <the user it runs as — a UID, a name, or root if the image sets none>
```

Anything after the `N: ` prefix is your answer.

---

# q09 — clean up someone else's mess

A previous session left containers and an image behind.

1. Host port **18081** is taken by a container. Find out which one — from
   Docker, not by guessing — and remove it.
2. Another container has already exited. Remove that one too.
3. Remove the image `ckad-junk:v1`.
4. Start a fresh `nginx:1-alpine` container named **ckad-new**, detached, on
   host port 18081.

Do them in an order that works. (Step 3 will refuse until something else is
done first — that refusal is the lesson.)

---

# q10 — translate a Dockerfile into a Pod spec

Read `work/q10/Dockerfile`. Write `work/q10/pod.yaml`: a Pod named `ckad-q10`,
one container named `app`, image `ckad-q10:v1`, which

- **keeps** the image's entrypoint,
- but starts with `--mode=fast` instead of the image's default argument,
- runs as UID 1001,
- and declares the port the Dockerfile exposes.

Then write `work/q10/answer.txt`, two lines:

```
command: <the Dockerfile directive that this Pod field overrides>
args: <the Dockerfile directive that this Pod field overrides>
```

No cluster needed — this is graded on the file.
