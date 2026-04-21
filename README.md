# claude-terminal-titles

> Live terminal tab titles for [Claude Code](https://claude.ai/code) — see exactly what the agent is doing without switching windows.

Your terminal tab updates in real time as Claude works: reading files, running commands, spawning subagents, waiting for you. Fully customizable — swap emojis, change labels, make it yours.

---

## Preview

```
📄 server.ts           ← reading a file
✏️  routes/auth.ts      ← editing
$ pytest tests/ ✓      ← command finished
🔍 def handle_         ← searching the codebase
⚙ Subagent...          ← spawned a background agent
✅ Done                ← waiting for your next message
💬 Thinking...         ← processing your prompt
⏳ Permission?         ← needs your approval
```

Works with any terminal emulator that supports OSC 2 title sequences — iTerm2, GNOME Terminal, Kitty, Alacritty, WezTerm, tmux, and more.

---

## Install

```bash
git clone https://github.com/iamiaud/claude-terminal-titles
cd claude-terminal-titles
bash install.sh
```

The installer asks:

```
  [1] Default  — install with standard emoji & labels
  [2] Custom   — choose your own emoji and titles
```

Choosing **Custom** opens an interactive configurator where you can change every emoji and label before the first run.

Then **restart Claude Code**. Done.

---

## Reconfigure anytime

```bash
bash configure.sh
```

```
╔══════════════════════════════════════════════════╗
║  claude-terminal-titles  ·  Configure            ║
╚══════════════════════════════════════════════════╝

  ── Tool labels ─────────────────────────────────────
   1  Read file               📄
   2  Edit file               ✏️
   3  Write file              💾
   4  Run command             $
   5  Search / Glob           🔍
   6  Spawn agent             ⚙
   7  Other tool              🔧

  ── Event titles ────────────────────────────────────
   8  Session start           ▶ Session Start
   9  Session end             💤 Session End
  10  Thinking                💬 Thinking...
  11  Done                    ✅ Done
  ...

  [s] Save   [r] Reset defaults   [q] Quit without saving
```

Type a number to edit that item, then `s` to save. Your choices are stored in `~/.claude/hooks/session-title.conf` — a plain shell file you can also edit by hand.

---

## Uninstall

```bash
bash uninstall.sh
```

---

## Event reference

| Event | Default title |
|---|---|
| Session starts | `▶ Session Start` |
| You submit a prompt | `💬 Thinking...` |
| Reading a file | `📄 filename.ext` |
| Editing a file | `✏️  filename.ext` |
| Writing a file | `💾 filename.ext` |
| Running a shell command | `$ cmd arg` |
| Searching / globbing | `🔍 pattern` |
| Spawning a subagent | `⚙ description` |
| Tool call succeeded | same + ` ✓` |
| Tool call failed | `❌ toolname failed` |
| Waiting for permission | `⏳ Permission?` |
| Compacting context | `🗜 Compacting...` |
| Agent finished | `✅ Done` |
| Session ends | `💤 Session End` |

---

## How it works

Claude Code fires [lifecycle hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) on every action. `session-title.sh` receives the event name and the tool's JSON payload, extracts a context label with a small Python snippet, then writes an [OSC 2](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html) escape sequence to update the tab title.

**TTY detection** — hooks run as detached child processes and don't always inherit `/dev/tty`. The script tries three strategies in order: direct `/dev/tty`, a cached device path from a previous sync hook, and a process-tree walk as a last resort.

**Persistence loop** — a background subshell re-applies the title every second so it survives shells that reset titles on each prompt (zsh `precmd`, tmux auto-rename, etc.).

**Config** — `session-title.sh` sources `~/.claude/hooks/session-title.conf` on every invocation. Edit it manually or use `configure.sh` — changes take effect the next time a hook fires (no restart needed for label changes).

---

## tmux

If your tmux config has `automatic-rename on`, add this to `~/.tmux.conf`:

```
set-option -g allow-rename on
set-option -g automatic-rename off
```

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `bash` + `python3` (standard on macOS and Linux)

No npm. No dependencies.

---

## License

MIT
