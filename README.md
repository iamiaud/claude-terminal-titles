# claude-terminal-titles

> Live terminal tab titles for [Claude Code](https://claude.ai/code) — see exactly what the agent is doing without switching windows.

Your terminal tab updates in real time as Claude works: reading files, running commands, spawning subagents, waiting for you. Zero config, one install command.

---

## Preview

```
📄 server.ts          ← Claude is reading a file
✏️  routes/auth.ts     ← Claude is editing
$ pytest tests/ ✓     ← just ran a command
🔍 def handle_        ← searching the codebase
⚙ Subagent...         ← spawned a background agent
✅ Done               ← waiting for your next message
💬 Thinking...        ← processing your prompt
⏳ Permission?        ← needs your approval
```

Works with any terminal emulator that supports OSC 2 title sequences — iTerm2, GNOME Terminal, Kitty, Alacritty, WezTerm, tmux, and more.

---

## Install

```bash
git clone https://github.com/iamiaud/claude-terminal-titles
cd claude-terminal-titles
bash install.sh
```

Restart Claude Code. Done.

The installer copies `session-title.sh` to `~/.claude/hooks/` and merges the hook entries into `~/.claude/settings.json` — your existing config is untouched.

### Uninstall

```bash
bash uninstall.sh
```

---

## Event reference

| Claude Code event | Tab title |
|---|---|
| Session starts | `▶ Session Start` |
| You submit a prompt | `💬 Thinking...` |
| Reading a file | `📄 filename.ext` |
| Editing a file | `✏️  filename.ext` |
| Writing a file | `💾 filename.ext` |
| Running a shell command | `$ cmd arg` |
| Searching / globbing | `🔍 pattern` |
| Spawning a subagent | `⚙ description` |
| Tool call succeeded | same label + ` ✓` |
| Tool call failed | `❌ toolname failed` |
| Waiting for permission | `⏳ Permission?` |
| Compacting context | `🗜 Compacting...` |
| Agent finished | `✅ Done` |
| Session ends | `💤 Session End` |

---

## How it works

Claude Code fires [lifecycle hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) on every action. This hook script receives the event name and the tool's JSON payload, then writes an [OSC 2](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html) escape sequence to the terminal to update the tab title.

**TTY detection** — hooks run as detached child processes and don't always inherit `/dev/tty`. The script tries three strategies in order:
1. Write directly to `/dev/tty` (works for sync hooks)
2. Use a cached device path from a previous sync hook
3. Walk up the process tree to find the parent TTY

**Persistence loop** — a background subshell re-applies the title every second so it survives shells that reset the title on each prompt (`zsh precmd`, tmux auto-rename, etc.).

---

## Customize

Edit `~/.claude/hooks/session-title.sh`. The two places to change are:

**`tool_label()`** — controls Pre/PostToolUse labels:
```bash
tool_label() {
  case "$1" in
    Read)  echo "📄 ${2:-read}" ;;
    Bash)  echo "$ ${2:-bash}" ;;
    # add your own tools here
  esac
}
```

**The `case` block** — controls all other event titles:
```bash
case "$EVENT" in
  Stop) TITLE="✅ Done" ;;   # change the emoji or text
esac
```

---

## tmux

If your tmux config sets `automatic-rename on`, it will fight with this script. Add to `~/.tmux.conf`:

```
set-option -g allow-rename on
set-option -g automatic-rename off
```

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `bash` + `python3` (standard on macOS and Linux)

No npm, no dependencies.

---

## License

MIT
