# Agents in Zellij

Working model: the agent runs **inside nvim** (CodeCompanion, chat buffer +
inline diffs), not as its own process in a pane. Zellij therefore only provides
tabs, panes and attention badges — it knows nothing about the agent any more.
Supacode stays installed alongside; the building blocks described here are
active outside of Supacode and inactive within it.

Which agent answers depends on the machine: `claude_code` by default,
`cursor_cli` where Cursor is the tool of the engagement. Both are ACP presets in
`nvim/.config/nvim/lua/plugins/ai/codecompanion.lua`.

## Review tab

```sh
review    # alias in .zshrc
# or: zellij action new-tab --layout review
```

Layout `layouts/review.kdl`: nvim on top (70%), a shell below it (30%) for gates
and git. There is deliberately no agent pane — `<C-.>` toggles the chat inside
nvim, `<leader>gdm` reviews the session diff (branch vs `origin/main`),
`<leader>gdd` the working tree.

## Attention badges: `zellij-attention`

Configured in `config.kdl`, badges a tab with ⏳ (waiting) and ✅ (done). It is
fed by `zellij pipe` from the `Stop`/`Notification` hooks declared in
`claude/.claude/settings.seed.json`.

**Unverified since the move into nvim:** whether Claude Code fires those hooks
while running in ACP mode as a child process of nvim. If it does, the badge now
lands on the nvim pane — which is the right place, since that is where the agent
lives. If it does not, the badges stay silent and the hook wiring is dead weight.
One real prompt answers it; nothing here depends on the outcome.

The same applies to `macos-notify.sh`, which fires a macOS banner on `Stop` (and
is a no-op inside Supacode via `SUPACODE_SOCKET_PATH` / bundle ID).

## Tab bar

`default_layout "compact"` — the built-in compact bar. The vendored `zellaude`
plugin (a bar showing per-tab Claude Code status) was removed: it was never
switched on (no `default_layout`, no hook in `~/.claude/settings.json`, no
runtime files), and with the agent inside nvim a per-tab agent status has no
subject left. It is in the git history if the model ever changes back.

## First start after the merge

```sh
cd ~/dotfiles && task setup
```

Then start a fresh Zellij session (layouts load at session start). Bootstrap
`settings.json` from the seed if needed (see `claude/README.md`).
