#!/usr/bin/env sh
set -eu

TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:latest}"
REPORT_FILE="${REPORT_FILE:-trivy-code-report.txt}"

echo "Task 11 - Trivy code/filesystem scan"
echo "Scanning current project directory"

set +e
docker run --rm \
  -v "$(pwd):/workspace:ro" \
  -v "$(pwd):/reports" \
  "$TRIVY_IMAGE" fs \
    --scanners vuln,secret,misconfig \
    --severity HIGH,CRITICAL \
    --ignore-unfixed \
    --exit-code 1 \
    --skip-dirs /workspace/node_modules \
    --format table \
    --output "/reports/$REPORT_FILE" \
    /workspace
TRIVY_EXIT_CODE=$?
set -e

echo "----- Trivy code scan report -----"
cat "$REPORT_FILE"
echo "----------------------------------"

exit "$TRIVY_EXIT_CODE"
