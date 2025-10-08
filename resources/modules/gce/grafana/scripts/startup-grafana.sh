#!/bin/bash
set -e

# Update OS
dnf update -y
dnf install wget -y

tee /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=Grafana OSS
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF

dnf install -y grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server

wget -nv https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.136.0/otelcol-contrib_0.136.0_linux_amd64.rpm
rpm -ivh otelcol-contrib_0.136.0_linux_amd64.rpm

cat > /etc/otelcol/config-contrib.yaml <<EOF
receivers:
  prometheus:
    config:
      scrape_configs:
      - job_name: 'otel-collector'
        scrape_interval: 10s
        static_configs:
          - targets: ['0.0.0.0:8888']
      - job_name: 'grafana'
        static_configs:
          - targets: ['localhost:3000']

exporters:
  otlphttp:
    endpoint: "http://otel-collector.natwestmarkets.internal:4318"
    tls:
      insecure: true

processors:
  batch:

service:
  pipelines:
    metrics:
      receivers: [prometheus]
      processors: [batch]
      exporters: [otlphttp]

EOF

service otelcol-contrib restart