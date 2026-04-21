#!/usr/bin/env bash
# claude-terminal-titles — interactive configurator
# Run anytime to change emojis and titles: bash configure.sh

CONF="${HOME}/.claude/hooks/session-title.conf"
HOOK="${HOME}/.claude/hooks/session-title.sh"

B='\033[1m' D='\033[2m' R='\033[0m'
CY='\033[36m' YL='\033[33m' GR='\033[32m' BL='\033[34m' RD='\033[31m' MG='\033[35m'

# ── Keys, labels, defaults ─────────────────────────────────────────────────────
KEYS=(
  E_READ     E_EDIT      E_WRITE      E_BASH
  E_SEARCH   E_AGENT     E_TOOL
  T_START    T_END       T_PROMPT     T_DONE
  T_FAILED   T_NOTIF     T_PERM       T_COMPACT
  T_COMPACTED T_SUBAGENT T_SUBAGENT_DONE T_ELICIT
)
LABELS=(
  'Read file'       'Edit file'       'Write file'      'Run command'
  'Search / Glob'   'Spawn agent'     'Other tool'
  'Session start'   'Session end'     'Thinking'        'Done'
  'Failed'          'Notification'    'Permission?'     'Compacting'
  'Compacted'       'Subagent start'  'Subagent done'   'Elicitation'
)
declare -A DEFAULTS=(
  [E_READ]='📄'      [E_EDIT]='✏️ '     [E_WRITE]='💾'     [E_BASH]='$'
  [E_SEARCH]='🔍'    [E_AGENT]='⚙'      [E_TOOL]='🔧'
  [T_START]='▶ Session Start'    [T_END]='💤 Session End'
  [T_PROMPT]='💬 Thinking...'    [T_DONE]='✅ Done'
  [T_FAILED]='❌ Failed'          [T_NOTIF]='🔔 Notification'
  [T_PERM]='⏳ Permission?'       [T_COMPACT]='🗜 Compacting...'
  [T_COMPACTED]='✅ Compacted'   [T_SUBAGENT]='⚙ Subagent...'
  [T_SUBAGENT_DONE]='⚙ Subagent done'   [T_ELICIT]='❓ Elicitation'
)

# ── Load current config ────────────────────────────────────────────────────────
declare -A CFG
for k in "${KEYS[@]}"; do CFG[$k]="${DEFAULTS[$k]}"; done
if [ -f "$CONF" ]; then
  while IFS='=' read -r k v; do
    k="${k//[[:space:]]/}"
    [[ "$k" =~ ^# ]] || [[ -z "$k" ]] && continue
    v="${v#\'}"; v="${v%\'}"   # strip surrounding single quotes
    [[ -v CFG[$k] ]] && CFG[$k]="$v"
  done < "$CONF"
fi

# ── Draw ──────────────────────────────────────────────────────────────────────
draw() {
  clear
  printf "${B}${CY}╔══════════════════════════════════════════════════╗${R}\n"
  printf "${B}${CY}║${R}  ${B}claude-terminal-titles${R}  ·  Configure         ${B}${CY}║${R}\n"
  printf "${B}${CY}╚══════════════════════════════════════════════════╝${R}\n\n"

  printf "  ${D}── Tool labels ─────────────────────────────────────${R}\n"
  for i in 0 1 2 3 4 5 6; do
    printf "  ${YL}%2d${R}  %-22s  %s\n" "$((i+1))" "${LABELS[$i]}" "${CFG[${KEYS[$i]}]}"
  done

  printf "\n  ${D}── Event titles ────────────────────────────────────${R}\n"
  for i in $(seq 7 $((${#KEYS[@]}-1))); do
    printf "  ${YL}%2d${R}  %-22s  %s\n" "$((i+1))" "${LABELS[$i]}" "${CFG[${KEYS[$i]}]}"
  done

  printf "\n  ${GR}[s]${R} Save   ${BL}[r]${R} Reset defaults   ${RD}[q]${R} Quit without saving\n\n"
  printf "  Number to edit, or command: "
}

# ── Edit one item ─────────────────────────────────────────────────────────────
edit_item() {
  local idx=$(( $1 - 1 ))
  local k="${KEYS[$idx]}" label="${LABELS[$idx]}"
  printf "\n  ${B}%s${R}  (current: %s)\n" "$label" "${CFG[$k]}"
  printf "  New value (Enter to keep current): "
  read -r val </dev/tty
  [[ -n "$val" ]] && CFG[$k]="$val"
}

# ── Save ──────────────────────────────────────────────────────────────────────
save() {
  mkdir -p "$(dirname "$CONF")"
  {
    printf '# claude-terminal-titles config\n'
    printf '# Edit here or run: bash configure.sh\n\n'
    for k in "${KEYS[@]}"; do
      printf "%s='%s'\n" "$k" "${CFG[$k]}"
    done
  } > "$CONF"
  # Apply immediately to the installed hook (copy fresh)
  if [ -f "$HOOK" ]; then
    src="$(dirname "${BASH_SOURCE[0]}")/session-title.sh"
    [ -f "$src" ] && cp "$src" "$HOOK"
  fi
  printf "\n  ${GR}✓ Saved to %s${R}\n" "$CONF"
  printf "  ${D}Restart Claude Code to apply changes.${R}\n\n"
}

# ── Main loop ─────────────────────────────────────────────────────────────────
while true; do
  draw
  read -r choice </dev/tty
  case "$choice" in
    [0-9]|[0-9][0-9])
      if (( choice >= 1 && choice <= ${#KEYS[@]} )); then
        edit_item "$choice"
      fi ;;
    s|S) save; printf "  Press Enter to continue..."; read -r _ </dev/tty ;;
    r|R)
      for k in "${KEYS[@]}"; do CFG[$k]="${DEFAULTS[$k]}"; done
      printf "\n  ${BL}✓ Reset to defaults (press [s] to save)${R}\n"
      sleep 1 ;;
    q|Q)
      printf "\n  ${D}Quit — no changes saved.${R}\n\n"
      exit 0 ;;
  esac
done
