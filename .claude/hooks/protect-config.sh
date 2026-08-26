#!/usr/bin/env bash
# Blocks edits to linter/formatter/build configs. Agents weaken these to make checks pass.
source "$(dirname "$0")/_lib.sh"

PROTECTED='\.swiftlint\.yml|\.swiftformat|\.swift-format|Package\.resolved|Package\.swift|project\.pbxproj|\.xcscheme|Makefile|\.github/workflows/|\.claude/settings\.json|\.claude/hooks/'

TOOL="$(json_get tool_name)"
case "$TOOL" in
  Edit|Write|MultiEdit)
    FILE="$(json_get tool_input.file_path)" ;;
  Bash)
    # A shell redirect, sed -i, or tee reaches the same file without the Edit tool.
    CMD="$(json_get tool_input.command)"
    if printf '%s' "$CMD" | grep -Eq '(>>?|tee|sed[[:space:]]+-i|cp[[:space:]]|mv[[:space:]])'; then
      FILE="$CMD"
    else
      FILE=""
    fi ;;
  *) FILE="" ;;
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
