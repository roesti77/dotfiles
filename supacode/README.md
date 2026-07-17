# supacode

Stow package for [supacode](https://supacode.sh/) — a native macOS GUI app built on
*libghostty* that orchestrates several coding agents in parallel in isolated git
worktrees. Requires macOS 26 Tahoe.

## Integration model: supacode *on top of* zellij, not instead of it

Tabs/panes still run exclusively through zellij. supacode only owns the layer above:

| Layer | Tool | Responsibility |
|---|---|---|
| Orchestration | **supacode** | Which worktree / which agent? Parallel agents, PR status, notifications |
| Multiplexing *within* a worktree | **zellij** | Tabs + panes + neovim — unchanged setup |

Rule: **one supacode worktree = one zellij session.** supacode's own splits/tabs are
not used. Conflict-free, because supacode is Cmd-based and zellij runs under `Ctrl-g`.

`templates/supacode.json` implements this: `setupScript`/`runScript` attach — on
worktree creation or via `⌘R` — to a zellij session named after the worktree, and
`archiveScript` tears it down again on archiving.

## Terminal config comes from ghostty

supacode renders through GhosttyKit and reads the **existing ghostty config** (theme,
font, keybinds) — which is already stowed via the `ghostty` package. There is
therefore deliberately *no* separate terminal/keybind config here.

## Keyboard (keyboard-only)

| Action | Shortcut |
|---|---|
| Command palette | `⌘P` |
| New worktree (branch + worktree) | `⌘N` |
| Jump straight to a worktree | `⌃1` … `⌃0` |
| Next / previous worktree | `⌃⌘↓` / `⌃⌘↑` |
| Start / stop run/setup script | `⌘R` / `⌘.` |
| Toggle sidebar | `⌘[` |
| Open PRs | `⌃⌘G` |

`⌃1`–`⌃0` is intercepted by supacode at the app level *before* zellij sees it. Since
zellij's tab navigation lives under the `Ctrl-g` leader (not raw `Ctrl+digit`), this
is conflict-free — verify once on first use.

## Installation / stow

```sh
cd ~/dotfiles
stow -t ~ supacode
```

This links `~/.supacode/templates/supacode.json` (per-repo template, see below).

### settings.json — app-managed, adopt via --adopt

`~/.supacode/settings.json` is **not a hand-maintained file**: the app continuously
writes state into it (`global` preferences, but also machine-local things like
`repositories`, `repositoryRoots`, `pinnedWorktreeIDs`, orderings, lastFocused). So
don't write it by hand up front — adopt it after the first start:

```sh
# 1. Start supacode once, set preferences in the GUI
#    (notifications on, default editor = nvim, update channel …), then quit.
# 2. Pull the settings.json the app created into the package + relink it:
cd ~/dotfiles
stow -t ~ --adopt supacode
# 3. Check git diff: keep only portable keys, reset machine-local state if needed.
git -C ~/dotfiles add -p supacode
```

Note: because the app writes through the symlink, it dirties the repo during use.
Use `git add -p` before committing and leave out machine-local keys.

## Per-repo setup (zellij integration)

The zellij binding belongs per project in a `supacode.json` at the respective repo
root (not in the dotfiles repo). The template lives at
`~/.supacode/templates/supacode.json`:

```sh
cp ~/.supacode/templates/supacode.json /path/to/project/supacode.json
```

Then adjust `setupScript`/`runScript`/`openActionID` per project (e.g. add
`pnpm install` in the setupScript).
