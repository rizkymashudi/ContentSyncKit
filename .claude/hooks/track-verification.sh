#!/usr/bin/env bash
# Records that a real build/test command ran this session, so the Stop gate can tell
# "verified" from "asserted".
source "$(dirname "$0")/_lib.sh"

CMD="$(json_get tool_input.command)"
[ -z "$CMD" ] && exit 0

# Match the project's real verification commands.
VERIFY_PATTERN='make (verify|verify-example|test|build)|swift (build|test)|xcodebuild'

if printf '%s' "$CMD" | grep -Eq "$VERIFY_PATTERN"; then
  date +%s > "$STATE_DIR/verified-$SESSION_ID"
fi
exit 0
