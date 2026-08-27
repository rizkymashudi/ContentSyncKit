#!/usr/bin/env bash
# Runs the linter/formatter on the file just edited, and records the edit for the Stop gate.
# Warn-only by default. Set HARNESS_STRICT=1 to make lint failures block.
source "$(dirname "$0")/_lib.sh"

FILE="$(json_get tool_input.file_path)"
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

printf '%s\n' "$FILE" >> "$STATE_DIR/edited-$SESSION_ID.txt"

# Only lint source files this project owns.
case "$FILE" in
  */Pods/*|*/node_modules/*|*/build/*|*/.build/*|*/vendor/*) exit 0 ;;
esac

# SwiftLint only understands Swift. Everything else is out of scope for this gate.
case "$FILE" in
  *.swift) ;;
  *) exit 0 ;;
esac
command -v swiftlint >/dev/null 2>&1 || exit 0

OUT="$(swiftlint lint --quiet "$FILE" 2>&1)" && exit 0

if [ "${HARNESS_STRICT:-0}" = "1" ]; then
  block "Lint failed on $FILE:

$OUT"
fi
warn "Lint warnings on $FILE (not blocking):

$OUT"
