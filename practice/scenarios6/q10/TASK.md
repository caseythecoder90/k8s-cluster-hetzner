# Q10 (topic: `ipBlock` with `except:`)

Namespace `thames` runs a Service `vault` on `:80` and two clients, `alpha`
and `beta`. Both can reach `vault` today. Security has quarantined one address
and wants it kept off `vault` while the rest of the pod network keeps its
access.

The addresses are in `/course6/10/peers.txt` — read them from there, do not
guess them.

1. Create a NetworkPolicy named `vault-ingress` in Namespace `thames`, saved
   as `/course6/10/vault-ingress.yaml`, and apply it
2. It attaches to the `vault` pods (`app: vault`) and governs **Ingress only**
3. It admits TCP `:80` from the whole `pod-network-cidr` in that file,
   **except** the quarantined address
4. It must express the peers as a **CIDR** — this task is about `ipBlock`.
   No `podSelector` and no `namespaceSelector` anywhere in the rule

Afterwards `alpha` must still reach `vault` and `beta` must not.

Do not change the Deployments or the Service, and do not delete or re-create
any Pod (the addresses in the file would go stale).

> Target: 7 minutes. `except:` is not a sibling of `from:` — check twice where
> it hangs, and remember what an `except` entry has to be relative to `cidr`.
