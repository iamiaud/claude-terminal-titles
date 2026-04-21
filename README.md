# claude-terminal-titles

Live terminal tab titles that show exactly what Claude Code is doing — at a glance, without switching windows.

![demo](https://user-images.githubusercontent.com/placeholder/demo.gif)

## What you get

| Event | Tab title |
|-------|-----------|
| Claude is reading a file | `📄 main.py` |
| Claude is editing | `✏️  config.ts` |
| Claude ran a shell command | `$ git status ✓` |
| Claude is searching | `🔍 def run_` |
| Claude spawned a subagent | `⚙ Subagent...` |
| Waiting for your input | `✅ Done` |
| You submitted a prompt | `💬 Thinking...` |
| Permission requested | `⏳ Permission?` |

Works in any terminal emulator that supports OSC 2 title sequences (iTerm2, GNOME Terminal, Kitty, Alacritty, WezTerm, tmux, etc.).

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `bash` + `python3` (already on every macOS/Linux system)

## Install

```bash
git clone https://github.com/YOUR_USERNAME/claude-terminal-titles
cd claude-terminal-titles
bash install.sh
```

Then **restart Claude Code**. That's it.

The installer:
1. Copies `session-title.sh` to `~/.claude/hooks/`
2. Merges hook entries into `~/.claude/settings.json` (non-destructively — your existing config is preserved)

## Uninstall

```bash
bash uninstall.sh
```

## How it works

Claude Code fires [lifecycle hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) on every action (`PreToolUse`, `PostToolUse`, `SessionStart`, etc.). `session-title.sh` receives the event name and the tool's JSON payload, then writes an OSC 2 escape sequence to the terminal to update the tab title.

**TTY detection** — hooks run as child processes and don't always inherit `/dev/tty`. The script tries three strategies in order:
1. Write directly to `/dev/tty`
2. Use a cached device path from a previous sync hook
3. Walk up the process tree to find the parent TTY

**Persistence loop** — a background subshell re-applies the title every second so it survives shells that reset titles on each prompt (zsh `precmd`, tmux title overrides, etc.).

## Customization

Edit `~/.claude/hooks/session-title.sh` to change emojis, labels, or add new events. The `tool_label()` function and the `case` block at the top are the two places to touch.

To add a custom event mapping:

```bash
case "$EVENT" in
  # ... existing entries ...
  MyCustomEvent) TITLE="🚀 Custom" ;;
esac
```

## tmux users

If your tmux config sets `set-option -g automatic-rename on`, it will fight with this script. Add this to `~/.tmux.conf` to let Claude Code win:

```
set-option -g allow-rename on
set-option -g automatic-rename off
```

## License

MIT
