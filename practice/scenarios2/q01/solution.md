# Q1 solution

```bash
k get pods -A -l tier=demo -o custom-columns=NAME:.metadata.name --no-headers \
  | sort > /course2/1/demo-pods
cat /course2/1/demo-pods
```

`-A` = all namespaces. `-l tier=demo` filters server-side — faster and safer
than piping through grep, and it's exactly the label the decoy pod lacks.
`custom-columns` with `--no-headers` gives bare names with no extra noise to
strip. `sort` satisfies "alphabetically."
