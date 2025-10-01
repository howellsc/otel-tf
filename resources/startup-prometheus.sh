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
wget https://github.com/prometheus/prometheus/releases/download/v3.6.0/prometheus-3.6.0.linux-amd64.tar.gz
tar -xvf prometheus-*.linux-amd64.tar.gz

cp prometheus-3.6.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-3.6.0.linux-amd64/promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

cp prometheus-3.6.0.linux-amd64/prometheus.yml /etc/prometheus/
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
  --storage.tsdb.path /var/lib/prometheus/
Restart=on-failure
User=prometheus
Group=prometheus

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus