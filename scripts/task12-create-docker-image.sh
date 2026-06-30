#!/usr/bin/env sh
set -eu

APP_IMAGE="${APP_IMAGE:-aupp-sonarqube-app:latest}"

echo "Task 12 - Create Docker image"
echo "Building image: $APP_IMAGE"
docker build -t "$APP_IMAGE" .

echo "Docker image created:"
docker image ls "$APP_IMAGE"
