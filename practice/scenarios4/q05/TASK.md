# Q5 (topic: Helm release housekeeping)

Teams Jade and Onyx share the cluster. Do some Helm housekeeping for them:

1. Uninstall release `onyx-legacy` in Namespace `onyx`
2. Upgrade release `onyx-web` (Namespace `onyx`) to the newest available
   version of its chart, keeping the values it was installed with
3. Somewhere in the cluster a release is stuck in a `pending-*` status after
   a Helm operation was interrupted. Find it and uninstall it. Before you do,
   write `<namespace>/<release-name>` to `/course4/5/stuck`
4. Write the number of Helm releases that remain in Namespaces `jade` and
   `onyx` combined to `/course4/5/count`
