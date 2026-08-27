#!/usr/bin/env bash
# Blocks edits to linter/formatter/build configs. Agents weaken these to make checks pass.
source "$(dirname "$0")/_lib.sh"

PROTECTED='\.swiftlint\.yml|\.swiftformat|\.swift-format|Package\.resolved|Package\.swift|project\.pbxproj|\.xcscheme|Makefile|\.github/workflows/|\.claude/settings\.json|\.claude/hooks/'

TOOL="$(json_get tool_name)"
case "$TOOL" in
  Edit|Write|MultiEdit)
    FILE="$(json_get tool_input.file_path)" ;;
  Bash)
    CMD="$(json_get tool_input.command)"
    # Inspect only what the command actually writes to. Matching the whole
    # command string blocks merely *mentioning* a protected path — in a heredoc
    # body, a grep argument, or even a 2>&1 redirect.
    FILE="$(printf '%s' "$CMD" \
      | grep -oE '(>>?|[[:space:]]tee[[:space:]]+(-a[[:space:]]+)?)[[:space:]]*[^|;&<>[:space:]]+' \
      | sed -E 's/^([[:space:]]*>>?|[[:space:]]*tee[[:space:]]+(-a[[:space:]]+)?)[[:space:]]*//')"
    # sed -i, cp, and mv write to the last argument of their segment.
    if printf '%s' "$CMD" | grep -Eq '(^|[;&|[:space:]])(sed[[:space:]]+-i|cp|mv)[[:space:]]'; then
      FILE="$FILE
$(printf '%s' "$CMD" | tr '|;&' '\n' | awk 'NF{print $NF}')"
    fi ;;
esac
[ -z "$FILE" ] && exit 0

if printf '%s' "$FILE" | grep -Eq "$PROTECTED"; then
  block "BLOCKED — protected config: $FILE

This file is part of the build or verification system. Fix the code so the existing
rules pass — do not relax the rule set, and do not edit the gate that checks you.

If the change is genuinely needed (a new platform, a new target, a new CI step), say so
and let the user make it."
fi
exit 0
