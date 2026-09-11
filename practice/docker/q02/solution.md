# q02 solution

```bash
cd work/q02
docker build -t ckad-q02:v1 .

docker run --rm ckad-q02:v1                 > a.txt
docker run --rm ckad-q02:v1 goodbye         > b.txt
docker run --rm --entrypoint sh ckad-q02:v1 -c 'echo overridden' > c.txt
```

## Why

The image is `ENTRYPOINT ["echo"]` + `CMD ["hello"]`, so the container's full
command line is `echo hello`.

- **a** — nothing overridden: `echo hello`.
- **b** — anything you type after the image name **replaces CMD** and is
  appended to ENTRYPOINT. So `echo goodbye`. Note you did not, and could not,
  replace `echo` this way.
- **c** — `--entrypoint` is the only way to replace the binary, and it takes
  **just the binary**. Its arguments still come from the image-name-onwards
  position, which is why `-c 'echo overridden'` sits *after* `ckad-q02:v1`.
  Writing `--entrypoint "sh -c 'echo overridden'"` fails: Docker looks for an
  executable with that entire string as its filename.

**Write `sh`, not `/bin/sh`, if you are in Git Bash.** MSYS rewrites arguments
that look like Unix absolute paths into Windows ones before Docker sees them,
and the container fails with `stat C:/Program Files/Git/usr/bin/sh: no such
file or directory`. `MSYS_NO_PATHCONV=1` in front of the command is the other
fix; WSL has no such problem. On the exam host, `/bin/sh` is fine.

## The reason this question exists

The same split is how Kubernetes overrides a container:

| Dockerfile | Pod spec |
|---|---|
| `ENTRYPOINT` | `command:` |
| `CMD` | `args:` |

and the trap is that setting `command:` alone **throws away the image's CMD**.
A Pod with `command: ["echo"]` and no `args:` on this image prints an empty
line, not `hello`. If you only want to change the arguments, set `args:` and
leave `command:` out entirely.
