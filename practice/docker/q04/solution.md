# q04 solution

```bash
cd work/q04

# 1 + 2 — image ⇄ tar
docker save -o img.tar ckad-q04:v1
docker rmi ckad-q04:v1
docker load -i img.tar          # tag comes back by itself
docker images | grep ckad-q04

# 3 — container → tar → image
docker run --name ckad-q04c ckad-q04:v1
docker export -o ctr.tar ckad-q04c
docker import ctr.tar ckad-q04-flat:v1

# 4
docker run --rm ckad-q04-flat:v1
# docker: Error response from daemon: no command specified
echo save > answer.txt
```

## Why

Two pairs that look interchangeable and are not:

| | `save` / `load` | `export` / `import` |
|---|---|---|
| Operates on | an **image** | a **container** |
| Archive holds | every layer, plus the config | one flattened filesystem |
| Survives | tags, history, `CMD`, `ENV`, `ENTRYPOINT` | files only |

`docker load` restored the tag on its own — the tag was inside the archive.
`docker import` had to be *given* a tag, because a flat tarball has no idea what
it used to be called.

And the flat image won't start: its config is empty, so there is no `CMD` to
run and Docker refuses with *No command specified*. `ENV HYDRA_STAGE` is gone
too. You can patch it back at import time —
`docker import --change 'CMD ["cat","/payload.txt"]' ctr.tar name:tag` — but the
history and the layer structure are gone for good.

**So: `save`/`load` is the pair for "move this image to another machine".**
`export`/`import` is for extracting a container's filesystem, and the exam's
whole game is offering you one pair when the task needs the other. The wording
gives it away — *"an image is at /course/x.tar, make it available locally"* is
`load`; anything phrased around a **running container** is `export`.

Both `load` and `save` also work with a pipe (`docker save x | gzip > x.tgz`),
and `docker load -i file.tar.gz` handles a gzipped archive directly — which is
exactly what killer.sh hands you.
