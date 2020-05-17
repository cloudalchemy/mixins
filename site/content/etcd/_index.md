---
title: etcd
---



{{< panel style="primary" title="Jsonnet source" >}}
Mixin jsonnet code is available at [github.com/etcd-io/etcd](https://github.com/etcd-io/etcd/tree/master/Documentation/etcd-mixin)
{{< /panel >}}

## Alerts

{{< panel style="info" >}}
Complete list of pregenerated alerts is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/etcd/alerts.yaml).
{{< /panel >}}

### etcdMembersDown

{{< code lang="yaml" >}}
alert: etcdMembersDown
annotations:
  message: 'etcd cluster "{{ $labels.job }}": members are down ({{ $value }}).'
expr: |
  max by (job) (
    sum by (job) (up{job=~".*etcd.*"} == bool 0)
  or
    count by (job,endpoint) (
      sum by (job,endpoint,To) (rate(etcd_network_peer_sent_failures_total{job=~".*etcd.*"}[3m])) > 0.01
    )
  )
  > 0
for: 3m
labels:
  severity: critical
{{< /code >}}
 
### etcdInsufficientMembers

{{< code lang="yaml" >}}
alert: etcdInsufficientMembers
annotations:
  message: 'etcd cluster "{{ $labels.job }}": insufficient members ({{ $value }}).'
expr: |
  sum(up{job=~".*etcd.*"} == bool 1) by (job) < ((count(up{job=~".*etcd.*"}) by (job) + 1) / 2)
for: 3m
labels:
  severity: critical
{{< /code >}}
 
### etcdNoLeader

{{< code lang="yaml" >}}
alert: etcdNoLeader
annotations:
  message: 'etcd cluster "{{ $labels.job }}": member {{ $labels.instance }} has no
    leader.'
expr: |
  etcd_server_has_leader{job=~".*etcd.*"} == 0
for: 1m
labels:
  severity: critical
{{< /code >}}
 
### etcdHighNumberOfLeaderChanges

{{< code lang="yaml" >}}
alert: etcdHighNumberOfLeaderChanges
annotations:
  message: 'etcd cluster "{{ $labels.job }}": {{ $value }} leader changes within the
    last 15 minutes. Frequent elections may be a sign of insufficient resources, high
    network latency, or disruptions by other components and should be investigated.'
expr: |
  increase((max by (job) (etcd_server_leader_changes_seen_total{job=~".*etcd.*"}) or 0*absent(etcd_server_leader_changes_seen_total{job=~".*etcd.*"}))[15m:1m]) >= 3
for: 5m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighNumberOfFailedGRPCRequests

{{< code lang="yaml" >}}
alert: etcdHighNumberOfFailedGRPCRequests
annotations:
  message: 'etcd cluster "{{ $labels.job }}": {{ $value }}% of requests for {{ $labels.grpc_method
    }} failed on etcd instance {{ $labels.instance }}.'
expr: |
  100 * sum(rate(grpc_server_handled_total{job=~".*etcd.*", grpc_code!="OK"}[5m])) BY (job, instance, grpc_service, grpc_method)
    /
  sum(rate(grpc_server_handled_total{job=~".*etcd.*"}[5m])) BY (job, instance, grpc_service, grpc_method)
    > 1
for: 10m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighNumberOfFailedGRPCRequests

{{< code lang="yaml" >}}
alert: etcdHighNumberOfFailedGRPCRequests
annotations:
  message: 'etcd cluster "{{ $labels.job }}": {{ $value }}% of requests for {{ $labels.grpc_method
    }} failed on etcd instance {{ $labels.instance }}.'
expr: |
  100 * sum(rate(grpc_server_handled_total{job=~".*etcd.*", grpc_code!="OK"}[5m])) BY (job, instance, grpc_service, grpc_method)
    /
  sum(rate(grpc_server_handled_total{job=~".*etcd.*"}[5m])) BY (job, instance, grpc_service, grpc_method)
    > 5
for: 5m
labels:
  severity: critical
{{< /code >}}
 
### etcdGRPCRequestsSlow

{{< code lang="yaml" >}}
alert: etcdGRPCRequestsSlow
annotations:
  message: 'etcd cluster "{{ $labels.job }}": gRPC requests to {{ $labels.grpc_method
    }} are taking {{ $value }}s on etcd instance {{ $labels.instance }}.'
expr: |
  histogram_quantile(0.99, sum(rate(grpc_server_handling_seconds_bucket{job=~".*etcd.*", grpc_type="unary"}[5m])) by (job, instance, grpc_service, grpc_method, le))
  > 0.15
for: 10m
labels:
  severity: critical
{{< /code >}}
 
### etcdMemberCommunicationSlow

{{< code lang="yaml" >}}
alert: etcdMemberCommunicationSlow
annotations:
  message: 'etcd cluster "{{ $labels.job }}": member communication with {{ $labels.To
    }} is taking {{ $value }}s on etcd instance {{ $labels.instance }}.'
expr: |
  histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket{job=~".*etcd.*"}[5m]))
  > 0.15
for: 10m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighNumberOfFailedProposals

{{< code lang="yaml" >}}
alert: etcdHighNumberOfFailedProposals
annotations:
  message: 'etcd cluster "{{ $labels.job }}": {{ $value }} proposal failures within
    the last 30 minutes on etcd instance {{ $labels.instance }}.'
expr: |
  rate(etcd_server_proposals_failed_total{job=~".*etcd.*"}[15m]) > 5
for: 15m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighFsyncDurations

{{< code lang="yaml" >}}
alert: etcdHighFsyncDurations
annotations:
  message: 'etcd cluster "{{ $labels.job }}": 99th percentile fync durations are {{
    $value }}s on etcd instance {{ $labels.instance }}.'
expr: |
  histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket{job=~".*etcd.*"}[5m]))
  > 0.5
for: 10m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighCommitDurations

{{< code lang="yaml" >}}
alert: etcdHighCommitDurations
annotations:
  message: 'etcd cluster "{{ $labels.job }}": 99th percentile commit durations {{
    $value }}s on etcd instance {{ $labels.instance }}.'
expr: |
  histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket{job=~".*etcd.*"}[5m]))
  > 0.25
for: 10m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighNumberOfFailedHTTPRequests

{{< code lang="yaml" >}}
alert: etcdHighNumberOfFailedHTTPRequests
annotations:
  message: '{{ $value }}% of requests for {{ $labels.method }} failed on etcd instance
    {{ $labels.instance }}'
expr: |
  sum(rate(etcd_http_failed_total{job=~".*etcd.*", code!="404"}[5m])) BY (method) / sum(rate(etcd_http_received_total{job=~".*etcd.*"}[5m]))
  BY (method) > 0.01
for: 10m
labels:
  severity: warning
{{< /code >}}
 
### etcdHighNumberOfFailedHTTPRequests

{{< code lang="yaml" >}}
alert: etcdHighNumberOfFailedHTTPRequests
annotations:
  message: '{{ $value }}% of requests for {{ $labels.method }} failed on etcd instance
    {{ $labels.instance }}.'
expr: |
  sum(rate(etcd_http_failed_total{job=~".*etcd.*", code!="404"}[5m])) BY (method) / sum(rate(etcd_http_received_total{job=~".*etcd.*"}[5m]))
  BY (method) > 0.05
for: 10m
labels:
  severity: critical
{{< /code >}}
 
### etcdHTTPRequestsSlow

{{< code lang="yaml" >}}
alert: etcdHTTPRequestsSlow
annotations:
  message: etcd instance {{ $labels.instance }} HTTP requests to {{ $labels.method
    }} are slow.
expr: |
  histogram_quantile(0.99, rate(etcd_http_successful_duration_seconds_bucket[5m]))
  > 0.15
for: 10m
labels:
  severity: warning
{{< /code >}}
 
## Dashboards
Following dashboards are generated from mixins and hosted on github:


- [etcd](https://github.com/cloudalchemy/mixins/blob/master/manifests/etcd/dashboards/etcd.json)