# Q13 (topic: the generated name hash — keep it or kill it)

Namespace `indium` has two Deployments and neither one starts:

- `broker`, applied from the overlay `/course5/13/overlays/prod`, reads
  `username` and `password` from a Secret `broker-auth`
- `audit`, which is **not** part of any Kustomize build (it was applied
  straight from `/course5/13/audit.yaml`), mounts a ConfigMap `broker-rules`
  at `/etc/rules`

From the overlay's `kustomization.yaml`, generate both objects:

1. Secret `broker-auth`, type `Opaque`, from the literals `username=indium`
   and `password=bismuth-77`. It must **keep** its generated hash suffix, and
   Deployment `broker` must end up referencing that hashed name — which you
   never type yourself
2. ConfigMap `broker-rules` from the file `rules.conf` in the overlay
   directory (key = the file name). It must be named **exactly**
   `broker-rules`, because `audit` is already running and asks for that name
3. Apply the overlay. Both `broker` and `audit` must become Ready

Do not modify the base, and do not edit or re-create the `audit` Deployment —
it stands in for something outside your build that you do not control.

> Target: 6 minutes. `disableNameSuffixHash` can be written in two different
> places and only one of them leaves the Secret's hash alone.
