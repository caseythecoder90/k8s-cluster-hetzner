# Q16 solution

```bash
k -n atlas create deploy atlas-web --image=nginx:1-alpine $do > d.yaml
vim d.yaml
```

```yaml
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox:1
        command:
          - sh
          - -c
          - "until nc -z atlas-db-svc 5432; do echo waiting for db; sleep 2; done"
      containers:
      - name: nginx
        image: nginx:1-alpine
```

```bash
k apply -f d.yaml
k -n atlas get pods -w        # Init:0/1 -> PodInitializing -> Running
k -n atlas logs deploy/atlas-web -c wait-for-db
```

The pattern: `until <command that fails until ready>; do sleep; done` is the
standard shell idiom for "poll until a condition holds" — worth having
memorized verbatim, since it comes up for waiting on a database, another
service, a file appearing, or any other readiness gate you'd express in a
initContainer rather than in the app itself.

Concept: an initContainer running `nc -z` here means the **main container
literally cannot start** until the dependency answers — this is stronger and
simpler than a readinessProbe on the main container, because the app process
never even launches against a database that isn't there yet. Multiple
initContainers run in the order listed, each must fully complete before the
next starts.
