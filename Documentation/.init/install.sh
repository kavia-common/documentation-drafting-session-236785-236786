#!/usr/bin/env bash
set -euo pipefail
# Environment setup and verification for mkdocs (idempotent)
WORKSPACE="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-drafting-session-236785-236786/Documentation}"
mkdir -p "$WORKSPACE"
command -v python3 >/dev/null || { echo "python3 not found" >&2; exit 2; }
python3 -m pip --version >/dev/null || { echo "pip for python3 not available" >&2; exit 3; }
command -v git >/dev/null || { echo "git not found" >&2; exit 4; }
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  echo "neither curl nor wget present" >&2; exit 5
fi
# optional pytest check (non-fatal)
if command -v pytest >/dev/null 2>&1; then
  : # pytest available
else
  echo "pytest not present (optional)" >/dev/null
fi
MIN_MKDOCS="1.5.0"
# determine mkdocs CLI version (if any)
MK_CLI_VER=0
if command -v mkdocs >/dev/null 2>&1; then
  MK_CLI_VER=$(mkdocs --version 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\./){print $i; exit}}' || true)
fi
# determine importable mkdocs version (fallback)
MK_PY_VER=0
MK_PY_VER=$(python3 - <<'PY'
import sys
try:
    import mkdocs
    print(getattr(mkdocs,'__version__','0'))
except Exception:
    print('0')
PY
)
# ensure packaging is available for version comparisons
if ! python3 -c "from packaging import version" >/dev/null 2>&1; then
  sudo -H python3 -m pip install --disable-pip-version-check --no-input --quiet packaging || { echo 'failed to install packaging' >&2; exit 6; }
fi
is_old(){ python3 - <<PY
from packaging import version
import sys
v=sys.argv[1]
minv=sys.argv[2]
try:
    print(int(version.parse(v) < version.parse(minv)))
except Exception:
    print(1)
PY
"$1" "$2"
}
NEED_INSTALL=0
if [ "$MK_CLI_VER" = "0" ]; then
  if [ "$(is_old "$MK_PY_VER" "$MIN_MKDOCS")" -eq 1 ]; then
    NEED_INSTALL=1
  fi
else
  if [ "$(is_old "$MK_CLI_VER" "$MIN_MKDOCS")" -eq 1 ]; then
    NEED_INSTALL=1
  fi
fi
if [ $NEED_INSTALL -eq 1 ]; then
  echo "Installing/upgrading mkdocs (required >= $MIN_MKDOCS)" >&2
  sudo -H python3 -m pip install --disable-pip-version-check --no-input --upgrade "mkdocs>=$MIN_MKDOCS,<3" || { echo 'mkdocs install failed' >&2; exit 7; }
else
  echo "mkdocs ok: cli=$MK_CLI_VER py=$MK_PY_VER" >/dev/null
fi
# Optional mkdocs-material install when requested and compatible
if [ "${MKDOCS_MATERIAL:-0}" = "1" ]; then
  rc=0
  python3 - <<'PY' || rc=$?; if [ ${rc:-0} -ne 0 ]; then true; fi
from packaging import version
import sys
try:
    import mkdocs
    mv=version.parse(getattr(mkdocs,'__version__','0'))
except Exception:
    sys.exit(2)
if mv < version.parse('1.0'):
    sys.exit(3)
sys.exit(0)
PY
  if [ ${rc:-0} -eq 0 ]; then
    sudo -H python3 -m pip install --disable-pip-version-check --no-input --upgrade mkdocs-material || echo 'mkdocs-material install failed' >&2
  else
    echo 'mkdocs-material incompatible; skipping' >&2
  fi
fi
# Create idempotent /etc/profile.d script that computes user base at login
PROFILE_FILE=/etc/profile.d/mkdocs_env.sh
if [ -d /etc/profile.d ]; then
  if ! sudo test -f "$PROFILE_FILE" || ! sudo grep -q "# mkdocs environment - generated" "$PROFILE_FILE" 2>/dev/null; then
    sudo tee "$PROFILE_FILE" >/dev/null <<'SH'
# mkdocs environment - generated
# At login compute user base and add its bin to PATH if present
if command -v python3 >/dev/null 2>&1; then
  USER_BASE=$(python3 -m site --user-base 2>/dev/null || echo "")
  if [ -n "$USER_BASE" ] && [ -d "$USER_BASE/bin" ]; then
    case ":$PATH:" in
      *":$USER_BASE/bin:") :;;
      *) export PATH="$USER_BASE/bin:$PATH";;
    esac
  fi
fi
SH
    sudo chmod 644 "$PROFILE_FILE"
  fi
fi
# Final verification: ensure mkdocs CLI available on PATH (fail if not)
if ! command -v mkdocs >/dev/null 2>&1; then
  echo 'mkdocs CLI not available on PATH' >&2; exit 8
fi
exit 0
