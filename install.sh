#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${HOME}/.claude/hooks"
SETTINGS="${HOME}/.claude/settings.json"

# Copy hook script
mkdir -p "$HOOKS_DIR"
cp "$SCRIPT_DIR/session-title.sh" "$HOOKS_DIR/session-title.sh"
chmod +x "$HOOKS_DIR/session-title.sh"
echo "✓ Copied session-title.sh → $HOOKS_DIR/"

# Register hook for every Claude Code event
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
            print("✗ ~/.claude/settings.json is invalid JSON — fix it first", file=sys.stderr)
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
    print(f"✓ Registered {added} hook entries in {settings_path}")
else:
    print("✓ Hooks already registered — nothing changed")
PYEOF

echo ""
echo "✅ Done! Restart Claude Code to activate."
