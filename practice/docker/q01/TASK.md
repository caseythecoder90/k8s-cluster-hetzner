# q01 — edit a Dockerfile, build it, tag it twice

Files are in `work/q01/` (a `Dockerfile` and `run.sh`).

1. Make the image set an environment variable `MOON_CIPHER_ID` to the hardcoded
   value `8f4c2a`. Do it **in the image**, not at run time.
2. Build it from that directory, tagged `localhost:5000/moon-cipher:v1`.
3. Give the same image a second name, `ckad-moon:latest`, **without building
   again**.

Sanity check when you're done: `docker run --rm ckad-moon:latest` should print
`moon-cipher reporting, id=8f4c2a`.
