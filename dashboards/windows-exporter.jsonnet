// Windows Exporter dashboard — placeholder.
// Replace panel definitions once the full JSON dashboard is provided.
local configMap = import 'configmap.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local datasource =
  g.dashboard.variable.datasource.new('datasource', 'prometheus')
  + g.dashboard.variable.datasource.withRegex('VictoriaMetrics');

local instance =
  g.dashboard.variable.query.new('instance')
  + g.dashboard.variable.query.withDatasourceFromVariable(datasource)
  + g.dashboard.variable.query.queryTypes.withLabelValues('instance', 'up{job="windows_exporter"}')
  + g.dashboard.variable.query.withRefresh('time')
  + g.dashboard.variable.query.withSort(1)
  + g.dashboard.variable.query.selectionOptions.withMulti(true)
  + g.dashboard.variable.query.selectionOptions.withIncludeAll(true);

// ── helper: shorthand for a timeSeries panel with common defaults ──
local tsPanel(title, expr, unit='short') =
  g.panel.timeSeries.new(title)
  + g.panel.timeSeries.queryOptions.withDatasource('prometheus', '$datasource')
  + g.panel.timeSeries.queryOptions.withTargets([
    g.query.prometheus.new(
      '$datasource',
      expr,
    )
    + g.query.prometheus.withLegendFormat('{{ instance }}'),
  ])
  + g.panel.timeSeries.standardOptions.withUnit(unit);

local statPanel(title, expr, unit='short') =
  g.panel.stat.new(title)
  + g.panel.stat.queryOptions.withDatasource('prometheus', '$datasource')
  + g.panel.stat.queryOptions.withTargets([
    g.query.prometheus.new(
      '$datasource',
      expr,
    )
    + g.query.prometheus.withLegendFormat('{{ instance }}'),
  ])
  + g.panel.stat.standardOptions.withUnit(unit);

// ── panels ──
local uptimePanel =
  statPanel(
    'Uptime',
    'windows_os_uptime{instance=~"$instance"}',
    's',
  );

local cpuPanel =
  tsPanel(
    'CPU Usage',
    '100 - (avg by (instance) (rate(windows_cpu_time_total{instance=~"$instance", mode="idle"}[5m])) * 100)',
    'percent',
  );

local memoryPanel =
  tsPanel(
    'Memory Usage',
    '100 - ((windows_os_visible_memory_bytes{instance=~"$instance"} - windows_os_physical_memory_free_bytes{instance=~"$instance"}) / windows_os_visible_memory_bytes{instance=~"$instance"} * 100)',
    'percent',
  );

local diskPanel =
  tsPanel(
    'Disk Free Space',
    'windows_logical_disk_free_bytes{instance=~"$instance", volume!~"HarddiskVolume.*"}',
    'bytes',
  );

local networkRecvPanel =
  tsPanel(
    'Network Received',
    'rate(windows_net_bytes_received_total{instance=~"$instance"}[5m])',
    'Bps',
  );

local networkSentPanel =
  tsPanel(
    'Network Sent',
    'rate(windows_net_bytes_sent_total{instance=~"$instance"}[5m])',
    'Bps',
  );

// ── dashboard ──
local dashboard =
  g.dashboard.new('Windows Exporter')
  + g.dashboard.withUid('windows-exporter')
  + g.dashboard.withDescription('Windows host metrics via windows_exporter')
  + g.dashboard.withTags(['windows', 'infrastructure'])
  + g.dashboard.withTimezone('browser')
  + g.dashboard.withRefresh('30s')
  + g.dashboard.time.withFrom('now-1h')
  + g.dashboard.time.withTo('now')
  + g.dashboard.withVariables([datasource, instance])
  + g.dashboard.withPanels(
    g.util.grid.makeGrid([
      g.panel.row.new('Overview'),
      uptimePanel,
      cpuPanel,
      memoryPanel,
      g.panel.row.new('Disk'),
      diskPanel,
      g.panel.row.new('Network'),
      networkRecvPanel,
      networkSentPanel,
    ], panelWidth=12, panelHeight=8)
  );

configMap.new('grafana-dashboard-windows-exporter', dashboard)
