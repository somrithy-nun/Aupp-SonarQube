#!/usr/bin/env sh
set -eu

APP_IMAGE="${APP_IMAGE:-aupp-sonarqube-app:task9}"
APP_CONTAINER="${APP_CONTAINER:-aupp-sonarqube-app-task9}"
MONGO_CONTAINER="${MONGO_CONTAINER:-aupp-sonarqube-mongo-task9}"
NETWORK_NAME="${NETWORK_NAME:-aupp-sonarqube-task9}"
HOST_PORT="${HOST_PORT:-3000}"

cleanup() {
  docker rm -f "$APP_CONTAINER" "$MONGO_CONTAINER" >/dev/null 2>&1 || true
  docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "Task 9 - Manually build and check if the app is working"
echo "Building Docker image: $APP_IMAGE"
docker build -t "$APP_IMAGE" .

echo "Starting MongoDB and app containers"
docker network create "$NETWORK_NAME" >/dev/null
docker run -d --name "$MONGO_CONTAINER" --network "$NETWORK_NAME" mongo:7 >/dev/null
docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e PORT=3000 \
  -e MONGO_URI="mongodb://$MONGO_CONTAINER:27017/node_crud" \
  -p "$HOST_PORT:3000" \
  "$APP_IMAGE" >/dev/null

echo "Waiting for the app health check"
for i in $(seq 1 30); do
  if curl -fsS "http://localhost:$HOST_PORT/healthz"; then
    echo
    echo "App is working on http://localhost:$HOST_PORT"
    docker ps --filter "name=$APP_CONTAINER" --filter "name=$MONGO_CONTAINER"
    exit 0
  fi
  sleep 2
done

echo "App did not become healthy. Logs:"
docker logs "$APP_CONTAINER" || true
exit 1
