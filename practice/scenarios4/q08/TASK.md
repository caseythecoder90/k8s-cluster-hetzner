# Q8 (topic: Helm pull and local charts)

Team Ruby wants to vendor a chart into their own repository and adjust its
defaults.

1. Download chart `hk-charts/redis` in version `0.6.0` (not the latest) to
   `/course4/8/` and extract it there, so that `/course4/8/redis/Chart.yaml`
   exists
2. Change the chart's *default* for `replicaCount` to `2` in its `values.yaml`
3. Install the chart **from that local directory** as release `ruby-cache`
   into Namespace `ruby` (create it). Pass no values on the command line —
   the edited default must do the work
