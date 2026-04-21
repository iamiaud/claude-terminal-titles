#!/usr/bin/env bash
# claude-terminal-titles — live terminal tab titles for Claude Code
# Each hook event updates the tab title with what Claude is currently doing.

EVENT="${1:-unknown}"
STDIN=$(cat)

TTY_CACHE="/tmp/claude-title-tty"
STATE_FILE="/tmp/claude-title-state"
LOOP_PID="/tmp/claude-title-loop-pid"

# Kill previous persistence loop
[ -f "$LOOP_PID" ] && kill "$(cat "$LOOP_PID" 2>/dev/null)" 2>/dev/null; true

# Parse tool name + context label from JSON stdin in a single Python call.
# Tempfile avoids the pipe+heredoc stdin conflict.
_py=$(mktemp /tmp/ct.XXXXXX.py)
cat > "$_py" << 'PYEOF'
import sys, json
d    = json.load(sys.stdin)
tool = d.get('tool_name', '')
inp  = d.get('tool_input', {})
ctx  = ''
if tool in ('Read', 'Edit', 'Write'):
    p   = inp.get('file_path', '')
    ctx = p.split('/')[-1][:32] if p else ''
elif tool == 'Bash':
    parts = inp.get('command', '').strip().split('\n')[0].split()
    label = parts[0].split('/')[-1] if parts else ''
    bad   = set('|&;<>$"' + "'" + r'\(){}')
    for p in parts[1:]:
        if p and not p.startswith('-') and not (set(p) & bad):
            label += ' ' + p[:20]
            break
    ctx = label[:32]
elif tool in ('Grep', 'Glob'):
    ctx = inp.get('pattern', '')[:32]
elif tool == 'Agent':
    ctx = inp.get('description', '')[:32]
print(tool + '\t' + ctx)
PYEOF
IFS=$'\t' read -r TOOL CTX < <(printf '%s' "$STDIN" | python3 "$_py" 2>/dev/null || printf '\t')
rm -f "$_py"

tool_label() {
  case "$1" in
    Read)       echo "📄 ${2:-read}" ;;
    Edit)       echo "✏️  ${2:-edit}" ;;
    Write)      echo "💾 ${2:-write}" ;;
    Bash)       echo "$ ${2:-bash}" ;;
    Grep|Glob)  echo "🔍 ${2:-search}" ;;
    Agent)      echo "⚙ ${2:-agent}" ;;
    *)          echo "🔧 ${1:-tool}" ;;
  esac
}

case "$EVENT" in
  SessionStart)       TITLE="▶ Session Start" ;;
  SessionEnd)         TITLE="💤 Session End" ;;
  UserPromptSubmit)   TITLE="💬 Thinking..." ;;
  Stop)               TITLE="✅ Done" ;;
  StopFailure)        TITLE="❌ Failed" ;;
  Notification)       TITLE="🔔 Notification" ;;
  PermissionRequest)  TITLE="⏳ Permission?" ;;
  PostToolUseFailure) TITLE="❌ ${TOOL:-tool} failed" ;;
  PreCompact)         TITLE="🗜 Compacting..." ;;
  PostCompact)        TITLE="✅ Compacted" ;;
  SubagentStart)      TITLE="⚙ Subagent..." ;;
  SubagentStop)       TITLE="⚙ Subagent done" ;;
  PreToolUse)         TITLE="$(tool_label "$TOOL" "$CTX")" ;;
  PostToolUse)        TITLE="$(tool_label "$TOOL" "$CTX") ✓" ;;
  Elicitation)        TITLE="❓ Elicitation" ;;
  *)                  TITLE="Claude: $EVENT" ;;
esac

set_title() {
  local t="$1"
  # Direct /dev/tty (sync hooks inherit a TTY)
  if printf '\033]0;%s\007' "$t" > /dev/tty 2>/dev/null; then
    dev=$(tty 2>/dev/null); [[ "$dev" == /dev/* ]] && echo "$dev" > "$TTY_CACHE"
    return
  fi
  # Cached TTY device (async hooks don't inherit /dev/tty)
  if [ -f "$TTY_CACHE" ]; then
    cached=$(< "$TTY_CACHE")
    [[ "$cached" != /dev/* ]] && { rm -f "$TTY_CACHE"; cached=""; }
    [ -n "$cached" ] && printf '\033]0;%s\007' "$t" > "$cached" 2>/dev/null && return
  fi
  # Walk up the process tree as last resort
  local pid=$PPID
  for _ in 1 2 3 4 5; do
    tty_name=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
    if [ -n "$tty_name" ] && [ "$tty_name" != "?" ]; then
      printf '\033]0;%s\007' "$t" > "/dev/$tty_name" 2>/dev/null
      echo "/dev/$tty_name" > "$TTY_CACHE"
      return
    fi
    ppid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
    [ -z "$ppid" ] || [ "$ppid" = "1" ] && break
    pid=$ppid
  done
}

echo "$TITLE" > "$STATE_FILE"
set_title "$TITLE"

# Re-apply every second so the title survives terminal resets (tmux, zsh precmd, etc.)
(
  while [ "$(cat "$STATE_FILE" 2>/dev/null)" = "$TITLE" ]; do
    sleep 1
    [ -f "$TTY_CACHE" ] && printf '\033]0;%s\007' "$TITLE" > "$(cat "$TTY_CACHE")" 2>/dev/null
  done
) &
echo $! > "$LOOP_PID"
