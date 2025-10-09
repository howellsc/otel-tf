#!/bin/bash
set -e

# Update OS
dnf update -y

dnf install wget -y
wget -nv https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.136.0/otelcol-contrib_0.136.0_linux_amd64.rpm
rpm -ivh otelcol-contrib_0.136.0_linux_amd64.rpm

cat > /etc/otelcol-contrib/config.yaml <<EOF
# To limit exposure to denial of service attacks, change the host in endpoints below from 0.0.0.0 to a specific network interface.
# See https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/security-best-practices.md#safeguards-against-denial-of-service-attacks

extensions:
  health_check:
    endpoint: "0.0.0.0:13133"
  pprof:
    endpoint: 0.0.0.0:1777
  zpages:
    endpoint: 0.0.0.0:55679

receivers:

  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

  # Collect own metrics and Grafana
  prometheus:
    config:
      scrape_configs:
      - job_name: 'otel-collector'
        scrape_interval: 10s
        static_configs:
          - targets: ['0.0.0.0:8888']

#  jaeger:
#    protocols:
#      grpc:
#        endpoint: 0.0.0.0:14250
#      thrift_binary:
#        endpoint: 0.0.0.0:6832
#      thrift_compact:
#        endpoint: 0.0.0.0:6831
#      thrift_http:
#        endpoint: 0.0.0.0:14268
#
#  zipkin:
#    endpoint: 0.0.0.0:9411

processors:
  batch:

  resource:
    resourcedetection:
      detectors: [gce]
      timeout: 2s
      override: false
    attributes:
      - key: deployment.environment
        value: "production"
        action: insert
      - key: host.id
        value: "gateway"
        action: insert  # do not override agent's host.id

exporters:
  debug:
    verbosity: detailed

  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: default

  prometheusremotewrite:
    endpoint: http://prometheus:9090/api/v1/write
    resource_to_telemetry_conversion:
      enabled: true

  otlp:
    endpoint: "tempo:4317"  # Tempo OTLP gRPC endpoint
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
      processors: [resource, resourcedetection, batch]
      exporters: [prometheusremotewrite]

    logs:
      receivers: [otlp]
      processors: [resource, batch]
      exporters: [debug]

  extensions: [health_check, pprof, zpages]
EOF

service otelcol-contrib restart