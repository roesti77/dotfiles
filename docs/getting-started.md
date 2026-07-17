# Getting Started — the Claude Code + zellij + nvim workflow

A short guide to the day-to-day working model this setup is built for.

## The idea

Claude Code writes most of the code. Your job shifts from *typing* to *reviewing* —
and the way you stay connected to the codebase is by **reading diffs like a
reviewer**, in nvim, after each CC run. The tools are split by role:

- **Claude Code** — writes.
- **nvim** — your reading / review / navigation surface.
- **zellij** — one tab per Claude session, with a status bar that shows what each
  session is doing.

The rule of thumb: *the diff you read is the new code you write.* If you review
every change as if you had to defend it in a PR, you keep the mental map of the
codebase alive at full CC speed.

## The daily flow

1. Start a zellij session. The tab bar is **zellaude** — each tab shows its Claude
   status at a glance (see below).
2. Work with Claude Code in a tab. One tab = one Claude session.
3. When CC has produced changes, open a **review tab**:
   ```sh
   zellij action new-tab --layout review
   ```
   You get nvim (left, 55%) next to Claude Code + a shell (right, 45%).
4. In nvim, read the change:
   - `<leader>gdm` — diff of the whole session (branch vs `origin/main`). This is
     the main review key.
   - `<leader>gdd` — just the uncommitted working tree.
   Go through it hunk by hunk. Ask: *would I have written it this way? If not, why
   did CC?*
5. The zellaude bar tells you which other tabs need attention (waiting for
   permission / prompt / done) so you can juggle parallel sessions.

## zellaude tab status

The tab bar shows, per tab: thinking · running bash · editing · ⚠ waiting for
permission · ▶ waiting for prompt · ✓ done · ○ idle. See
[zellij-workflow.md](./zellij-workflow.md) for details.

## nvim review keymaps

Leader is `<Space>`.

| Key | Action |
|---|---|
| `<leader>gdm` | Diff branch vs `origin/main` — **review the whole session** |
| `<leader>gdd` | Diff working tree (uncommitted) |
| `<leader>gdh` / `<leader>gdH` | File history / repo history |
| `<leader>gdq` | Close diffview |
| `<leader>gp` | Preview hunk (gitsigns) |
| `<leader>gt` | Toggle line blame (gitsigns) |
| `<leader>gs` | Git status picker (telescope) |
| `<leader>gc` / `<leader>gcf` | Git commits / commits for current file |
| `<leader>sf` / `<leader>sg` / `<leader>sw` | Find files / live grep / grep word |
| `<leader>sb` / `<leader>sr` / `<leader>s.` | Buffers / resume / recent files |

## zellij cheat sheet

Press **`Ctrl y`** any time — the `zellij-forgot` plugin shows the live keybindings.
The essentials:

| Group | Key | Action |
|---|---|---|
| Modes | `Ctrl o` / `Ctrl t` / `Ctrl p` | session / tab / pane mode |
| Modes | `Ctrl n` / `Ctrl m` / `Ctrl s` | resize / move / scroll mode |
| Modes | `Ctrl g` | lock (pass keys straight to the program) — press again to unlock |
| Move | `Ctrl h/j/k/l` | move focus (or to the next tab at an edge) |
| Tabs | `Ctrl i` / `Alt o` | move tab left / right |
| Panes | `Alt n` / `Alt f` | new pane / toggle floating |
| Layouts | `Ctrl a` / `Alt a` | next / previous swap layout |
| Jump | `Ctrl Shift t` | fuzzy jump to pane/tab (`room`) |
| Tree | `Ctrl o` then `w` | session/tab tree (`choose-tree`) |
| Quit | `Ctrl q` | quit zellij |

Within a mode: pane mode `n/d/r` new panes, `f` fullscreen, `w` float, `x` close;
tab mode `n` new, `x` close, `r` rename, `b` break pane.

## Keyboard: Hyper / MEH (Corne)

The Corne exposes a **Hyper** (Ctrl+Shift+Alt+Cmd) and a **MEH** (Ctrl+Shift+Alt)
modifier. Terminals swallow `Cmd`, so for terminal/zellij shortcuts use **MEH** —
it is the collision-free "hyper for the terminal" (nvim's `<C-w>`, readline, etc.
stay untouched). Kitty keyboard protocol is enabled so MEH chords reach zellij.

## First run

```sh
cd ~/dotfiles && task setup
```

Then start a fresh zellij session (the zellaude bar and layouts load at session
start). For plugin/notification/`settings.json` details see
[zellij-workflow.md](./zellij-workflow.md).
