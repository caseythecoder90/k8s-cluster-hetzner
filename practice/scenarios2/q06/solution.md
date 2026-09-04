# Q6 solution

Investigate first — this is the reflex the exam wants to see:

```bash
k -n artemis get pods                    # ImagePullBackOff / ErrImagePull
k -n artemis describe pod <pod-name>      # Events: "manifest unknown" / pull error
k -n artemis rollout history deploy/artemis-api
```

Then roll back:

```bash
k -n artemis rollout undo deploy/artemis-api
k -n artemis rollout status deploy/artemis-api
```

```bash
k -n artemis get deploy artemis-api -o jsonpath='{.spec.template.spec.containers[0].image}'
```

`rollout undo` reverts to the **previous** revision by default. To go back
further: `k rollout history deploy/artemis-api` lists revisions, then
`k rollout undo deploy/artemis-api --to-revision=N` targets a specific one.

Why undo instead of just `set image` back to the right tag by hand: it's
faster (one command, no need to remember/retype the correct tag), and it's
the mechanism the exam is actually testing — a manual `set image` would
"fix" the symptom without demonstrating rollback knowledge, and on a real
production incident you may not even know the exact prior value offhand.
