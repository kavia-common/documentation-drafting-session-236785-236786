#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-drafting-session-236785-236786/Documentation}"
cd "$WORKSPACE"
# Build first
mkdocs build --clean || { echo 'build failed' >&2; exit 12; }
[ -d site ] || { echo 'build failed: site/ missing' >&2; exit 13; }
LOG=/tmp/mkdocs_serve.log
: ${VALIDATION_TIMEOUT:=60}
# Determine HTTP_CMD (use curl preferentially)
if command -v curl >/dev/null 2>&1; then
  HTTP_CMD_TYPE=curl
else
  if command -v wget >/dev/null 2>&1; then
    HTTP_CMD_TYPE=wget
  else
    echo 'neither curl nor wget available for validation' >&2; exit 14
  fi
fi
# Start server via start.sh in background process group
./start.sh >"$LOG" 2>&1 &
PID=$!
# get PGID for process group-based termination
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
exit_code=1
cleanup(){
  if kill -0 "$PID" >/dev/null 2>&1; then
    kill -TERM -"$PGID" >/dev/null 2>&1 || true
    sleep 1
    kill -KILL -"$PGID" >/dev/null 2>&1 || true
  fi
}
trap 'cleanup; exit $exit_code' EXIT INT TERM
END=$((SECONDS+VALIDATION_TIMEOUT))
while [ $SECONDS -lt $END ]; do
  if [ "$HTTP_CMD_TYPE" = "curl" ]; then
    BODY=$(curl -sS --max-time 3 -o - -w '%{http_code}' http://127.0.0.1:8000/ 2>/dev/null || true)
    HTTP_CODE=${BODY: -3}
    CONTENT=${BODY%???}
  else
    CONTENT=$(wget -q -O - --timeout=3 http://127.0.0.1:8000/ 2>/dev/null || true)
    # wget doesn't provide status easily here; rely on non-empty content
    if [ -n "${CONTENT}" ]; then
      HTTP_CODE=200
    else
      HTTP_CODE=000
    fi
  fi
  if [ "$HTTP_CODE" = "200" ] && [ -n "${CONTENT:-}" ]; then
    echo "http_response_snippet:"
    echo "$CONTENT" | head -n 10
    exit_code=0
    break
  fi
  sleep 1
done
if [ $exit_code -ne 0 ]; then
  echo 'server did not respond within timeout' >&2
  echo '--- mkdocs serve log (tail) ---'
  tail -n 200 "$LOG" || true
  exit_code=15
fi
# trap will run cleanup and exit with $exit_code
