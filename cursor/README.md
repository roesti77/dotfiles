# cursor

Stow package for the global [Cursor](https://cursor.com) configuration (`~/.cursor`).

Cursor is the agent at a client where Claude Code is not the tool of choice. The
point of this package is *not* a second harness: most of the Claude Code harness
is loaded by Cursor as-is. This package only fills the gaps.

## Precondition: the third-party toggle

Everything below marked "reused" depends on one switch:

> Settings → Rules, Skills, Subagents → **Include third-party Plugins, Skills, and other configs**

Without it Cursor ignores the `.claude` directories and the harness is simply not there.

## What Cursor reuses from the `claude` package

| Surface | Path Cursor reads | Notes |
|---|---|---|
| Skills | `~/.claude/skills/`, `.claude/skills/` | loaded unmodified next to `~/.cursor/skills/` |
| Subagents | `~/.claude/agents/`, `.claude/agents/` | `.cursor/` only wins on a name clash |
| Hooks | `~/.claude/settings.json`, `.claude/settings.json`, `.claude/settings.local.json` | event names are mapped (`PreToolUse` → `preToolUse`, `Stop` → `stop`, …); the nested `hookSpecificOutput` format and exit code 2 both work, so `worktree-guard`, `context-guard` and `macos-notify` run unchanged |
| Project memory | `CLAUDE.md` / `AGENTS.md` in the repo | picked up per project, no configuration |

## What this package adds

| File | Purpose |
|---|---|
| `~/.cursor/cli-config.seed.json` | bootstrap seed for `cli-config.json` — the ported permission allow/deny lists |
| `~/.cursor/mcp.json` | MCP servers, token-free (see below) |
| `~/bin/agents-md` (from the `zsh` package) | renders `~/.claude/CLAUDE.md` into a project `AGENTS.md` |

### cli-config.json is app-managed, not stowed

Same reasoning as `settings.json` in the `claude` package: Cursor writes state
into `~/.cursor/cli-config.json` itself (`hasChangedDefaultModel`, `rewind`,
model choice, …), so a stow symlink would be replaced on first write and a stale
repo copy would only mislead. The repo carries the seed instead:

```sh
cp ~/.cursor/cli-config.seed.json ~/.cursor/cli-config.json
```

After deliberate permission changes, fold them back into the seed.

### Permissions

Ported from `claude/.claude/settings.seed.json` into Cursor's token syntax:
`Shell(commandBase:args)` with glob support, and deny always beats allow. The
read-only kubectl/helm/argocd/talosctl verbs stay allowed; the secret reads
(`kubectl get secret*`, `helm get values`/`all`) stay denied, plus `Read()`
denies for `.env*`, `*.key` and `*.pem`, which the Claude list cannot express
because it only gates shell commands.

Project-level overrides go into `<project>/.cursor/cli.json` — that is the only
part of the CLI config Cursor reads per project.

### MCP without secrets

`mcp.json` is checked into this **public** repo, so it carries no tokens: each
server sources its credentials from an env file under
`$HOME/.local/share/opencode/` at start-up, the same files the Claude Code and
opencode setups already use. Missing env file = that server fails to start, and
nothing leaks either way.

The global list is the personal one. On a client machine, scope anything
client-specific to `<project>/.cursor/mcp.json` instead of adding it here.

## Global conventions: `agents-md`

Cursor has no global `~/.cursor/AGENTS.md`; cross-project instructions would
have to live in account-synced User Rules, outside of git. So the conventions
stay in `~/.claude/CLAUDE.md` and get rendered into the project:

```sh
cd <project> && agents-md
```

The command rewrites only its own marked block, so hand-written project content
in `AGENTS.md` survives a re-run. It warns when `AGENTS.md` is not git-ignored —
these are personal conventions, and whether a client repo should carry them is a
deliberate decision, not a default.

## What does not carry over

- **Workflows** (`~/.claude/workflows/*.js`) — Cursor has no deterministic
  workflow runner. The subagents they orchestrate exist, so the same work has to
  be driven in natural language ("use the team-red subagent, then …").
- **Statusline, TUI and voice settings** — Claude Code specifics with no counterpart.

## Installation / stow

`~/.cursor` must exist as a **real directory** before stowing. Otherwise stow
folds the whole package into a single directory symlink, and Cursor then writes
its live state (`cli-config.json`, sessions, subagent output) straight into this
public repo — the same trap `~/.config/nvim` already sits in with `lazy-lock.json`.

```sh
mkdir -p ~/.cursor          # first, so stow links individual files
cd ~/dotfiles
stow -t ~ cursor
cp ~/.cursor/cli-config.seed.json ~/.cursor/cli-config.json   # once per machine
```

`.gitignore` carries the app-written paths as a second line of defence.
