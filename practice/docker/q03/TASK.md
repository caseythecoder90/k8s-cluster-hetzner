# q03 — run it detached, then get things out of it

Run `nginx:1-alpine` as a container named **ckad-web**:

- detached
- reachable on **host port 18080** (nginx listens on 80)
- with environment variable `APP_ENV=exam`

Then, without stopping it:

1. Make one HTTP request to it, so it logs something, and save the container's
   log output to `work/q03/logs.txt`.
2. Print `APP_ENV` **from inside the running container** and save that to
   `work/q03/env.txt` (the file should contain just `exam`).
