# Q5 (topic: RBAC)

Namespace `apollo` has an existing ServiceAccount `apollo-reader`.

1. Create a Role `apollo-pod-reader` in `apollo` allowing **get, list, watch**
   on **pods** only (no other resource, no write verbs).
2. Bind it to `apollo-reader` via a RoleBinding named
   `apollo-pod-reader-binding`.

The ServiceAccount should be able to list pods in `apollo`, but must **not**
be able to delete them.
