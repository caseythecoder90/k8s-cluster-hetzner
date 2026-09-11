# q06 — make the image smaller with a multi-stage build

`work/q06/` builds a tiny C program with a compiler that the finished image
does not need.

1. Build the Dockerfile as it stands, tagged `ckad-q06:fat`. Look at
   `docker images` — that size is the problem.
2. Rewrite it as a **multi-stage** build so the final image ships the compiled
   binary and nothing else. Tag it `ckad-q06:slim`. It must still print
   `hydra v2 ok`.
3. Put both sizes in `work/q06/sizes.txt`, any format you like.

Target: under 20 MB.
