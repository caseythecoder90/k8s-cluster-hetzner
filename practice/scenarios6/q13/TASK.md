# Q13 (topic: blue/green — validate, cut over, roll back)

Namespace `yangtze` runs the live Service `orders` (ClusterIP, `:80`), backed
by `orders-blue` (2 replicas, `track: blue`, serving `orders-v1`).
`orders-green` (2 replicas, `track: green`, serving `orders-v2`) is deployed
and taking no traffic. Client `probe` is there to fetch from.

Run the release end to end. Green turns out to be bad, so you will also back
it out.

1. **Validate green with no production traffic.** Create a second Service
   `orders-test` in `yangtze` — ClusterIP, port `80`, targetPort `80` — that
   selects the **green** pods only. Confirm it answers `orders-v2` while
   `orders` is still answering `orders-v1`
2. **Cut over.** Point Service `orders` at green
3. **Record the cutover.** While green is live on `orders`, save the Service's
   selector to `/course6/13/cutover.txt`:

   ```bash
   kubectl -n yangtze get svc orders -o jsonpath='{.spec.selector}' > /course6/13/cutover.txt
   ```

4. **Roll back.** Green is misbehaving. Put Service `orders` back on blue

End state: `orders` serves `orders-v1`, `orders-test` still serves
`orders-v2`, both Deployments still running at 2 ready replicas each, and
`cutover.txt` proving green was live.

Do not scale, edit or delete either Deployment at any point.

> Target: 8 minutes. Steps 2 and 4 are the same operation, and the reason step
> 4 takes seconds instead of minutes is something you must deliberately *not*
> do in between.
