# Claude Code in Zellij

Working model: **one tab per Claude session** inside a Zellij session. Supacode
itself (package + hooks) stays installed alongside; the building blocks described
here are active outside of Supacode and inactive within it.

## Tab status: zellaude

[zellaude](https://github.com/ishefi/zellaude) (v0.5.1, vendored) replaces the tab
bar and shows each tab's Claude Code status — thinking, running bash, editing,
waiting for permission (⚠), waiting for prompt (▶), done (✓), idle (○). This makes
it obvious at a glance which Claude session in which tab is waiting for what. Set
via `default_layout "zellaude"` (layout `layouts/zellaude.kdl`).

On first load the plugin writes `~/.config/zellij/plugins/zellaude-hook.sh` itself
and registers the hook in the app-managed `~/.claude/settings.json`. These
plugin-generated files (`zellaude-hook.sh`, `zellaude.json`) are in `.gitignore`,
since they would otherwise land in the repo through the stow symlink. Runtime deps:
`jq`; optionally `terminal-notifier` for click-to-focus notifications.

**Activation:** start a fresh Zellij session (the plugin/layout load at session
start). Compatibility requirement: zellaude v0.5.1 is built against
`zellij-tile 0.43.1` = our Zellij version.

### Review tab

Open a review tab with:

```sh
zellij action new-tab --layout review
```

This opens a tab with nvim (diff/review, 55%) next to Claude Code + a shell (45%),
layout `layouts/review.kdl`. It uses the same zellaude bar as the default layout,
so several review tabs at the top each show their respective Claude status. (If you
want a shortcut, alias the command as `review` in your `.zshrc`.)

## Notifications: `macos-notify.sh`

The hook fires a macOS banner with sound on `Stop` (agent done); the Zellij session
name is in the title. Permission/waiting messages are handled by **zellaude** (bar
icon + its own banner), so the `Notification` branch is deliberately **not** wired
up — otherwise you get duplicate banners. Inside Supacode the hook is a no-op
(`SUPACODE_SOCKET_PATH` / bundle ID).

The script ships via the `hooks` symlink with `task setup`. The **wiring**
(macos-notify on `Stop` only) is declared in `claude/.claude/settings.seed.json`
and lands in the app-managed `~/.claude/settings.json` at bootstrap. The model +
bootstrap step (`cp seed → settings.json`, supacode injects its hooks live, fold
intentional changes back into the seed) are described in `claude/README.md` — not
duplicated here.

## First start after the merge

```sh
cd ~/dotfiles && task setup
```

Then start a fresh Zellij session (zellaude/layout load at start). Bootstrap
`settings.json` from the seed if needed (see `claude/README.md`).
