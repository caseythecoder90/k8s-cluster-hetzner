# q06 solution

```dockerfile
FROM alpine:3.20 AS build
RUN apk add --no-cache gcc musl-dev
WORKDIR /src
COPY app.c .
RUN gcc -static -o /usr/local/bin/app app.c

FROM alpine:3.20
COPY --from=build /usr/local/bin/app /usr/local/bin/app
CMD ["app"]
```

```bash
cd work/q06
docker build -t ckad-q06:fat .              # before the edit
docker build -t ckad-q06:slim .             # after
docker images ckad-q06 --format '{{.Tag}} {{.Size}}' > sizes.txt
docker run --rm ckad-q06:slim               # hydra v2 ok
```

Roughly 120 MB → 9 MB.

## Why

**Only the last stage ships.** Earlier stages are build scratch space: they run,
they produce artefacts, and then they're discarded. `COPY --from=build <src>
<dst>` reaches back into a named stage and lifts a file out of it. Nothing else
from that stage survives, so the compiler, its headers and the source tree
never enter the final image.

`FROM alpine:3.20 AS build` is what names a stage. Without `AS`, you'd copy by
index (`--from=0`), which works and reads terribly.

**Why not just `apk del gcc` at the end?** Because a layer that deletes files
still sits on top of the layer that added them — the bytes are in the image
either way. Removing something in a later `RUN` never shrinks an image; only
not putting it in the final stage does.

Two related things worth knowing:

- `docker build --target build -t x .` stops at a named stage — how you debug a
  builder stage without producing the final image.
- The other half of "make it smaller" is the base tag: `-alpine` and `-slim`
  variants exist for most official images, and swapping `node:20` for
  `node:20-alpine` is exactly what `scenarios2/q11` asks for.
