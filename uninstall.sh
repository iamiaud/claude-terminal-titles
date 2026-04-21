#!/usr/bin/env bash
set -euo pipefail

HOOKS_DIR="${HOME}/.claude/hooks"
SETTINGS="${HOME}/.claude/settings.json"
HOOK_SCRIPT="${HOOKS_DIR}/session-title.sh"

# Kill persistence loop if running
[ -f /tmp/claude-title-loop-pid ] && kill "$(cat /tmp/claude-title-loop-pid 2>/dev/null)" 2>/dev/null || true

# Remove hook script and temp files
[ -f "$HOOK_SCRIPT" ] && rm "$HOOK_SCRIPT" && echo "✓ Removed $HOOK_SCRIPT"
rm -f /tmp/claude-title-tty /tmp/claude-title-state /tmp/claude-title-loop-pid

# Remove hook entries from settings.json
if [ -f "$SETTINGS" ]; then
  python3 - <<PYEOF
import json, os

settings_path = os.path.expanduser("${SETTINGS}")
hook_cmd      = os.path.expanduser("${HOOK_SCRIPT}")

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})
for event in list(hooks.keys()):
    hooks[event] = [
        g for g in hooks[event]
        if not any(h.get("command", "").startswith(hook_cmd) for h in g.get("hooks", []))
    ]
    if not hooks[event]:
        del hooks[event]

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print(f"✓ Removed hook entries from {settings_path}")
PYEOF
fi

echo ""
echo "✅ Uninstalled. Restart Claude Code to deactivate."
