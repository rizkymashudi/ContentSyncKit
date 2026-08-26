#!/usr/bin/env bash
# Blocks irreversible operations that can destroy uncommitted work.
#
# Denylists in settings.json match one spelling of one command; this matches by intent.
# Build artifacts are exempt so ordinary cleanup still works without approval.
source "$(dirname "$0")/_lib.sh"

[ "$(json_get tool_name)" = "Bash" ] || exit 0
CMD="$(json_get tool_input.command)"
[ -z "$CMD" ] && exit 0

RM_RE='(^|[;&|`]|\$\()[[:space:]]*(sudo[[:space:]]+)?rm[[:space:]]+(-[a-zA-Z]*[rRf]|--recursive|--force)'
GIT_RE='git[[:space:]]+(clean[[:space:]]+-[a-zA-Z]*[fdx]|reset[[:space:]]+--hard|checkout[[:space:]]+--[[:space:]]|restore[[:space:]]|push[[:space:]]+.*(--force|-f( |$))|filter-branch|reflog[[:space:]]+delete|branch[[:space:]]+-D)'
MISC_RE='find[[:space:]]+.*-(delete|exec[[:space:]]+rm)|mkfs|dd[[:space:]]+.*of=/dev/|>[[:space:]]*/dev/(sd|disk)'

hit=""
printf '%s' "$CMD" | grep -Eq "$RM_RE"   && hit="recursive or forced delete"
printf '%s' "$CMD" | grep -Eq "$GIT_RE"  && hit="destructive git operation"
printf '%s' "$CMD" | grep -Eq "$MISC_RE" && hit="bulk or device-level deletion"
[ -z "$hit" ] && exit 0

# Exempt: deletes confined to regenerable build output.
if printf '%s' "$CMD" | grep -Eq "$RM_RE" && ! printf '%s' "$CMD" | grep -Eq "$GIT_RE|$MISC_RE"; then
  TARGETS="$(printf '%s' "$CMD" | sed -E 's/.*rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*//')"
  if printf '%s' "$TARGETS" | grep -Eq '^[[:space:]]*("?)(\./)?(\.build|build|DerivedData|\.swiftpm|/tmp/|/private/tmp/)' \
     && ! printf '%s' "$TARGETS" | grep -Eq '(^|[[:space:]])(/|~|\*|\$HOME)([[:space:]]|$)'; then
    exit 0
  fi
fi

block "BLOCKED — $hit.

  $CMD

Nothing in this repository is worth an irreversible command. This work is committed;
destroying it loses more than it saves.

Instead:
  - to clear build output:      make clean
  - to discard your own edits:  show the user 'git diff' and let them decide
  - to remove a file you added: git rm <path>, which is reviewable and revertible

If this operation is genuinely required, explain what it removes and why, and let the
user run it."
