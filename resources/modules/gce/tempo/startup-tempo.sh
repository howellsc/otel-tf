#!/bin/bash
set -e

dnf update -y

curl -Lo tempo_2.8.2_linux_amd64.rpm https://github.com/grafana/tempo/releases/download/v2.8.2/tempo_2.8.2_linux_amd64.rpm

dnf install tempo_2.8.2_linux_amd64.rpm -y

cat > /etc/tempo/config.yml <<EOF
server:
  http_listen_port: 3100

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"
        http:
          endpoint: "0.0.0.0:4318"

compactor:
  compaction:
    block_retention: 48h                # configure total trace retention here

metrics_generator:
  registry:
    external_labels:
      source: tempo
      cluster: linux-microservices
  storage:
    path: /var/tempo/generator/wal
    remote_write:
    - url: http://prometheus:9090/api/v1/write
      send_exemplars: true

storage:
  trace:
    backend: local
    local:
      path: /var/lib/tempo/traces
    wal:
      path: /var/lib/tempo/wal

overrides:
  defaults:
    metrics_generator:
      processors: [service-graphs, span-metrics,local-blocks]
EOF

mkdir -p /var/lib/tempo/{traces,wal}
chown -R tempo:tempo /var/lib/tempo

service tempo restart

wget -nv https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.136.0/otelcol_0.136.0_linux_amd64.rpm
rpm -ivh otelcol_0.136.0_linux_amd64.rpm

cat > /etc/otelcol/config.yaml <<EOF
receivers:
  prometheus:
    config:
      scrape_configs:
      - job_name: 'otel-collector'
          scrape_interval: 10s
          static_configs:
            - targets: ['0.0.0.0:8888']
        - job_name: 'tempo'
          static_configs:
            - targets: ['localhost:3100']
          metrics_path: /metrics

exporters:
  otlp:
    endpoint: otel-collector.natwestmarkets.internal
    tls:
      insecure: true

processors:
  batch:

service:
  pipelines:
    metrics:
      receivers: [prometheus]
      processors: [batch]
      exporters: [otlp]

EOF

service otelcol restart