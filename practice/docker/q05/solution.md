# q05 solution

```bash
cd work/q05
docker build -t localhost:5000/ckad-hydra:v2 .
docker push localhost:5000/ckad-hydra:v2

docker rmi localhost:5000/ckad-hydra:v2
docker pull localhost:5000/ckad-hydra:v2
docker run --rm localhost:5000/ckad-hydra:v2      # hydra v2
```

## Why

**The tag is the address.** There is no `--registry` flag; `docker push` reads
the destination out of the image's name. `ckad-hydra:v2` with no host prefix
means Docker Hub, and the push would fail on authentication — which on the exam
looks like a permissions problem and is really a tagging problem.

If you built it under the wrong name, you don't rebuild:

```bash
docker tag ckad-hydra:v2 localhost:5000/ckad-hydra:v2
```

**Why no TLS error.** Docker refuses plain-HTTP registries — except when the
host is `localhost`/`127.0.0.1`, which it treats as insecure-by-default. A
remote private registry over HTTP needs an `insecure-registries` entry in the
daemon config; killer.sh's `registry.killer.sh:5000` is already set up for you,
so this never comes up in the exam, only on your own machine.

**`docker login <host>`** is only needed if the registry asks. This one doesn't.

Check what a registry holds over its HTTP API — handy when you're not sure your
push landed:

```bash
curl -s localhost:5000/v2/_catalog
curl -s localhost:5000/v2/ckad-hydra/tags/list
```
