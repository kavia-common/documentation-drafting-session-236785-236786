#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-drafting-session-236785-236786/Documentation}"
cd "$WORKSPACE"
# Build site cleanly
mkdocs build --clean || { echo 'build failed' >&2; exit 12; }
[ -d site ] || { echo 'build failed: site/ missing' >&2; exit 13; }
