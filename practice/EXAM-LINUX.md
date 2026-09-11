# Linux text tools for the exam

Companion to `EXAM-SPEED.md`. That file is about changing cluster state fast;
this one is about the other half of the exam — questions that end with *"write
the name to /opt/course/x.txt"*, *"how many pods are not Running"*, *"decode
the secret"*. Those are graded on a **file with exact contents**, so the shell
pipeline is the answer, not kubectl.

## First: don't reach for awk if kubectl can do it

kubectl formats its own output, and the formatted version can't drift the way
column positions can.

```bash
k get po --no-headers                       # drops the header row entirely
k get po -o name                            # pod/nginx  (prefix included!)
k get po -o custom-columns=NAME:.metadata.name --no-headers
k get po -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --no-headers
k get po -o jsonpath='{.items[*].metadata.name}'
```

`--no-headers` is the direct answer to "skip the header" — no awk needed.
Use awk when the data is *already* text (logs, `/etc/passwd`, a file the
question gave you) or when you need to filter/compute on it.

## awk — the ten patterns that cover everything

awk runs `pattern { action }` once per line. Fields are whitespace-split into
`$1 $2 $3…`, `$0` is the whole line, `NR` is the line number, `NF` the number
of fields.

```bash
awk '{print $1}'  file              # first column
awk 'NR>1 {print $1}'  file         # SKIP THE HEADER, then first column
awk '{print $NF}'  file             # last column, however many there are
awk '{print $1, $3}'  file          # two columns, space-joined
awk -F: '{print $1}' /etc/passwd    # different separator (-F, for CSV)
awk '$3=="Running" {print $1}'      # filter on a field, then print another
awk '$4>0 {print $1, $4}'           # numeric comparison
awk '/CrashLoop/ {print $1}'        # filter on a regex anywhere in the line
awk 'END {print NR}'  file          # line count (same as wc -l)
awk '{sum+=$2} END {print sum}'     # add up a column
```

Combine the pattern and the action freely — `awk 'NR>1 && $3!="Running" {print $1}'`
is "skip the header, show me the broken pods' names".

Two more worth knowing:

```bash
awk 'NR==3'                          # print just line 3 (no action = print $0)
awk '{printf "%-30s %s\n", $1, $3}'  # aligned columns instead of ragged
```

`tail -n +2` skips the header too, and reads better in a long pipeline:
`k get po | tail -n +2 | ...`.

### The quoting trap

Always single-quote the awk program. In double quotes, **bash** expands `$1`
first — into the empty string — and awk receives `{print }`:

```bash
awk "{print $1}"   # BROKEN: prints whole lines
awk '{print $1}'   # correct
```

### The column-counting trap

Column numbers shift, and two things shift them on the exam:

- `-A` / `--all-namespaces` inserts NAMESPACE as `$1`, pushing everything
  right by one. `k get po` → STATUS is `$3`; `k get po -A` → STATUS is `$4`.
- A pod that has restarted prints RESTARTS as `2 (5m ago)` — that's **three**
  whitespace fields, not one, so every column after it moves by two.

If restarts might be non-zero, use `-o custom-columns` (fixed fields, no
surprises) instead of counting positions.

## sed — line surgery

```bash
sed -n '5p'  file             # print only line 5  (-n = don't auto-print)
sed -n '5,10p'  file          # lines 5-10
sed '1d'  file                # delete the header line
sed 's/old/new/'  file        # replace FIRST match on each line
sed 's/old/new/g'  file       # replace all matches
sed -i 's/old/new/g'  file    # edit the file in place (no backup)
sed -i.bak 's/old/new/g' file # in place, keeping file.bak
sed -n '/Events/,$p'  file    # from the first match to end of file
```

`sed -i` on a YAML file is the fastest way to bulk-rename an image tag or a
namespace across a manifest you were given.

## grep — the flags that matter

```bash
grep -i error          # case-insensitive
grep -v Running        # invert: lines that DON'T match
grep -c Error          # count matching lines
grep -n Error          # show line numbers
grep -w app            # whole word only (not "apple")
grep -E 'Pending|Failed'   # regex alternation (or use grep -e a -e b)
grep -o 'image: .*'    # print only the matched part, not the line
grep -A5 Events        # 5 lines After  (-B before, -C both)
grep -r -l --include='*.yaml' securityContext /course   # which files mention it
grep -q Running && echo yes    # silent, use the exit code only
```

`k describe po x | grep -A10 Events` is the single most useful troubleshooting
line in the exam.

## Counting, sorting, slicing

```bash
wc -l  file                    # line count
sort -k2 -rn                   # sort by column 2, numeric, descending
sort -u                        # sort + dedupe
uniq -c                        # count runs of identical lines
cut -d: -f1  /etc/passwd       # field 1 by delimiter (single char only)
cut -d/ -f2                    # strip the "pod/" from `k get po -o name`
tr ' ' '\n'                    # turn a space-separated line into one per line
tr -d '\n'                     # strip newlines (e.g. before base64)
head -1  /  tail -5  /  tail -n +2
```

**`uniq` only dedupes adjacent lines** — it must follow `sort`. The idiom for
"most common thing" is always `sort | uniq -c | sort -rn | head`.

## Plumbing: pipes, files, xargs

```bash
cmd > f            # overwrite     cmd >> f    # append
cmd 2>/dev/null    # discard errors only
cmd &> f           # stdout + stderr into one file
cmd | tee f        # write to f AND keep it flowing down the pipe
cat f | tee /opt/course/save.yaml | k apply -f -   # the "save AND apply" task
... | xargs k delete po                            # names as arguments
... | xargs -I{} k label po {} tier=web            # one call per item
```

`tee` is the direct answer to the trap in `EXAM-SPEED.md`: when a question
says save the YAML *and* apply it, both are graded.

`k apply -f -` reads the manifest from stdin, so nothing needs a temp file.

## Secrets: base64

```bash
echo -n 'S3cret' | base64                      # encode  (-n is mandatory)
echo 'UzNjcmV0' | base64 -d                    # decode
k get secret s -o jsonpath='{.data.password}' | base64 -d
```

Without `-n`, `echo` adds a newline and you encode `S3cret\n` — the password
is then wrong in a way nothing warns you about. For long values add `-w 0`
so base64 doesn't wrap the output across lines.

## Finding files

```bash
find / -name '*.yaml' -type f 2>/dev/null      # 2>/dev/null hides permission noise
find /course -mmin -5                          # modified in the last 5 minutes
ls -la /opt/course/                            # verify what you actually wrote
```

Always `cat` the file you were asked to create before moving on. A file with a
trailing blank line, a `pod/` prefix, or a header row you forgot to strip
scores zero.

## vim, because every YAML edit goes through it

Set this once at the start of the exam (tabs are invalid in YAML — this is the
one that saves you):

```vim
:set et ts=2 sw=2 ai nu
```

`et`=expandtab, `ts`/`sw`=2-space indents, `ai`=autoindent, `nu`=line numbers.

| Do this | Keys |
|---|---|
| Top / bottom / line 12 | `gg` / `G` / `:12` |
| Delete line / 3 lines | `dd` / `3dd` |
| Copy line / paste | `yy` / `p` |
| Undo / redo | `u` / `Ctrl+r` |
| Search, next hit | `/text` then `n` |
| Replace everywhere | `:%s/old/new/g` |
| Indent a block | `V` select, then `>` or `<` |
| Same edit on many lines | `Ctrl+v`, select rows, `I`, type, `Esc` |
| Save a copy elsewhere | `:w /opt/course/file.yaml` |
| Save+quit / quit hard | `:wq` / `:q!` |

Before pasting anything into vim: `:set paste` — otherwise autoindent
compounds each line's indentation and the YAML arrives shredded. `:set nopaste`
after.

## Recipes the exam actually asks for

| Task | Pipeline |
|---|---|
| Node using the most CPU, into a file | `k top node --no-headers \| sort -k2 -rn \| head -1 \| awk '{print $1}' > /opt/course/node.txt` |
| Pod using the most memory in a namespace | `k top pod -n neptune --no-headers \| sort -k3 -rn \| head -1` |
| Just the pod names, one per line | `k get po -n neptune --no-headers \| awk '{print $1}'` |
| Pods that aren't Running | `k get po -A --no-headers \| awk '$4!="Running" {print $1, $2, $4}'` |
| Count pods per namespace, busiest first | `k get po -A --no-headers \| awk '{print $1}' \| sort \| uniq -c \| sort -rn` |
| Every image in the cluster, deduped | `k get po -A -o jsonpath='{.items[*].spec.containers[*].image}' \| tr ' ' '\n' \| sort -u` |
| Which node each pod is on | `k get po -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName --no-headers` |
| Errors from a Deployment's logs, saved | `k logs deploy/web \| grep -i error \| tee /opt/course/errors.log` |
| Container names in a multi-container pod | `k get po x -o jsonpath='{.spec.containers[*].name}'` |
| Events, newest last | `k get events -n neptune --sort-by=.metadata.creationTimestamp` |

## Two small things that waste minutes

- `watch k get po` fails — `watch` doesn't expand shell aliases. Use
  `k get po -w` (kubectl's own watch) or `watch kubectl get po`.
- `sort -k2` without `-n` sorts *alphabetically*, so 100m lands before 9m.
  Any question about "most/highest" needs `-rn`.
