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
