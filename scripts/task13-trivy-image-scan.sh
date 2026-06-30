#!/usr/bin/env sh
set -eu

APP_IMAGE="${APP_IMAGE:-aupp-sonarqube-app:latest}"
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:latest}"
REPORT_FILE="${REPORT_FILE:-trivy-image-report.txt}"
TRIVY_CONTAINER="${TRIVY_CONTAINER:-trivy-image-scan-$$}"
FAIL_ON_FINDINGS="${FAIL_ON_FINDINGS:-false}"

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

REPORT_CREATED=true
if ! docker cp "$TRIVY_CONTAINER:/tmp/$REPORT_FILE" "$REPORT_FILE" >/dev/null 2>&1; then
  echo "Trivy did not create $REPORT_FILE. Check the scan output above."
  : > "$REPORT_FILE"
  REPORT_CREATED=false
fi

echo "----- Trivy image scan report -----"
cat "$REPORT_FILE"
echo "-----------------------------------"

if [ "$TRIVY_EXIT_CODE" -eq 0 ]; then
  echo "Trivy image scan completed without HIGH/CRITICAL findings."
  exit 0
fi

if [ "$REPORT_CREATED" != "true" ]; then
  echo "Trivy image scan failed before creating a report."
  exit "$TRIVY_EXIT_CODE"
fi

if [ "$FAIL_ON_FINDINGS" = "true" ]; then
  echo "Trivy image scan found HIGH/CRITICAL findings. Failing because FAIL_ON_FINDINGS=true."
  exit "$TRIVY_EXIT_CODE"
fi

echo "Trivy image scan found HIGH/CRITICAL findings. Continuing so Jenkins can finish and archive screenshots/reports."
echo "Set FAIL_ON_FINDINGS=true to fail the pipeline on these findings."
exit 0
