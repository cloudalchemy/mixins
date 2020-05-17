---
title: sealed-secrets
---



{{< panel style="primary" title="Jsonnet source" >}}
Mixin jsonnet code is available at [github.com/bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets/tree/master/contrib/prometheus-mixin)
{{< /panel >}}

## Alerts

{{< panel style="info" >}}
Complete list of pregenerated alerts is available [here](https://github.com/cloudalchemy/mixins/blob/master/manifests/sealed-secrets/alerts.yaml).
{{< /panel >}}

### SealedSecretsUnsealErrorRateHigh

{{< code lang="yaml" >}}
alert: SealedSecretsUnsealErrorRateHigh
annotations:
  message: High rate of errors unsealing Sealed Secrets
  runbook: https://github.com/bitnami-labs/sealed-secrets
expr: |
  sum(rate(sealed_secrets_controller_unseal_errors_total{}[5m])) > 0
labels:
  severity: warning
{{< /code >}}
 
## Dashboards
Following dashboards are generated from mixins and hosted on github:


- [sealed-secrets-controller](https://github.com/cloudalchemy/mixins/blob/master/manifests/sealed-secrets/dashboards/sealed-secrets-controller.json)
