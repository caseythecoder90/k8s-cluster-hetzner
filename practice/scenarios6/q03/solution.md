# Q3 solution

```bash
k -n ganges get deploy ganges-web -o jsonpath='{.spec.template.spec.containers[0].ports}{"\n"}'
# [{"containerPort":80,"name":"http"},{"containerPort":9113,"name":"metrics"}]
vim /course6/3/service.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ganges-web
  namespace: ganges
spec:
  type: ClusterIP
  selector:
    app: ganges-web
  ports:
    - name: http           # the SERVICE port's name
      port: 80
      targetPort: http     # the CONTAINER port's name
    - name: metrics
      port: 9113
      targetPort: 9113
```

```bash
kubectl apply -f /course6/3/service.yaml
k -n ganges get endpoints ganges-web        # 10.244.x.x:80,10.244.x.x:9113,...
k -n ganges exec deploy/probe -- wget -qO- http://ganges-web:80
k -n ganges exec deploy/probe -- wget -qO- http://ganges-web:9113
```

## The two `name` fields, which are not the same field

This is the confusion the question exists to break.

- **`spec.ports[].name`** names the *Service's* port. It is what other
  resources refer to (`Ingress` backends use `service.port.name`, and
  `kubectl get svc` prints it). It has nothing to do with the container.
- **`spec.ports[].targetPort`** points at the *container's* port, either by
  number or by the name declared in `containers[].ports[].name`.

They happen to both be `http` here because that is the sane convention, not
because they are linked. Give the Service port the name `frontend` and
`targetPort: http` still resolves to container port 80.

## Why the name is worth using

`targetPort: http` is late-bound: the endpoints controller resolves the name
against each Pod's spec when it writes the EndpointSlice. So the day the app
moves from 80 to 8080, you change the container port and the Service needs no
edit — and different Pods behind the same Service may even use different
numbers for the same name. A numeric `targetPort` hard-codes today's number
into a second object.

A name must be a valid IANA service name: at most **15 characters**,
lowercase alphanumerics and `-`, with at least one letter. `http`, `metrics`,
`grpc-web` are fine; `HTTP` and `metrics-endpoint-v2` are not.

## Trap

**`name` is optional on a single-port Service and required as soon as there is
a second port.** Write this:

```yaml
  ports:
    - port: 80
      targetPort: http
    - port: 9113
```

and the API server refuses it with

```
Service "ganges-web" is invalid: spec.ports[0].name: Required value
```

which tells you the field but not the rule. The rule is: with more than one
port, every port needs a `name`, and the names must be unique within the
Service — because the port is addressed by name downstream (Endpoints,
Ingress, `kubectl port-forward`), and an unnamed port has no address.

Related habit: `targetPort` is the only place a **name** is legal. `port` and
`nodePort` are always numbers.
