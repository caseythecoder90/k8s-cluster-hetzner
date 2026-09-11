# q08 — read an image without running it

Answer four questions about the local image `nginx:1-alpine` using
`docker inspect` / `docker history`. **Do not start a container.**

Write `work/q08/answers.txt` with exactly four lines, in this order:

```
1: <the port number the image EXPOSEs>
2: <the image's ENTRYPOINT — the script/binary it runs, or NONE if it has none>
3: <how many layers the image has>
4: <the user it runs as — a UID, a name, or root if the image sets none>
```

Anything after the `N: ` prefix is your answer.
