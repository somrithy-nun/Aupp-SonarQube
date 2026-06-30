#!/usr/bin/env sh
set -eu

TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:latest}"
REPORT_FILE="${REPORT_FILE:-trivy-code-report.txt}"
SCAN_DIR="${SCAN_DIR:-.trivy-workspace}"
TRIVY_CONTAINER="${TRIVY_CONTAINER:-trivy-code-scan-$$}"

cleanup() {
  docker rm -f "$TRIVY_CONTAINER" >/dev/null 2>&1 || true
  rm -rf "$SCAN_DIR"
}

trap cleanup EXIT

echo "Task 11 - Trivy code/filesystem scan"
echo "Scanning current project directory"

rm -rf "$SCAN_DIR"
mkdir -p "$SCAN_DIR"

for file in package.json package-lock.json Dockerfile server.js app.js; do
  if [ -f "$file" ]; then
    cp "$file" "$SCAN_DIR/"
  fi
done

if [ -d src ]; then
  cp -R src "$SCAN_DIR/"
fi

echo "Files prepared for Trivy:"
find "$SCAN_DIR" -maxdepth 3 -type f | sort

docker create \
  --name "$TRIVY_CONTAINER" \
  "$TRIVY_IMAGE" fs \
    --scanners vuln,secret,misconfig \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    --exit-code 1 \
    --format table \
    --output "/tmp/$REPORT_FILE" \
    /tmp/workspace >/dev/null

docker cp "$SCAN_DIR/." "$TRIVY_CONTAINER:/tmp/workspace"

set +e
docker start -a "$TRIVY_CONTAINER"
TRIVY_EXIT_CODE=$?
set -e

if ! docker cp "$TRIVY_CONTAINER:/tmp/$REPORT_FILE" "$REPORT_FILE" >/dev/null 2>&1; then
  echo "Trivy did not create $REPORT_FILE. Check the scan output above."
  : > "$REPORT_FILE"
fi

echo "----- Trivy code scan report -----"
cat "$REPORT_FILE"
echo "----------------------------------"

exit "$TRIVY_EXIT_CODE"
