# 05 — Migrating the apps from the old VPS

Zero-downtime plan: the old VPS keeps serving `caseyrquinn.com` until the very
last step. Everything is built and tested on the cluster first; DNS flips only
when proven. Rollback at any point before step 7 = do nothing.

```
1. storage provisioner ─▶ 2. cert-manager ─▶ 3. secrets ─▶ 4. deploy apps
        ─▶ 5. test via --resolve ─▶ 6. copy databases ─▶ 7. DNS flip ─▶ 8. decommission
```

## 1. Storage provisioner

Follow [kubernetes/cluster/local-path-storage/README.md](../kubernetes/cluster/local-path-storage/README.md).

## 2. cert-manager

Install per [kubernetes/cluster/cert-manager/README.md](../kubernetes/cluster/cert-manager/README.md)
— but **hold the ClusterIssuer + ingress TLS until step 7** (issuance needs DNS
pointing here; until then apps are tested over plain HTTP with --resolve).

## 3. Namespaces + secrets

```bash
kubectl apply -k kubernetes/cluster/namespaces
```

**Pull secret** (backend image is private on GHCR). Create a GitHub PAT
(classic) with **only `read:packages`** scope, then:

```bash
kubectl -n personal-website create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io --docker-username=caseythecoder90 --docker-password=<PAT>
```

**App secrets** — same key names as the old `.env` files, values copied from
the VPS. Hostname-bearing values change: DB/Redis hosts are now the k8s
Service names (`postgres`, `redis`):

```bash
kubectl -n personal-website create secret generic personal-website-secrets \
  --from-literal=POSTGRES_DB=<same-as-vps> \
  --from-literal=POSTGRES_USER=<same> \
  --from-literal=POSTGRES_PASSWORD=<same> \
  --from-literal=DB_URL='jdbc:postgresql://postgres:5432/<POSTGRES_DB value>' \
  --from-literal=DB_USER=<same-as-POSTGRES_USER> \
  --from-literal=DB_PASSWORD=<same-as-POSTGRES_PASSWORD> \
  --from-literal=REDIS_HOST=redis \
  --from-literal=REDIS_PORT=6379 \
  --from-literal=REDIS_PASSWORD=<same> \
  --from-literal=CLOUD_NAME=<same> \
  --from-literal=CLOUDINARY_API_KEY=<same> \
  --from-literal=CLOUDINARY_API_SECRET=<same> \
  --from-literal=JWT_SECRET=<same> \
  --from-literal=JASYPT_ENCRYPTOR_PASSWORD=<same> \
  --from-literal=RESEND_API_KEY=<same> \
  --from-literal=OWNER_EMAIL=<same>
```

```bash
kubectl -n grindtrack create secret generic grindtrack-secrets \
  --from-literal=POSTGRES_DB=<same-as-vps> \
  --from-literal=POSTGRES_USER=<same> \
  --from-literal=POSTGRES_PASSWORD=<same> \
  --from-literal=JWT_SECRET=<same> \
  --from-literal=GRINDTRACK_USERNAME=<same> \
  --from-literal=GRINDTRACK_PASSWORD=<same>
```

(Typing secrets on the command line lands them in shell history — acceptable
here; `history -c` after, or use `read -s` per value if it bothers you. The
proper fix later is Sealed Secrets or SOPS.)

## 4. Deploy

```bash
kubectl apply -k kubernetes/apps/personal-website/overlays/prod
kubectl apply -k kubernetes/apps/grindtrack/overlays/prod
kubectl get pods -n personal-website -w    # everything Running/Ready
```

Expected on first rollout: postgres/redis come up fast; backends restart once
or twice while their DB initializes — that's the readiness probe doing its job.

## 5. Test through the real path (DNS still on old VPS)

`--resolve` fakes DNS for one request — the Host header is real, so ingress
routing is exercised end to end:

```bash
WORKER_IP=$(cd terraform && terraform output -raw worker_public_ip)
curl -s --resolve caseyrquinn.com:80:$WORKER_IP http://caseyrquinn.com | head -20
curl -s --resolve api.caseyrquinn.com:80:$WORKER_IP http://api.caseyrquinn.com/actuator/health
curl -s --resolve track.caseyrquinn.com:80:$WORKER_IP http://track.caseyrquinn.com/api/public/stats
```

## 6. Copy the databases

The only step with (write-)downtime, per app: dump on the VPS, restore into
the cluster pod. Fresh empty targets — drop what Flyway auto-created first is
not needed (`--clean` handles it).

```bash
# on the old VPS
docker exec personal-website-postgres pg_dump -U <user> -Fc <db> > pw.dump
docker exec grindtrack-db pg_dump -U <user> -Fc <db> > gt.dump
# copy to workstation: scp vps:pw.dump vps:gt.dump .

# into the cluster (kubectl exec streams stdin into the pod)
kubectl -n personal-website exec -i deploy/postgres -- \
  pg_restore -U <user> -d <db> --clean --if-exists < pw.dump
kubectl -n grindtrack exec -i deploy/postgres -- \
  pg_restore -U <user> -d <db> --clean --if-exists < gt.dump
```

Restart backends so caches/sequences are fresh, and re-run step 5 checks —
real data should now appear:

```bash
kubectl -n personal-website rollout restart deploy/backend
kubectl -n grindtrack rollout restart deploy/grindtrack
```

## 7. TLS + DNS flip

1. Apply the ClusterIssuer: `kubectl apply -f kubernetes/cluster/cert-manager/clusterissuer.yaml`
2. At your DNS provider, point A records to the **worker public IP**:
   `caseyrquinn.com`, `www`, `api`, `track`. Lower TTL to 300s beforehand if possible.
3. As DNS propagates, cert-manager auto-issues all four certs
   (`kubectl get certificate -A` → READY True, usually within a couple minutes).
4. Verify for real: `curl -I https://caseyrquinn.com` etc. — valid TLS, right content.

If anything is wrong: point DNS back at the old VPS. It's still running,
unchanged. (Any DB writes made on the cluster since step 6 would need dumping
back — keep the window short or repeat step 6 in reverse.)

## 8. Decommission

After a few quiet days: final `pg_dump` from the cluster as a keepsake backup,
then delete the old VPS. That's the moment this migration starts saving money.
