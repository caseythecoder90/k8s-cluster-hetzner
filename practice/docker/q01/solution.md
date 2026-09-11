# q01 solution

In `work/q01/Dockerfile`, add an `ENV` line (anywhere after `FROM`):

```dockerfile
FROM alpine:3.20
ENV MOON_CIPHER_ID=8f4c2a
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
```

```bash
cd work/q01
docker build -t localhost:5000/moon-cipher:v1 .
docker tag localhost:5000/moon-cipher:v1 ckad-moon:latest
```

## Why

**The trailing dot** is the build context — the directory shipped to the daemon,
and the root that `COPY run.sh` resolves against. Leaving it off is the most
common build error under time pressure; `-f` changes which Dockerfile is used,
never the context.

**`ENV` vs `-e`.** The question said the value is hardcoded *in the image*, so
`docker run -e MOON_CIPHER_ID=8f4c2a` would be wrong even though it prints the
same line — the graded artefact is the image, and anyone else running it would
get `UNSET`.

**`docker tag` copies nothing.** Both names point at the same image ID; a tag is
a label, not a duplicate. That is also how you retarget an image at a registry
— `docker tag app:v1 registry.killer.sh:5000/app:v1` then push. The registry a
push goes to is decided entirely by the tag.

You can also do it in one step — `-t` is repeatable:

```bash
docker build -t localhost:5000/moon-cipher:v1 -t ckad-moon:latest .
```
