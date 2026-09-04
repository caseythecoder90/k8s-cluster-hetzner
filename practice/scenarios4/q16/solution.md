# Q16 solution

```bash
cat /course4/16/components/monitoring/kustomization.yaml    # kind: Component
vim /course4/16/overlays/prod/kustomization.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: obsidian
resources:
  - ../../base
components:
  - ../../components/monitoring
```

```bash
kubectl kustomize /course4/16/overlays/prod     # ConfigMap appears, env var patched in
kubectl apply -k /course4/16/overlays/prod
kubectl apply -k /course4/16/overlays/dev       # unchanged, but "apply both" was asked
k -n obsidian get cm; k -n obsidian get deploy obsidian-app -o jsonpath='{.spec.template.spec.containers[0].env}'
```

## What a component is

A component is a kustomization with `kind: Component` (and
`apiVersion: kustomize.config.k8s.io/v1alpha1`) that an overlay **opts into**
via `components:`. It can carry resources, patches and generators, and its
patches apply to whatever the including overlay already has — here it adds a
ConfigMap *and* patches the base's Deployment.

That's the difference from a base: a base is included by everyone; a
component only by overlays that list it. Put it in the base and dev would get
monitoring too; copy it into prod and you'd maintain two copies.

## Traps

- Listing the component under `resources:` fails (*kind Component is not
  allowed as a resource*); listing a base under `components:` fails the
  other way round.
- Components apply **after** the overlay's resources, in the listed order —
  so a component's patch always sees the base's Deployment.

## Exam note

Components are a KodeKloud-course topic and a real Kustomize feature, but
they're the least likely thing on this set to appear on the CKAD. Know the
`kind: Component` / `components:` pair; don't drill it.
