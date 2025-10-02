#!/bin/bash
set -e

# Update OS
dnf update -y

yum -y install podman

# A name for the container and image
CONTAINER_NAME="spring-boot-otel"
REGISTRY="europe-north1-docker.pkg.dev"
IMAGE="ritm4225265/spring/otel-spring-boot"

# Get access token from gcloud
TOKEN=$(gcloud auth print-access-token)

podman login -u oauth2accesstoken -p "$TOKEN" https://$REGISTRY

# Stop and remove the container if it exists
podman stop $CONTAINER_NAME || true
podman rm $CONTAINER_NAME || true

# Pull the latest version of the container image
podman pull $REGISTRY/$IMAGE

# Run docker container
podman run -d --network=host --name $CONTAINER_NAME -p 5000:5000 $IMAGE
