#!/bin/bash
set -e

# Update OS
dnf update -y

# Create a user
useradd --no-create-home --shell /bin/false otel

# Download OpenTelemetry Collector (contrib build for exporters/receivers)
OTEL_VERSION="0.79.0"
cd /opt
curl -LO https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_linux_amd64
chmod +x otelcol-contrib_linux_amd64
mv otelcol-contrib_linux_amd64 otelcol

# Create config directory
mkdir -p /etc/otel
chmod 755 /etc/otel

# Write config
cat <<EOF >/etc/otel/collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  batch:

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  logging:
    loglevel: debug

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus, logging]
EOF

# Permissions
chown -R otel: /etc/otel
chown otel: /opt/otelcol

# Create systemd service
cat <<EOF >/etc/systemd/system/otel-collector.service
[Unit]
Description=OpenTelemetry Collector
Wants=network-online.target
After=network-online.target

[Service]
User=otel
ExecStart=/opt/otelcol --config /etc/otel/collector-config.yaml
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# Enable & start
systemctl daemon-reload
systemctl enable otel-collector
systemctl start otel-collector
