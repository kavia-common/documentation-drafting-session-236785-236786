#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-drafting-session-236785-236786/Documentation}"
cd "$WORKSPACE"
# Basic checks
[ -f mkdocs.yml ] || { echo 'mkdocs.yml missing' >&2; exit 20; }
[ -d docs ] || { echo 'docs/ missing' >&2; exit 21; }
[ -f docs/index.md ] || { echo 'docs/index.md missing' >&2; exit 22; }
# Build to verify successful site generation
mkdocs build --clean >/dev/null || { echo 'build failed' >&2; exit 23; }
[ -f site/index.html ] || { echo 'site/index.html missing after build' >&2; exit 24; }
