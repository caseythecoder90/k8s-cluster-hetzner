# Q1 (topic: the four commands + the name/namespace transformers)

Base manifests for team Copper are at `/course5/1/base`. Build an overlay at
`/course5/1/overlays/prod` that, on top of the base:

1. Places every resource in Namespace `copper` (exists)
2. Prefixes every resource name with `pr-`
3. Suffixes every resource name with `-v2`
4. Adds the annotation `owner: copper` to every resource

Then:

5. Save the rendered manifests — without applying them — to
   `/course5/1/rendered.yaml`
6. Apply the overlay

Do not modify the base.

> Target: 4 minutes. Everything here is `kustomization.yaml` fields; if you
> reach for a patch you have overshot the question.
