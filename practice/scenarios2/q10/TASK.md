# Q10 (topic: debugging CrashLoopBackOff)

Deployment `hera-worker` in Namespace `hera` is stuck `CrashLoopBackOff`.

1. Investigate and identify the root cause.
2. Fix the Deployment so the container runs successfully — override its
   `command` to `sleep 3600` (a valid busybox command) so it stays up.
3. Write a one-line explanation of the root cause into
   `/course2/10/root-cause.txt` on the control-plane host.
