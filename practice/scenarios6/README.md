# CKAD practice — Exam Set 6: Services, NetworkPolicy, traffic shifting

Sixteen original questions on the Services & Networking domain (~20% of the
exam) plus the two release patterns CKAD asks you to assemble from primitives:
blue/green and canary. Written to the syllabus of
`notes/07-services-and-networking/` and `notes/05-pod-design/03`–`04` in the
ckad-exam-prep repo.

Uses `/course6/N/...` for files and river Namespaces (`amazon` … `elbe`), so it
never collides with Sets 1–5 (planets, trees, gemstones, metals) on the same
cluster.

## Workflow

```bash
./setup-all.sh           # build all 16 starting states
cat TASKS-ALL.md         # read the questions
# ...solve on the control plane, exam-style...
./verify-all.sh          # score yourself
```

Single question:

```bash
./setup-all.sh q09
cat q09/TASK.md
./verify-all.sh q09
```

Re-running a question's `setup.sh` resets it. `./cleanup.sh` removes everything
this set created and leaves the other sets alone.

## The policies are really enforced

This lab runs **Calico**, so a NetworkPolicy here does what it does on the exam:
it actually drops packets. Every policy question's `verify.sh` therefore asserts
**both directions of the truth** — that the traffic you were told to allow still
flows, *and* that the traffic you were told to block is genuinely blocked. A
policy that denies everything fails, the same as one that allows everything.
`kubectl apply`-ing valid YAML is not the pass condition; behaviour is.

Probes run from long-lived busybox Pods with stable labels (`client` in
`common.sh`) rather than one-shot `kubectl run`, so the policies have something
real to select on and a check costs an `exec` instead of a Pod start. Web
servers (`webserver` in `common.sh`) serve their own identity as their index
page, which is what makes a traffic split observable.

## Two environment caveats

| | |
|---|---|
| **No ingress controller** | `ingress-nginx` is installed on the prod cluster, not this lab. q16 therefore checks the Ingress resource **structurally** — rules, hosts, paths, `pathType`, backend service names and ports — and never issues an HTTP request through it. Nothing will serve on the Ingress; that is expected, not a bug. Writing a correct Ingress under time pressure is the examinable skill, and that is what is graded. |
| **NodePorts use the private IP** | Questions that reach a NodePort curl the control plane's private address `10.10.1.10`, not `localhost` — the same adaptation Set 4 makes. |

## Topic map

| # | Topic | Namespace(s) | Difficulty |
|---|---|---|---|
| q01 | Service with a selector matching nothing; `get endpoints` as diagnostic #1 | amazon | warm-up |
| q02 | NodePort: `port` vs `targetPort` vs `nodePort` | danube | easy |
| q03 | named `targetPort`; multi-port Services need `name:` per port | ganges | medium |
| q04 | endpoints populated but connection refused — a `targetPort` fault | hudson | medium |
| q05 | default-deny ingress with `podSelector: {}`; egress still open | indus | medium |
| q06 | allow from one pod label, on one port | jordan | medium |
| q07 | `namespaceSelector` + `kubernetes.io/metadata.name` | mekong, nile | medium |
| q08 | **AND vs OR — the dash is the operator** | oder, rhine | **hard** |
| q09 | egress policy + **the DNS :53 trap** | seine | **hard** |
| q10 | `ipBlock` with `except:` | thames | **hard** |
| q11 | one policy, both directions, `policyTypes` | tiber | medium |
| q12 | blue/green: flip the Service selector | volga | easy |
| q13 | blue/green done properly: validate, cut over, roll back | yangtze | medium |
| q14 | canary: shared label + replica ratio sets the split | zambezi | medium |
| q15 | canary promotion: primary forward, canary gone, Service untouched | congo | medium |
| q16 | Ingress host + path routing (structural check — no controller here) | elbe | medium |

## The two questions to get right before Saturday

**q08** and **q09**. The AND/OR dash is the most reliable way an examiner can
tell whether you understand `from:` semantics or are pattern-matching YAML, and
the DNS trap is the one that makes an otherwise perfect egress policy break the
application in a way that looks like it has nothing to do with your policy.
