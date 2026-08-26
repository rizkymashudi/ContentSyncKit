#!/usr/bin/env bash
# The highest-value gate: source files were edited this session but no build/test ever ran.
# Blocks once per session, then gets out of the way (never loops).
source "$(dirname "$0")/_lib.sh"

[ "$(json_get stop_hook_active)" = "true" ] && exit 0

EDITED="$STATE_DIR/edited-$SESSION_ID.txt"
VERIFIED="$STATE_DIR/verified-$SESSION_ID"
NAGGED="$STATE_DIR/nagged-$SESSION_ID"

[ -f "$EDITED" ]   || exit 0   # nothing was edited
[ -f "$VERIFIED" ] && exit 0   # verification already ran
[ -f "$NAGGED" ]   && exit 0   # already asked once this session

touch "$NAGGED"
COUNT="$(sort -u "$EDITED" | wc -l | tr -d ' ')"
block "$COUNT file(s) were edited this session and no verification command has run.

Run one of these and report the actual output before calling the work done:
  swift build && swift test
  xcodebuild test -scheme ContentKitExample -destination 'platform=iOS Simulator,name=iPhone 16'

If verification is genuinely not possible here (no simulator, no toolchain, environment
missing), say so explicitly and state what remains unverified."
