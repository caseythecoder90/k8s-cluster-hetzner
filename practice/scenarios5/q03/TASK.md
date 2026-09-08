# Q3 (topic: labels that do not touch selectors)

The Cobalt portal is already running in Namespace `cobalt`, applied from the
base at `/course5/3/base`.

Compliance wants every resource of this app to carry the label
`tier: frontend`.

1. Create an overlay at `/course5/3/overlays/labelled` on top of the base
2. Add the label `tier: frontend` to every resource — **without changing any
   selector**
3. Apply the overlay against the running app

Do not modify the base. The Deployment must still be Ready when you are done.

> Target: 3 minutes. There are two fields that add labels and only one of them
> can be applied to a live Deployment.
