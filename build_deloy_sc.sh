#!/bin/bash

set -exv

IMAGE="quay.io/cloudservices/insights-3scale"
IMAGE_TAG=apicast-base-$(git rev-parse --short=7 HEAD)
SECURITY_TAG="apicast-base-security-compliance"

if [[ -z "$QUAY_USER" || -z "$QUAY_TOKEN" ]]; then
    echo "QUAY_USER and QUAY_TOKEN must be set"
    exit 1
fi

DOCKER_CONF="$PWD/.docker"
mkdir -p "$DOCKER_CONF"
docker --config="$DOCKER_CONF" login -u="$QUAY_USER" -p="$QUAY_TOKEN" quay.io
docker --config="$DOCKER_CONF" build --no-cache -t "${IMAGE}:${IMAGE_TAG}" .
docker --config="$DOCKER_CONF" push "${IMAGE}:apicast-base-${IMAGE_TAG}"
docker --config="$DOCKER_CONF" tag "${IMAGE}:${IMAGE_TAG}" "${IMAGE}:${SECURITY_TAG}"
docker --config="$DOCKER_CONF" push "${IMAGE}:${SECURITY_TAG}"
