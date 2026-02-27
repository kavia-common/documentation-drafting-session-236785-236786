#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-drafting-session-236785-236786/Documentation}"
cd "$WORKSPACE"
# Derive WORKSPACE from script location if not set
if [ -z "${WORKSPACE:-}" ]; then
  SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  WORKSPACE="$SCRIPT_DIR/.."
fi
cd "$WORKSPACE"
# Start mkdocs serve in foreground (bind 127.0.0.1:8000 by default)
# Use --dev-addr so it binds predictably
exec mkdocs serve --dev-addr 127.0.0.1:8000
