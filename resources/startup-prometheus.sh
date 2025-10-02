#!/bin/bash
set -e

dnf update -y
dnf install wget -y

useradd --no-create-home --shell /bin/false prometheus

mkdir /etc/prometheus # will hold configuration
mkdir /var/lib/prometheus # is where time-series data will be stored
chown prometheus:prometheus /etc/prometheus # & Prometheus owns both.
chown prometheus:prometheus /var/lib/prometheus

mkdir prometheus
cd prometheus
wget -nv https://github.com/prometheus/prometheus/releases/download/v3.6.0/prometheus-3.6.0.linux-amd64.tar.gz
tar -xvf prometheus-*.linux-amd64.tar.gz

cp prometheus-3.6.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-3.6.0.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

#cp prometheus-3.6.0.linux-amd64/prometheus.yml /etc/prometheus/

cat > /etc/prometheus/prometheus.yml <<EOF
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
#  - job_name: 'otel-collector'
#    scrape_interval: 10s
#    static_configs:
#      - targets: ['otel-collector:8889']

  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
       # The label name is added as a label `label_name=<label_value>` to any timeseries scraped from this config.
        labels:
          app: "prometheus"
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.enable-remote-write-receiver

Restart=on-failure
User=prometheus
Group=prometheus

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus