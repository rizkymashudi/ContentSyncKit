# ContentSyncKit — Claude Code

Instructions for this repository live in **[`AGENTS.md`](AGENTS.md)**. Read it first.

It is the canonical, tool-agnostic version, and this file exists only so Claude Code finds it.
Nothing project-specific is written here — a second copy of the rules would drift from the first.

Claude Code additionally runs the gates in `.claude/hooks/`, which enforce the credential,
config, and verification rules from `AGENTS.md` automatically. Other tools rely on `make verify`
and CI for the same checks.
