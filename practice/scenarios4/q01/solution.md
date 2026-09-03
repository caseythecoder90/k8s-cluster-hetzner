# Q1 solution

```bash
helm repo list                                   # already there? then skip the add
helm repo add hk-charts http://localhost:6100
helm repo update                                 # refresh the index after add
```

## Which charts does the repo have?

```bash
helm search repo hk-charts
```

```
NAME             CHART VERSION  APP VERSION  DESCRIPTION
hk-charts/api    2.2.0          2.2          Internal API service (practice chart)
hk-charts/nginx  1.2.0          1.27         Plain nginx web server (practice chart)
hk-charts/redis  0.7.1          7.4          Redis cache (practice chart)
```

One line per chart, **newest version only**. Strip the prefix and the header:

```bash
helm search repo hk-charts | awk 'NR>1 {print $1}' | sed 's#hk-charts/##' > /course4/1/charts
cat /course4/1/charts
```

Typing the three names by hand into the file is just as correct.

## All versions of one chart

The plain search hides older versions. `--versions` shows them all, newest
first:

```bash
helm search repo hk-charts/api --versions
```

```
NAME           CHART VERSION  APP VERSION  DESCRIPTION
hk-charts/api  2.2.0          2.2          ...
hk-charts/api  2.1.0          2.1          ...
hk-charts/api  2.0.0          2.0          ...
hk-charts/api  1.0.0          1.0          ...
```

```bash
helm search repo hk-charts/api --versions | awk 'NR>1 {print $2}' > /course4/1/api-versions
```

**CHART VERSION vs APP VERSION** is the trap: the question asks for chart
versions (the packaging version, what `--version` selects on install). APP
VERSION is the version of the software inside, informational only.

## Worth knowing

```bash
helm show chart hk-charts/api            # Chart.yaml of the newest version
helm show values hk-charts/api           # the configurable values (next question)
helm show values hk-charts/api --version 2.1.0
helm search repo api                     # matches across all added repos
```
