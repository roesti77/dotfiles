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
| `~/.claude/agents/` | Subagent fleet |
| `~/.claude/workflows/` | Orchestration workflows |
| `~/.claude/hooks/` | Hook scripts (e.g. worktree-guard) |

## Intentionally NOT managed here

- `settings.local.json` — machine-local permissions / MCP servers
- `remote-settings.json` — secrets
- `projects/`, `file-history/`, `cache/`, `plugins/`, `telemetry/`, … — runtime state

> Note: `settings.json` contains supacode-managed hooks that supacode rewrites
> automatically — expect occasional churn there after running supacode.
