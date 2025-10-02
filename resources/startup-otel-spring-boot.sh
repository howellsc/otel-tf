#!/bin/bash

apt-get update
apt-get install -y docker.io curl tar

systemctl start docker

# A name for the container and image
CONTAINER_NAME="spring-boot-otel"
IMAGE="europe-north1-docker.pkg.dev/ritm4225265/spring/otel-spring-boot"

# Set home directory to save docker credentials
export HOME=/home/appuser
mkdir -p $HOME

# Configure docker with credentials for gcr.io and pkg.dev
VERSION=2.1.29
OS=linux  # or "darwin" for OSX, "windows" for Windows.
ARCH=amd64  # or "386" for 32-bit OSs

curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${VERSION}/docker-credential-gcr_${OS}_${ARCH}-${VERSION}.tar.gz" \
| tar xz docker-credential-gcr \
&& chmod +x docker-credential-gcr && sudo mv docker-credential-gcr /usr/bin/

docker-credential-gcr configure-docker

# Stop and remove the container if it exists
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# Pull the latest version of the container image
docker pull $IMAGE

# Run docker container
docker run -d --network=host --name $CONTAINER_NAME -p 5000:5000 $IMAGE
