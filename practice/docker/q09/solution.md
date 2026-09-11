# q09 solution

```bash
docker ps                        # who has 0.0.0.0:18081->80/tcp ?  → ckad-old
docker rm -f ckad-old

docker ps -a                     # the exited one only shows up with -a → ckad-dead
docker rm ckad-dead

docker rmi ckad-junk:v1          # works now; would have failed before the line above
docker run -d --name ckad-new -p 18081:80 nginx:1-alpine
```

## Why

**`docker ps` hides stopped containers.** `-a` shows everything, and a stopped
container is not nothing: it still holds its name, its writable layer, and a
reference to its image. Two of this question's three obstacles are invisible
without `-a`.

**`docker rmi` refuses while any container — running *or* exited — references
the image.** The error is *"conflict: unable to remove repository reference"*
or *"image is being used by stopped container <id>"*. The fix is to remove the
container, not to reach for `-f`. `docker rmi -f` on a referenced image just
untags it and leaves the layers behind as a dangling image, which is how disk
quietly fills up.

**`docker rm -f`** is stop-then-remove in one step — fine for a container you
know is disposable. Two separate steps (`docker stop` then `docker rm`) give
the process its SIGTERM grace period, which matters when it's writing something.

**The port is the diagnosis, not the symptom.** `docker run -p 18081:80` on an
occupied port fails with *"port is already allocated"*. The habit worth building
is `docker ps` first: the PORTS column names the container holding it. On the
exam, `scenarios2/q11` has exactly this shape — an old container squatting on
8080 that you must stop and remove before your new one can start.

Cleanup verbs, for completeness:

```bash
docker container prune     # all stopped containers
docker image prune         # dangling images
docker system prune -f     # everything unused, including build cache
```

Free on an exam host. **Never on your laptop** — `system prune` will take your
own project images and unused volumes with it.
