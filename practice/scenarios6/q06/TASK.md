# Q6 (topic: allow one label, on one port)

Namespace `jordan` runs `jordan-api` (labels `app=jordan-api`). Its container
listens on **two** ports: `8080` serves the application, `9090` serves an admin
endpoint that should never have been exposed. Service `jordan-api` publishes
both:

| Service port | goes to container port |
|---|---|
| `80` | `8080` |
| `9090` | `9090` |

Two busybox clients share the Namespace: Deployment `frontend` (labels
`app=frontend,role=frontend`) and Deployment `batch` (labels
`app=batch,role=batch`). Today both can reach both ports.

Write a NetworkPolicy named `allow-frontend` in Namespace `jordan` so that:

1. Only Pods labelled `role=frontend` may open connections to the `jordan-api`
   Pods
2. They may reach the **application** port only — the admin port must be closed
   to everyone, `frontend` included
3. Everything else keeps working: do not edit the Deployment, the Service or
   the clients, and do not delete the Service's admin port

Save it as `/course6/6/policy.yaml` and apply it.

> Target: 5 minutes. The port number you put in the policy is not the port
> number you curl — a NetworkPolicy has never heard of a Service.
