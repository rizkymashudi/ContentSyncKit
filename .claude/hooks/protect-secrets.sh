#!/usr/bin/env bash
# Blocks any attempt to read credential/config files, including via shell pipelines.
# Forward-looking: none of these exist in the repo yet. Update as real ones land.
source "$(dirname "$0")/_lib.sh"

# Regex alternation, not globs — must also catch paths embedded in shell commands.
SECRET_PATTERNS='\.env|\.xcconfig|GoogleService-Info\.plist|secrets?\.(json|plist|ya?ml)|\.p8|\.p12|\.mobileprovision|\.pem|id_rsa'

TOOL="$(json_get tool_name)"
case "$TOOL" in
  Read|Grep|Glob) TARGET="$(json_get tool_input.file_path)$(json_get tool_input.path)$(json_get tool_input.pattern)" ;;
  Bash)           TARGET="$(json_get tool_input.command)" ;;
  *)              exit 0 ;;
esac

if printf '%s' "$TARGET" | grep -Eq "$SECRET_PATTERNS"; then
  block "BLOCKED — credential/config path.

These paths are off limits for read, search, print, quote, or summary:
  - `.env`, `.env.*`
  - `*.xcconfig`
  - `**/GoogleService-Info.plist`
  - `secrets.{json,plist,yml,yaml}`
  - signing material: `*.p8`, `*.p12`, `*.mobileprovision`, `*.pem`, `id_rsa*`

Naming the path when explaining project structure is fine. If this task needs a value
from one of them, ask the user for a safe redacted excerpt instead."
fi
exit 0
