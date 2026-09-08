# Q3 solution

```yaml
# /course5/3/overlays/labelled/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: cobalt

resources:
  - ../../base

labels:
  - pairs:
      tier: frontend
    includeSelectors: false     # the default; write it to say you meant it
```

```bash
kubectl apply -k /course5/3/overlays/labelled
```

## Why not `commonLabels`

`commonLabels: {tier: frontend}` writes the label into `metadata.labels`
**and** into `spec.selector.matchLabels` and the Service's `spec.selector`.
On a Deployment that already exists that is fatal:

```
The Deployment "portal" is invalid: spec.selector: Invalid value: ...
field is immutable
```

A Deployment's selector cannot be changed after creation. `commonLabels` is
fine on a green-field apply and a landmine on a running one — and the exam
words it as **"without changing the selectors"** precisely to see whether you
know which of the two fields you are being steered towards.

`labels:` (kustomize v5) writes `metadata.labels` only, unless you opt in with
`includeSelectors: true` or `includeTemplates: true`.

## Reading the wording

| Wording | Field |
|---|---|
| "label every resource, do not touch selectors" | `labels:` |
| "label everything including the selectors" (green field only) | `commonLabels:` |
| "annotate every resource" | `commonAnnotations:` |
