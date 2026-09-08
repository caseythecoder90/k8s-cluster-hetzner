# Q10 solution

## Read the addresses, do not invent them

```bash
cat /course6/10/peers.txt
```

```
pod-network-cidr:  192.168.0.0/16
alpha-pod-ip:      192.168.29.71
beta-pod-ip:       192.168.29.72
quarantined:       192.168.29.72/32
```

(Your values will differ — use the ones in **your** file.)

## The policy

```yaml
# /course6/10/vault-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vault-ingress
  namespace: thames
spec:
  podSelector:
    matchLabels:
      app: vault
  policyTypes:
    - Ingress
  ingress:
    - from:
        - ipBlock:
            cidr: 192.168.0.0/16       # from the file
            except:
              - 192.168.29.72/32       # the quarantined address
      ports:
        - protocol: TCP
          port: 80
```

```bash
k apply -f /course6/10/vault-ingress.yaml
k -n thames describe netpol vault-ingress

VIP=$(k -n thames get svc vault -o jsonpath='{.spec.clusterIP}')
k -n thames exec deploy/alpha -- wget -T 4 -qO- http://$VIP    # vault-v1
k -n thames exec deploy/beta  -- wget -T 4 -qO- http://$VIP    # hangs, then fails
```

## The shape of `ipBlock`

```
ingress:
  - from:                 # a LIST of peers
      - ipBlock:          # one peer
          cidr: ...       # required
          except:         # optional, a LIST of CIDRs
            - ...
    ports: [...]
```

Three things go wrong here and only here:

1. **`except:` lives inside `ipBlock`, next to `cidr:`.** It is not a sibling
   of `from:` and there is no such thing as a top-level `except`. Getting the
   indentation wrong usually still parses as *something*, and you end up with
   a policy that admits the whole /16.
2. **Every `except` entry must be a subset of `cidr`.** The API server
   rejects the object outright otherwise (`except values must be within the
   CIDR range`). This is a rare case where a wrong NetworkPolicy fails loudly
   — take the free feedback.
3. **A single host is `/32`.** `except: [192.168.29.72]` with no prefix is not
   a CIDR and is rejected.

`except` is a hole punched in one `ipBlock`, nothing more. It does not
subtract from other rules: if a second `from:` item let the same address in,
it would still get in. Rules are ORed, and an `except` only narrows the peer
it is written inside.

## Why `ipBlock` is the wrong tool for pods — and why this question uses it anyway

`ipBlock` matches on **IP address**. Pod IPs are allocated at schedule time
and handed back when the pod dies, so the address you carefully quarantined
today belongs to a completely different workload after the next rollout. The
policy does not break; it silently starts protecting nothing and blocking
something innocent. That is why the task warns you not to re-create the Pods,
and why `setup.sh` has to go and look the addresses up — a question that
hard-coded them would be wrong within the hour.

The rule to carry into the exam:

| Peer | Use |
|---|---|
| Pods in this cluster | `podSelector` (+ `namespaceSelector`) |
| Everything in a Namespace | `namespaceSelector` |
| Anything with no Kubernetes identity — an on-prem database, a partner's VPN range, a monitoring appliance, the node network | `ipBlock` |

Labels travel with the workload; addresses do not. `ipBlock` exists for peers
that have no labels to select on, and that is the only time to reach for it.

## Two more `ipBlock` facts worth knowing

- **`ipBlock` never combines with a selector in the same list item.** Fields
  inside one `-` are ANDed, but an `ipBlock` peer is only ever an `ipBlock`.
  To allow "the api pods **or** the partner range" you write two `-` items.
- **A Service ClusterIP in an `ipBlock` matches nothing.** Policy is evaluated
  after kube-proxy has DNATed the ClusterIP to a real pod IP, so the address
  in the rule never appears on the wire at the point of enforcement.
