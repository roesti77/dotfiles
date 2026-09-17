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
| `Super+space` | launcher — open windows and applications in one list |
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
| `Super+w` | tabbed on/off |
| `Super+s` | stacking on/off |
| `Super+a` | focus the parent container |
| `Super+g` | flip a container between side by side and stacked |
| `Super+b` / `Super+v` | direction for the **next** window |
| `Super+Shift+space` | floating on/off |
| `Super+Shift+Tab` | focus between tiled and floating windows |
| `Super+m` | large without fullscreen — 90% of the screen |
| `Super`+drag | move a floating window (right button resizes) |

Three fingers left and right walk the workspaces, four fingers jump between the
levels 1-3 and 4-6.

Splits stay shallow on purpose: panes are zellij's job, sway only has to put
ghostty next to the browser.

`Super+w` and `Super+s` toggle both ways because their lists include the layout
they switch out of. A bare `layout toggle split` cycles splith/splitv only and does
nothing at all while the container is tabbed.

Layouts apply to a container, not to the screen. In a nested split, `Super+a` steps
up one level so the outer container can be changed.

### Workspaces

| Key | Action |
|---|---|
| `Super+1..9` | switch — also from the Corne's keypad layer |
| `Super+Shift+1..9` | move the window there — keypad layer works too |
| `Super+Shift+,` / `Super+Shift+.` | move the whole workspace to the other monitor |
| `Super+grave` | last workspace |
| `Super+n` / `Super+p` | next / previous |

Shift flips the numlock keysyms, so the keypad variants are bound under the names
the keys actually send while shifted — `KP_1` arrives as `KP_End`. Same result, the
Corne just reaches them from layer 2.

### System

| Key | Action |
|---|---|
| `Hyper+l` | lock — Tab-hold then `l` on the Corne |
| `Super+d` / `Super+Shift+d` | dismiss one / all notifications |
| `Super+Shift+z` | park the focused window in the scratchpad |
| `Super+z` | bring a parked window back (cycles) |
| `Super+Shift+s` | screenshot a region to the clipboard |
| `Print` | whole screen to the clipboard |
| `Shift+Print` | region saved as a file |
| `Super+Shift+c` | reload the config |
| `Super+Shift+e` | exit sway, asks first |

Tiling has no minimise; the scratchpad stands in for it. What is parked is not
visible anywhere — `Super+z` cycles through it.

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
| `Ctrl o` then `w` | sessions and their tabs |

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
| `AltGr+u`, then the vowel | ä ö ü — same gesture as the mac's `alt+u` |
| home row `a r s t` | hold for Ctrl Alt Super Shift |
| home row `n e i o` | hold for Shift Super Alt Ctrl |

In the terminal this needs `GTK_IM_MODULE=simple` in `~/.profile` — GTK stopped
composing dead keys by itself in 4.20.

Layer 2 carries the digits as keypad codes, layer 3 the F-keys, arrows and media
keys.

Each keyboard has one fixed layout and there is nothing to toggle: the Corne runs
`usmac`, the built-in keyboard `de`. On `de` the umlauts sit on their own keys, so
the dead key is a Corne matter.

The umlaut dead key comes from `.config/xkb/symbols/usmac`, a local variant on top
of `us(altgr-intl)` — no linux layout ships that gesture. On the Corne, AltGr is the
`i` home-row mod. `TD(10)` still sends the mac's `LALT(KC_U)`, which does nothing
here and is free to be remapped.
