# Q4 (topic: Helm history and rollback)

The most recent upgrade of release `garnet-api` in Namespace `garnet` went
wrong: the new Pods never become ready.

1. Inspect the release history and identify the last revision that worked
2. Roll the release back to that revision. Do **not** fix the problem with a
   new upgrade — the team wants Helm's rollback mechanism used
3. Afterwards write the revision number that is now deployed to
   `/course4/4/revision`, and the chart version now deployed (just the
   version, e.g. `1.2.3`) to `/course4/4/chart-version`
