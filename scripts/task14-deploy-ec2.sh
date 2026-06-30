#!/usr/bin/env sh
set -eu

APP_IMAGE="${APP_IMAGE:-aupp-sonarqube-app:latest}"
APP_CONTAINER="${APP_CONTAINER:-aupp-sonarqube-app}"
MONGO_CONTAINER="${MONGO_CONTAINER:-aupp-sonarqube-mongo}"
NETWORK_NAME="${NETWORK_NAME:-aupp-sonarqube-net}"
HOST_PORT="${HOST_PORT:-80}"
CONTAINER_PORT="${CONTAINER_PORT:-3000}"
EC2_USER="${EC2_USER:-ubuntu}"

if [ -z "${EC2_HOST:-}" ] || [ -z "${SSH_KEY:-}" ]; then
  echo "Task 14 - Deploy Docker container on EC2"
  echo "Required environment variables:"
  echo "  EC2_HOST=<your-ec2-public-ip-or-dns>"
  echo "  SSH_KEY=<path-to-private-key.pem>"
  echo "Optional:"
  echo "  EC2_USER=ubuntu|ec2-user"
  echo "  APP_IMAGE=$APP_IMAGE"
  echo "  HOST_PORT=$HOST_PORT"
  exit 1
fi

IMAGE_TAR="aupp-sonarqube-app.tar"

echo "Task 14 - Deploy Docker container on EC2"
echo "Building image: $APP_IMAGE"
docker build -t "$APP_IMAGE" .

echo "Saving image to $IMAGE_TAR"
docker save "$APP_IMAGE" -o "$IMAGE_TAR"

echo "Copying image to EC2: $EC2_USER@$EC2_HOST"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$IMAGE_TAR" "$EC2_USER@$EC2_HOST:/tmp/$IMAGE_TAR"

echo "Deploying containers on EC2"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" "
  set -eu
  if ! command -v docker >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y docker.io
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y docker
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y docker
    else
      echo 'No supported package manager found for Docker install.'
      exit 1
    fi
    sudo systemctl enable --now docker
  fi

  sudo docker load -i /tmp/$IMAGE_TAR
  sudo docker network create $NETWORK_NAME >/dev/null 2>&1 || true
  sudo docker rm -f $APP_CONTAINER $MONGO_CONTAINER >/dev/null 2>&1 || true

  sudo docker run -d \
    --name $MONGO_CONTAINER \
    --network $NETWORK_NAME \
    --restart unless-stopped \
    mongo:7

  sudo docker run -d \
    --name $APP_CONTAINER \
    --network $NETWORK_NAME \
    --restart unless-stopped \
    -e PORT=$CONTAINER_PORT \
    -e MONGO_URI=mongodb://$MONGO_CONTAINER:27017/node_crud \
    -p $HOST_PORT:$CONTAINER_PORT \
    $APP_IMAGE

  sudo docker ps --filter name=$APP_CONTAINER --filter name=$MONGO_CONTAINER
"

echo "Deployment finished. Open: http://$EC2_HOST:$HOST_PORT/healthz"
