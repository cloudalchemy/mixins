---
title: kube-state-metrics
---

## Overview



{{< panel style="primary" title="Jsonnet source" >}}
Mixin jsonnet code is available at [github.com/kubernetes/kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/tree/master/jsonnet/kube-state-metrics-mixin)
{{< /panel >}}

## Alerts

{{< panel style="info" >}}
Complete list of pregenerated alerts is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/kube-state-metrics/alerts.yaml).
{{< /panel >}}

### kube-state-metrics

##### KubeStateMetricsListErrors

{{< code lang="yaml" >}}
alert: KubeStateMetricsListErrors
annotations:
  message: kube-state-metrics is experiencing errors at an elevated rate in list operations.
    This is likely causing it to not be able to expose metrics about Kubernetes objects
    correctly or at all.
expr: |
  (sum(rate(kube_state_metrics_list_total{job="kube-state-metrics",result="error"}[5m]))
    /
  sum(rate(kube_state_metrics_list_total{job="kube-state-metrics"}[5m])))
  > 0.01
for: 15m
labels:
  severity: critical
{{< /code >}}
 
##### KubeStateMetricsWatchErrors

{{< code lang="yaml" >}}
alert: KubeStateMetricsWatchErrors
annotations:
  message: kube-state-metrics is experiencing errors at an elevated rate in watch
    operations. This is likely causing it to not be able to expose metrics about Kubernetes
    objects correctly or at all.
expr: |
  (sum(rate(kube_state_metrics_watch_total{job="kube-state-metrics",result="error"}[5m]))
    /
  sum(rate(kube_state_metrics_watch_total{job="kube-state-metrics"}[5m])))
  > 0.01
for: 15m
labels:
  severity: critical
{{< /code >}}
 
