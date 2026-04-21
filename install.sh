#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${HOME}/.claude/hooks"
SETTINGS="${HOME}/.claude/settings.json"

B='\033[1m' D='\033[2m' R='\033[0m'
CY='\033[36m' GR='\033[32m' YL='\033[33m'

printf "\n${B}${CY}  claude-terminal-titles${R} — installer\n\n"

# ── Choose mode ───────────────────────────────────────────────────────────────
printf "  ${YL}[1]${R} Default  — install with standard emoji & labels\n"
printf "  ${YL}[2]${R} Custom   — choose your own emoji and titles\n\n"
printf "  Choice [1]: "
read -r choice
choice="${choice:-1}"

# ── Copy hook script ──────────────────────────────────────────────────────────
mkdir -p "$HOOKS_DIR"
cp "$SCRIPT_DIR/session-title.sh" "$HOOKS_DIR/session-title.sh"
chmod +x "$HOOKS_DIR/session-title.sh"
printf "\n  ${GR}✓${R} Copied session-title.sh → %s/\n" "$HOOKS_DIR"

# ── Register hooks in settings.json ──────────────────────────────────────────
python3 - <<PYEOF
import json, os, sys

settings_path = os.path.expanduser("${SETTINGS}")
hook_cmd      = os.path.expanduser("${HOOKS_DIR}/session-title.sh")

settings = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError:
            print("  ✗ ~/.claude/settings.json is invalid JSON — fix it first", file=sys.stderr)
            sys.exit(1)

hooks = settings.setdefault("hooks", {})
events = [
    "SessionStart", "SessionEnd", "UserPromptSubmit", "Stop", "StopFailure",
    "Notification", "PermissionRequest", "PostToolUseFailure",
    "PreCompact", "PostCompact", "SubagentStart", "SubagentStop",
    "PreToolUse", "PostToolUse", "Elicitation",
]
added = 0
for event in events:
    event_hooks = hooks.setdefault(event, [])
    cmd = f"{hook_cmd} {event}"
    already = any(
        any(h.get("command", "") == cmd for h in g.get("hooks", []))
        for g in event_hooks
    )
    if not already:
        event_hooks.insert(0, {
            "matcher": "",
            "hooks": [{"type": "command", "command": cmd, "timeout": 5, "async": True}],
        })
        added += 1

os.makedirs(os.path.dirname(settings_path), exist_ok=True)
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

if added:
    print(f"  \033[32m✓\033[0m Registered {added} hook entries in {settings_path}")
else:
    print(f"  \033[2m✓ Hooks already registered — nothing changed\033[0m")
PYEOF

# ── Custom config ─────────────────────────────────────────────────────────────
if [[ "$choice" == "2" ]]; then
  printf "\n  ${YL}Opening configurator...${R}\n\n"
  sleep 0.5
  bash "$SCRIPT_DIR/configure.sh"
fi

printf "\n  ${GR}${B}✅ Done!${R} Restart Claude Code to activate.\n"
printf "  ${D}To reconfigure later: bash configure.sh${R}\n\n"
