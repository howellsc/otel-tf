#!/bin/bash
set -e

# Update OS
dnf update -y

dnf install wget -y
wget -nv https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.136.0/otelcol_0.136.0_linux_amd64.rpm
rpm -ivh otelcol_0.136.0_linux_amd64.rpm

cat > /etc/otelcol/config.yaml <<EOF
# To limit exposure to denial of service attacks, change the host in endpoints below from 0.0.0.0 to a specific network interface.
# See https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/security-best-practices.md#safeguards-against-denial-of-service-attacks

extensions:
  health_check:

receivers:

  otlp:
    protocols:
      grpc:
      http:

  # Collect own metrics
  prometheus:
    config:
      scrape_configs:
      - job_name: 'otel-collector'
        scrape_interval: 10s
        static_configs:
          - targets: ['0.0.0.0:8888']

processors:
  batch:

  resource:
    attributes:
      - key: host.zone
        value: "us-central1-a"
        action: upsert
      - key: host.instance_type
        value: "e2-medium"
        action: upsert

exporters:
  debug:
    verbosity: detailed

  otlp:
    endpoint: "otel-collector.natwestmarkets.internal:80"
    tls:
      insecure: true  # Use insecure if Tempo does not use TLS

service:

  pipelines:

    traces:
      receivers: [otlp]
      processors: [resource, batch]
      exporters: [otlp]

    metrics:
      receivers: [otlp, prometheus]
      processors: [resource, batch]
      exporters: [otlp]

    logs:
      receivers: [otlp]
      processors: [resource, batch]
      exporters: [debug]

  extensions: [health_check]
EOF

service otelcol restart