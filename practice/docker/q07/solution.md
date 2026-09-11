# q07 solution

```dockerfile
FROM alpine:3.20
RUN apk add --no-cache curl      # rarely changes → goes first
WORKDIR /app
COPY app.sh /app/app.sh          # changes constantly → goes last
CMD ["/app/app.sh"]
```

```bash
cd work/q07
docker build -t ckad-q07:v1 .
sed -i 's/app v1/app v2/' app.sh
docker build -t ckad-q07:v1 . 2>&1 | tee build2.log
grep -i cached build2.log
```

## Why

**Each instruction is a layer, and the cache is positional.** Docker walks the
Dockerfile comparing each instruction — and, for `COPY`, a checksum of the files
it would copy — against the cached build. The first mismatch invalidates that
layer *and every layer after it*, unconditionally. Nothing downstream can be
reused, even if it would produce identical output.

So `COPY . /app` before `RUN apk add` means: touch any file in the context, and
the copy layer changes, and the install re-runs. Put the install first and the
mismatch happens at the last layer instead, where it costs nothing.

`COPY . /app` has a second problem: it copies the *whole* context, so
`build2.log` itself, editor swap files and `.git` all become part of the cache
key. `COPY app.sh` is narrower and more predictable; `.dockerignore` handles
the rest.

**This is the shape of every real Dockerfile:**

```dockerfile
COPY package.json package-lock.json ./     # or requirements.txt, go.mod, pom.xml
RUN npm ci                                 # cached until dependencies change
COPY . .                                   # source last
```

An exam question phrased as *"builds are slow / make rebuilds faster"* always
means this reordering, never `--no-cache` (which does the opposite) and never a
bigger machine.
