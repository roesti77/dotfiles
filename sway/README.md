# sway — wayland session for the linux work laptop

The sway counterpart to the mac setup: same dark palette as ghostty (Catppuccin
Mocha), same `Super+F12` drop-down terminal, and a keyboard config that handles the
Corne and the built-in keyboard at the same time.

One stow package holds sway, waybar, mako, fuzzel and swaylock. They only work as
one session — splitting them into five packages would mean five `stow` calls for a
single desktop.

```sh
stow sway          # or: task setup-linux
```

`task setup` deliberately leaves this out — on the mac it would only create dead
symlinks.

## Install

```sh
sudo apt install sway swayidle swaylock swaybg waybar fuzzel mako-notifier \
  grim slurp wl-clipboard jq brightnessctl playerctl wireplumber pavucontrol \
  network-manager-gnome xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
  fonts-hack qt6ct adwaita-icon-theme qalc gnome-keyring papirus-icon-theme
```

`cliphist` (clipboard history) is not in the apt repos on every release — check with
`apt-cache policy cliphist` and fall back to the upstream release if it comes back
empty.

Ghostty is not in the apt repos — install it from the upstream Linux builds.
`sway --validate` checks the config without starting a session.

Sway cannot export variables into the session, so the theming and wayland hints go
into `~/.profile`:

```sh
export XDG_CURRENT_DESKTOP=sway
export QT_QPA_PLATFORMTHEME=qt6ct   # qt/kde apps follow a dark theme
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
```

GTK apps are switched to dark by the two `gsettings` lines in the config itself.

## Keyboard

`Super` is the window-manager modifier. On the mac the terminal swallows `Cmd`,
which is why the Corne's **MEH** exists — under sway nothing competes for `Super`,
so MEH stays entirely with zellij and Hyper is left free.

On the Corne, `Super` is the home-row mod on `s` / `e`, plus layer 3.

Two things the Corne needs from the input config:

- `xkb_layout us,de` — the Corne sends US HID codes, so US has to be the first
  group. `Caps` toggles to `de` for the built-in keyboard. Not `Alt+Shift`: that
  chord is part of every MEH and Hyper press.
- `xkb_numlock enabled` — the Corne's number layer emits keypad codes, which only
  resolve to `KP_1`..`KP_9` with numlock on. Without it the workspace bindings are
  dead on that keyboard.

To give the built-in keyboard `de` as its default while the Corne stays on `us`,
fill in the commented `input` block with the identifier from
`swaymsg -t get_inputs`.

## Umlauts

The mac's `alt+u` dead key is a macOS feature of the US layout — it has no linux
equivalent, which is why KDE could not reproduce it. Three ways out, all wired up:

- **AltGr** — the `altgr-intl` variant puts `ä ö ü ß` on `AltGr+q/p/y/s`. Two keys,
  no layout switch, and the base layer keeps its dead-key-free `'` and `"` for
  writing code. On the Corne AltGr is the `i` home-row mod.
- **Compose** — `Menu`, then `"`, then the vowel. Slower, but it covers every
  accent, dash and `€` in any layout.
- **`Caps`** — switches the whole keyboard to `de`, where the umlauts sit on their
  own keys.

The Corne's `TD(10)` hold still sends `LALT(KC_U)`, which does nothing on linux.
Remapping it to `KC_RALT` in Vial puts AltGr under the same key the umlaut
modifier had on the mac.

## Bindings

| Key | Action |
|---|---|
| `Super+Return` | ghostty (auto-starts zellij) |
| `Super+F12` | drop-down terminal — same key as the mac quick terminal |
| `Super+space` | fuzzel launcher |
| `Super+q` | close window |
| `Super+Escape` | lock screen |
| `Super+h/j/k/l` | focus window |
| `Super+Shift+h/j/k/l` | move window |
| `Super+Control+h/j/k/l` | resize window |
| `Super+1..9` | workspace (also on the keypad codes of the Corne) |
| `Super+Shift+1..9` | move window to workspace |
| `Super+Tab` / `Super+n` / `Super+p` | last / next / previous workspace |
| `Super+f` / `Super+e` / `Super+w` | fullscreen / toggle split / tabbed |
| `Super+Shift+space` | float toggle |
| `Super+Shift+v` | clipboard history |
| `Super+Shift+w` | jump to any window |
| `Super+c` | calculator |
| `Super+Shift+s` / `Print` | region / full screenshot to clipboard |
| `Super+Shift+c` / `Super+Shift+e` | reload config / exit sway |

Splits and layouts stay shallow on purpose: panes are zellij's job, sway only has
to place ghostty next to the browser.

`Super+Shift+1..9` has no keypad twin — `Shift` flips the numlock keysyms
(`KP_1` becomes `KP_End`), so moving windows stays on the number row.

## The raycast pieces

Raycast has no linux counterpart, so its parts are split across fuzzel and two
scripts:

- `Super+space` — app launcher.
- `Super+Shift+v` — clipboard history through `cliphist`. The daemon that fills it
  is the `wl-paste --watch` line in the config.
- `Super+Shift+w` — fuzzy-jump to a window, the same move `room` makes inside
  zellij, one level up.

The calculator is the exception: it opens `qalc` in a floating ghostty rather than
in fuzzel. Fuzzel's dmenu mode only returns entries that exist in its list, so a
calculator prompt would need a live-eval hook it does not have — and an interactive
qalc keeps its history and unit conversions on top.

## Session services

KDE and GNOME start a pile of services behind your back; sway starts nothing that
is not in its config. The one that actually matters is **gnome-keyring**: without
a secret service on the bus, browsers, chat clients and SSO flows fail to store
credentials — silently, which makes it an annoying thing to debug.

The config starts the daemon, but the keyring stays locked until something unlocks
it. For that PAM has to do it at login:

```
session optional pam_gnome_keyring.so auto_start
```

in `/etc/pam.d/sddm` (or whichever display manager is in use), plus
`auth optional pam_gnome_keyring.so` in the same file.

## Corporate tooling

- **Kerberos** is unaffected by the window manager. It hangs off PAM, SSSD and
  `krb5.conf`, so a session started from the same display manager gets the same
  ticket. `klist` after login is the whole test.
- **Tray-based VPN and proxy clients** are the part to verify before relying on
  this session. Waybar's tray implements StatusNotifierItem; clients that still use
  the legacy XEmbed tray show no icon — under any wayland session, GNOME included.
  If the icon is missing, the daemon is usually still running and reachable from
  the CLI.

Keep the old desktop installed and pick sway as a second session in the display
manager until both have been checked on the machine.

## Laptop specifics

- Idle: lock after 5 min, screens off after 10, lock before sleep.
- Closing the lid disables `eDP-1` — check the output name with
  `swaymsg -t get_outputs` if the laptop screen does not come back.
- `XDG_CURRENT_DESKTOP=sway` is pushed into the dbus activation environment,
  otherwise screen sharing in meeting apps picks the wrong portal backend.
