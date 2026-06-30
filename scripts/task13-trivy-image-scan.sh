#!/usr/bin/env sh
set -eu

APP_IMAGE="${APP_IMAGE:-aupp-sonarqube-app:latest}"
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:latest}"
REPORT_FILE="${REPORT_FILE:-trivy-image-report.txt}"

echo "Task 13 - Trivy Docker image scan"
echo "Scanning image: $APP_IMAGE"

set +e
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd):/workspace" \
  "$TRIVY_IMAGE" image \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    --exit-code 1 \
    --format table \
    --output "/workspace/$REPORT_FILE" \
    "$APP_IMAGE"
TRIVY_EXIT_CODE=$?
set -e

echo "----- Trivy image scan report -----"
cat "$REPORT_FILE"
echo "-----------------------------------"

exit "$TRIVY_EXIT_CODE"
