# Q7 (topics: multi-container pods, sidecar pattern)

Pod `poseidon-web` in Namespace `poseidon` runs one container (`web`) that
writes to `/var/log/app/access.log` on an `emptyDir` volume.

Add a **sidecar** container:

1. Name `log-shipper`, image `busybox:1`
2. Mounts the **same volume**, at the same path
3. Runs `tail -F /var/log/app/access.log` (streams new lines as they're
   written — both containers run concurrently, unlike an initContainer)
