#!/usr/bin/env bash
# Shared helpers for ContentSyncKit agent hooks.
# Hook contract: JSON on stdin; exit 0 = allow, exit 2 = block (stderr goes to the agent).

set -uo pipefail

HOOK_INPUT="$(cat)"

# jq_get <jq-style dotted path> — no jq dependency, python3 only.
json_get() {
  printf '%s' "$HOOK_INPUT" | python3 -c '
import json,sys
path=sys.argv[1].split(".")
try: cur=json.load(sys.stdin)
except Exception: sys.exit(0)
for k in path:
    if isinstance(cur,dict) and k in cur: cur=cur[k]
    else: sys.exit(0)
print(cur if isinstance(cur,str) else json.dumps(cur))
' "$1"
}

STATE_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/.state"
SESSION_ID="$(json_get session_id)"
mkdir -p "$STATE_DIR" 2>/dev/null || true

block() { printf '%s\n' "$1" >&2; exit 2; }
warn()  { printf '%s\n' "$1" >&2; exit 0; }
