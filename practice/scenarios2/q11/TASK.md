# Q11 (topic: container images) — NOT REPRODUCED ON THIS LAB

Same reasoning as Exam Set 1's q11 (`../../scenarios/q11/TASK.md`): no Docker
daemon or private registry on this containerd-based lab. Different specifics
here so you drill a wider slice of the same command family.

## The task (as asked)

Files to build an image are at `/course2/11/image` on the exam host. A
Node.js app writes to stdout.

1. The Dockerfile currently uses `node:20` as its base — change it to
   `node:20-alpine` (smaller final image)
2. Build the image, tag it `registry.killer.sh:5000/hydra-app:v2`, push it
3. **Save** the image to a tar archive at `/course2/11/hydra-app.tar` (not
   push — a different operation than Set 1's q11)
4. Someone already built an older image and left it running as container
   `hydra-old`; **stop and remove** that container (it's holding port 8080)
5. Run a **new** container from your fresh image, named `hydra-app`,
   detached, publishing port 8080

## The commands to know cold

```bash
# 1. Dockerfile edit — just change the FROM line
# FROM node:20-alpine

# 2. build + tag + push
sudo docker build -t registry.killer.sh:5000/hydra-app:v2 .
sudo docker push registry.killer.sh:5000/hydra-app:v2

# 3. save an image to a tar (contrast with `load`, which does the reverse)
sudo docker save -o /course2/11/hydra-app.tar registry.killer.sh:5000/hydra-app:v2

# 4. stop + remove the old container (two steps, or one with -f)
sudo docker stop hydra-old
sudo docker rm hydra-old
# equivalently: sudo docker rm -f hydra-old

# 5. run detached, named, with a published port
sudo docker run -d --name hydra-app -p 8080:8080 registry.killer.sh:5000/hydra-app:v2
```

## The four verbs worth having memorized cold

| Verb | Direction | Operates on |
|---|---|---|
| `docker save` | image → tar file | image |
| `docker load` | tar file → image | image |
| `docker export` | running container → tar (flat filesystem, no layers/history) | container |
| `docker import` | tar → new image (single layer) | container→image |

`save`/`load` preserve image layers and metadata (tags, history) — the pair
you want for "move this image somewhere else intact." `export`/`import`
flatten everything into one layer and drop history — rarely what you want,
but the exam likes testing whether you know the difference.

Also worth knowing: `docker ps -a` (see stopped containers too, not just
running), `docker images` (list local images), `docker system prune -f`
(clean up dangling images/containers — useful if disk fills up mid-exam).
