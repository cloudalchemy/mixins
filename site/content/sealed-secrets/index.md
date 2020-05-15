---
title: sealed-secrets
---



Mixin available at [github.com/bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets/tree/master/contrib/prometheus-mixin)

# Alerts

[embedmd]:# (../../../manifests/sealed-secrets/alerts.yaml yaml)
```yaml
groups:
- name: sealed-secrets
  rules:
  - alert: SealedSecretsUnsealErrorRateHigh
    annotations:
      message: High rate of errors unsealing Sealed Secrets
      runbook: https://github.com/bitnami-labs/sealed-secrets
    expr: |
      sum(rate(sealed_secrets_controller_unseal_errors_total{}[5m])) > 0
    labels:
      severity: warning
```

# Dashboards
Following dashboards are generated from mixins and hosted on github:


- [sealed-secrets-controller](https://github.com/cloudalchemy/mixins/blob/master/manifests/sealed-secrets/dashboards/sealed-secrets-controller.json)
