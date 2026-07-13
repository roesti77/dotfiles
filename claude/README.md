# claude

Stow package for the global Claude Code configuration (`~/.claude`).

`stow claude` folds these into the existing `~/.claude` directory as individual
symlinks (the directory itself stays a real dir holding machine-local runtime
state):

| Link | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global memory / cross-project conventions |
| `~/.claude/settings.seed.json` | Bootstrap seed for `settings.json` (see below) |
| `~/.claude/statusline-command.sh` | Statusline script referenced by `settings.json` |
| `~/.claude/skills/` | Personal skills |
| `~/.claude/agents/` | Subagent fleet |
| `~/.claude/workflows/` | Orchestration workflows |
| `~/.claude/hooks/` | Hook scripts (e.g. worktree-guard) |

## settings.json is machine-managed, not stowed

Supacode rewrites `~/.claude/settings.json` via atomic rename, which replaces
any symlink with a real file — stowing it is futile and a stale repo copy just
misleads. The repo instead carries `settings.seed.json` with the user-owned
config (macos-notify + guard hooks, permissions, statusline, plugins, flags)
and no supacode-managed hooks.

Bootstrap on a new machine:

```sh
cp ~/.claude/settings.seed.json ~/.claude/settings.json
```

Supacode injects its `# supacode-managed-hook` entries into the live file on
first run. After deliberate settings changes, fold them back into the seed
(minus the supacode hooks).

## Secret exposure — what the permission list can and cannot do

The `permissions.deny` list blocks the obvious secret reads (`kubectl get
secret*`, `helm get values`/`all`). It is a string matcher, not a content
filter: it cannot express "no secret content". `kubectl get <resource> -o
yaml/jsonpath` on any secret-bearing object (a ServiceAccount token, a
ConfigMap holding credentials, a workload with inline env secrets) still
exfiltrates them and stays the operator's responsibility. Durable closure
would need an allow-only-non-secret model, not attempted here.

## Intentionally NOT managed here

- `settings.json` — machine-managed by supacode (see above)
- `settings.local.json` — machine-local permissions / MCP servers
- `allowed-contexts` — machine-local kube contexts the context-guard hook may mutate
- `remote-settings.json` — secrets
- `projects/`, `file-history/`, `cache/`, `plugins/`, `telemetry/`, … — runtime state
