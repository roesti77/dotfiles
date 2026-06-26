# claude

Stow package for the global Claude Code configuration (`~/.claude`).

`stow claude` folds these into the existing `~/.claude` directory as individual
symlinks (the directory itself stays a real dir holding machine-local runtime
state):

| Link | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global memory / cross-project conventions |
| `~/.claude/settings.json` | Global settings (hooks, statusline, plugins, flags) |
| `~/.claude/statusline-command.sh` | Statusline script referenced by `settings.json` |
| `~/.claude/skills/` | Personal skills |

## Intentionally NOT managed here

- `settings.local.json` — machine-local permissions / MCP servers
- `remote-settings.json` — secrets
- `agents/` — symlink into the separate `company/ai-agents` repo
- `projects/`, `file-history/`, `cache/`, `plugins/`, `telemetry/`, … — runtime state

> Note: `settings.json` contains supacode-managed hooks that supacode rewrites
> automatically — expect occasional churn there after running supacode.
