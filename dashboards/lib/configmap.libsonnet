// configmap.libsonnet — wraps a Grafana dashboard object in a
// Kubernetes ConfigMap with the sidecar label grafana_dashboard.
{
  new(name, dashboard):: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: name,
      namespace: 'monitoring',
      labels: {
        grafana_dashboard: '1',
      },
    },
    data: {
      [name + '.json']: std.manifestJsonEx(dashboard, '  '),
    },
  },
}
