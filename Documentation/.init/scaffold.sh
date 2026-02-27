#!/usr/bin/env bash
set -euo pipefail
# Idempotent MkDocs scaffolding for authoritative workspace
WORKSPACE="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-drafting-session-236785-236786/Documentation}"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
mkdir -p docs
[ -f docs/index.md ] && [ "${OVERWRITE:-0}" != "1" ] || cat > docs/index.md <<'MD'
# Welcome

This is a minimal MkDocs site for automated testing.
MD
[ -f docs/usage.md ] && [ "${OVERWRITE:-0}" != "1" ] || cat > docs/usage.md <<'MD'
# Usage

- mkdocs build
- mkdocs serve
MD
# Prefer material theme if available as a python import
if python3 -c "import mkdocs_material" >/dev/null 2>&1; then
  [ -f mkdocs.yml ] && [ "${OVERWRITE:-0}" != "1" ] || cat > mkdocs.yml <<'YML'
site_name: Documentation
nav:
  - Home: index.md
  - Usage: usage.md
theme:
  name: material
YML
else
  [ -f mkdocs.yml ] && [ "${OVERWRITE:-0}" != "1" ] || cat > mkdocs.yml <<'YML'
site_name: Documentation
nav:
  - Home: index.md
  - Usage: usage.md
YML
fi
# create start.sh helper (derives WORKSPACE or fails clearly)
cat > start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${WORKSPACE-}"
if [ -z "${WORKSPACE:-}" ]; then
  WORKSPACE=$(cd "$(dirname "$0")/.." >/dev/null 2>&1 && pwd || true)
  if [ -z "$WORKSPACE" ]; then
    echo 'WORKSPACE not set and could not be derived; set WORKSPACE to workspace path' >&2
    exit 2
  fi
fi
cd "$WORKSPACE"
exec mkdocs serve --dev-addr=0.0.0.0:8000
SH
chmod +x start.sh
# create build.sh helper (derives WORKSPACE or fails clearly)
cat > build.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
: "${WORKSPACE-}"
if [ -z "${WORKSPACE:-}" ]; then
  WORKSPACE=$(cd "$(dirname "$0")/.." >/dev/null 2>&1 && pwd || true)
  if [ -z "$WORKSPACE" ]; then
    echo 'WORKSPACE not set and could not be derived; set WORKSPACE to workspace path' >&2
    exit 2
  fi
fi
cd "$WORKSPACE"
mkdocs build --clean
SH
chmod +x build.sh
# Done
