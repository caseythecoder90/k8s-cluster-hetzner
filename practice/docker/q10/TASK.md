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
