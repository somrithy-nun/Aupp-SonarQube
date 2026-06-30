#!/usr/bin/env sh
set -eu

APP_IMAGE="${APP_IMAGE:-aupp-sonarqube-app:latest}"
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:latest}"
REPORT_FILE="${REPORT_FILE:-trivy-image-report.txt}"
TRIVY_CONTAINER="${TRIVY_CONTAINER:-trivy-image-scan-$$}"

cleanup() {
  docker rm -f "$TRIVY_CONTAINER" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "Task 13 - Trivy Docker image scan"
echo "Scanning image: $APP_IMAGE"

docker image inspect "$APP_IMAGE" >/dev/null

docker create \
  --name "$TRIVY_CONTAINER" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  "$TRIVY_IMAGE" image \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    --exit-code 1 \
    --format table \
    --output "/tmp/$REPORT_FILE" \
    "$APP_IMAGE" >/dev/null

set +e
docker start -a "$TRIVY_CONTAINER"
TRIVY_EXIT_CODE=$?
set -e

if ! docker cp "$TRIVY_CONTAINER:/tmp/$REPORT_FILE" "$REPORT_FILE" >/dev/null 2>&1; then
  echo "Trivy did not create $REPORT_FILE. Check the scan output above."
  : > "$REPORT_FILE"
fi

echo "----- Trivy image scan report -----"
cat "$REPORT_FILE"
echo "-----------------------------------"

exit "$TRIVY_EXIT_CODE"
