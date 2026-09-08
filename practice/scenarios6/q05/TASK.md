# Q5 (topic: default-deny ingress for a whole Namespace)

Namespace `indus` is being locked down. Nothing may open a connection **to** any
Pod in it — not from another Namespace, and not from another Pod inside `indus`
either. The Pods must keep full outbound access, DNS above all: whatever you
write must not cost them name resolution.

Namespace `indus` runs `indus-web` (nginx, container port 80, labels
`app=indus-web`) and a busybox `indus-client` (labels `app=indus-client`).

1. Write a NetworkPolicy named `default-deny-ingress` in Namespace `indus`
2. It must select **every** Pod in the Namespace, present and future — not a
   list of the two that happen to exist today
3. It must deny all ingress to them and allow no exceptions
4. It must leave egress completely unrestricted

Save it as `/course6/5/policy.yaml` and apply it. Afterwards `indus-client`
must fail to reach `indus-web`, and must still resolve `kubernetes.default`.

> Target: 3 minutes. The whole spec is four lines and there are no rules in it
> at all — but the direction it denies is set by a field people leave out,
> and adding one word too many to that field takes DNS down with it.
