# Q3 (topic: a named `targetPort`, and a second port on the same Service)

Deployment `ganges-web` in Namespace `ganges` runs 2 Pods labelled
`app=ganges-web`. Its container listens on two ports, and the Pod spec names
them:

```yaml
ports:
  - name: http
    containerPort: 80
  - name: metrics
    containerPort: 9113
```

Create one ClusterIP Service `ganges-web` in Namespace `ganges` fronting both:

1. Selects the `ganges-web` Pods
2. A Service port `80` called `http`, whose `targetPort` is the container
   port's **name** `http` — the number `80` must not appear as the targetPort
3. A Service port `9113` called `metrics`, reaching container port `9113`

Save it as `/course6/3/service.yaml` and apply it. Both ports must actually
serve: `http://<clusterIP>:80` returns `ganges-web`, `http://<clusterIP>:9113`
returns `ganges-metrics`.

> Target: 4 minutes. The second port is where this one bites — a field that is
> optional on a single-port Service becomes mandatory the moment there are two,
> and the API server's error message names the field but not the reason.
