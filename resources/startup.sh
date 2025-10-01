#!/bin/bash
set -e

# Update OS
dnf update -y

yum update
yum -y install wget
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.136.0/otelcol_0.136.0_linux_amd64.rpm
rpm -ivh otelcol_0.136.0_linux_amd64.rpm