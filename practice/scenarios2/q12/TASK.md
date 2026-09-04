# Q12 (topic: NetworkPolicy)

Namespace `demeter` has `demeter-backend` (label `app=backend`, Service
`demeter-backend-svc` on port 80) and `demeter-frontend` (label
`app=frontend`).

Create a NetworkPolicy `demeter-backend-policy` in `demeter` that:

1. Applies to pods labelled `app=backend`
2. Allows **ingress** only from pods labelled `app=frontend` **within the
   same namespace**
3. Only on **port 80**
4. Everything else inbound to the backend is denied

Test it: a request from `demeter-frontend`'s pod should succeed; a request
from the unrelated pod in `demeter-other` should **not**.
