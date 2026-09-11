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
