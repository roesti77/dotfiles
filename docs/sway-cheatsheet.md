# Keybindings — sway, zellij, nvim

Three layers, three modifiers. Each layer owns its own key, which is why they stay
out of each other's way — except at the four keys listed at the bottom.

## The modifier map

| Layer | Modifier | On the Corne | Owns |
|---|---|---|---|
| sway | `Super` | `s` / `e` home-row mod | windows, workspaces, launching |
| zellij | `Ctrl` | `a` / `o` home-row mod | modes, panes, tabs |
| nvim | `Space` | left thumb | everything inside the editor |
| — | Hyper | Tab-hold | lock screen, nothing else |
| — | MEH | Esc-hold | unused, reserved for zellij |

On the mac MEH exists because the terminal swallows `Cmd`. Under sway nothing
competes for `Super`, so MEH stayed reserved for zellij.

`Super` is the same key and the same HID code macOS calls Command.

## sway

### Launching

| Key | Action |
|---|---|
| `Super+Return` | ghostty — starts zellij with it |
| `Super+F12` | drop-down terminal, same key as the mac quick terminal |
| `Super+space` | launcher (fuzzel) |
| `Super+c` | calculator (qalc) |
| `Super+Shift+v` | clipboard history |

### Windows

| Key | Action |
|---|---|
| `Super+Tab` | window switcher — the cmd+tab reflex |
| `Super+h/j/k/l` | move focus (arrow keys work too) |
| `Super+Shift+h/j/k/l` | move the window |
| `Super+Control+h/j/k/l` | resize |
| `Super+q` | close, without asking |

### Layout

| Key | Action |
|---|---|
| `Super+f` | fullscreen |
| `Super+w` | tabbed — closest to how windows feel on the mac |
| `Super+e` | toggle split |
| `Super+b` / `Super+v` | split horizontally / vertically |
| `Super+Shift+space` | floating on/off |

Splits stay shallow on purpose: panes are zellij's job, sway only has to put
ghostty next to the browser.

### Workspaces

| Key | Action |
|---|---|
| `Super+1..9` | switch — also from the Corne's keypad layer |
| `Super+Shift+1..9` | move the window there — number row only |
| `Super+grave` | last workspace |
| `Super+n` / `Super+p` | next / previous |

`Super+Shift+1..9` has no keypad twin because Shift flips the numlock keysyms:
`KP_1` becomes `KP_End`.

### System

| Key | Action |
|---|---|
| `Hyper+l` | lock — Tab-hold then `l` on the Corne |
| `Super+d` / `Super+Shift+d` | dismiss one / all notifications |
| `Super+Shift+s` | screenshot a region to the clipboard |
| `Print` | whole screen to the clipboard |
| `Super+Shift+c` | reload the config |
| `Super+Shift+e` | exit sway, asks first |

Volume, brightness and media keys work from their own keys, and from the Corne's
layer 3. Closing the lid disables the internal display.

## zellij

`Ctrl y` shows the live bindings at any time (`zellij-forgot`). `Esc` leaves a mode.

### Modes

| Key | Mode |
|---|---|
| `Ctrl p` / `Ctrl t` / `Ctrl o` | pane / tab / session |
| `Ctrl n` / `Ctrl m` / `Ctrl s` | resize / move / scroll |
| `Ctrl g` | lock — passes every key through |
| `Ctrl b` | tmux compatibility |

### Moving

| Key | Action |
|---|---|
| `Ctrl h/j/k/l` | focus, and at an edge the neighbouring tab |
| `Ctrl i` / `Alt o` | move the tab left / right |
| `Ctrl Shift t` | fuzzy jump (`room`) |
| `Ctrl o` then `w` | session tree |

### Panes and tabs

| Key | Action |
|---|---|
| `Alt n` / `Alt f` | new pane / floating |
| `Ctrl a` / `Alt a` | next / previous swap layout |
| `Ctrl p` then `n`/`d`/`r` | new pane: free / below / right |
| `Ctrl p` then `f`/`x` | fullscreen / close |
| `Ctrl t` then `n`/`x`/`r`/`b` | tab new / close / rename / break out |

### Review workflow

| Key | Action |
|---|---|
| `Ctrl e` | pick a changed repo, open its diff in nvim |
| `Ctrl o` then `d` | detach — the session keeps running |
| `Ctrl q` | quit zellij, all tabs |

## nvim

Leader is `Space`. The agent lives inside the editor, not in a pane of its own.

### Reading a diff

| Key | Action |
|---|---|
| `<leader>gdm` | branch vs `origin/main` — the main review key |
| `<leader>gdd` | working tree only |
| `<leader>gdh` / `<leader>gdH` | file / repo history |
| `<leader>gdq` | close diffview |
| `<leader>gp` / `<leader>gt` | hunk preview / line blame |

### Agent

| Key | Action |
|---|---|
| `<C-.>` | toggle the chat (CodeCompanion) |
| `gv` | view the proposed diff |
| `g2` / `g3` | accept / reject the hunk |
| `g1` | accept the whole buffer |

### Search

| Key | Action |
|---|---|
| `<leader>sf` / `<leader>sg` | files / live grep |
| `<leader>sw` | word under the cursor |
| `<leader>sb` / `<leader>sr` / `<leader>s.` | buffers / resume / recent |
| `<leader>gs` / `<leader>gc` | git status / commits |

### Buffers and windows

| Key | Action |
|---|---|
| `Tab` / `Shift+Tab` | next / previous buffer |
| `<leader>q` / `<leader>b` | close / new buffer |
| `<leader>v` / `<leader>h` | split vertically / horizontally |
| `jk` / `kj` | escape from insert mode |
| `<leader>y` | yank to the system clipboard |

## Where the layers overlap

zellij binds these globally, so it takes them before the editor ever sees them.
That is the layer order working as intended — it just helps to know which keys it
costs.

| Key | What actually happens |
|---|---|
| `Ctrl h/j/k/l` | zellij moves the focus, **not** nvim's window switch |
| `Ctrl s` | zellij enters scroll mode, it does **not** save |
| `Ctrl q` | quits **all of zellij**, not the nvim window |
| `Ctrl e` | opens the diff picker instead of nvim's scroll |

The way out is `Ctrl g` — lock mode passes everything through to nvim, and a second
press turns it off again. `<leader>v` and `<leader>h` avoid the problem entirely by
not using `Ctrl`.

sway collides with neither layer. That is the reason the window manager sits on
`Super` rather than on MEH: no terminal and no editor claims that key.

## The keyboard itself

| Key | Action |
|---|---|
| `AltGr+q/p/y/s` | ä ö ü ß — AltGr is the `i` home-row mod |
| `Menu`, `"`, vowel | compose, for everything else |
| `Caps` | switch layout us ⇄ de |
| home row `a r s t` | hold for Ctrl Alt Super Shift |
| home row `n e i o` | hold for Shift Super Alt Ctrl |

Layer 2 carries the digits as keypad codes, layer 3 the F-keys, arrows and media
keys. The mac's `alt+u` umlaut dead key has no linux equivalent; `TD(10)` still
sends it and does nothing here.
