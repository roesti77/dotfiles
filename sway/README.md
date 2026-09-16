# sway — wayland session for the linux work laptop

The sway counterpart to the mac setup: same dark palette as ghostty (Catppuccin
Mocha), same `Super+F12` drop-down terminal, and a keyboard config that handles the
Corne and the built-in keyboard at the same time.

One stow package holds sway, waybar, mako, fuzzel and swaylock. They only work as
one session — splitting them into five packages would mean five `stow` calls for a
single desktop.

## Install

```sh
task setup-linux
```

That stows the package and runs `scripts/bootstrap`, which installs the apt
packages, wires KWallet up as the secret service and validates the config. It is
idempotent — re-run it whenever something changed.

`task setup` deliberately leaves this out; on the mac it would only create dead
symlinks.

Two things bootstrap cannot install, and warns about instead: **ghostty** has no
apt package (upstream linux builds), and **cliphist** is missing from the repos on
some releases (`apt-cache policy cliphist`, otherwise the upstream release).

Sway cannot export variables into its own session, so these go into `~/.profile`:

```sh
export XDG_CURRENT_DESKTOP=sway
export QT_QPA_PLATFORMTHEME=kde     # qt apps read kdeglobals, so breeze applies
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
```

If qt apps come up unstyled, `qt6ct` is the fallback — install it and point
`QT_QPA_PLATFORMTHEME` at it instead.

## What comes from KDE, and what cannot

This runs on a machine that already has KDE, so the rule is: standalone KDE
services are reused, anything living inside plasmashell or KWin is replaced.

| Piece | Used | Why |
|---|---|---|
| Secret service | KWallet | credentials are already in it |
| Icons, GTK theme | Breeze | already installed, matches the KDE apps |
| Portal, dialogs | `xdg-desktop-portal-kde` | already installed |
| Portal, screencast | `xdg-desktop-portal-wlr` | the KDE portal screencasts over KWin protocols sway does not speak |
| Network tray | `nm-applet` | plasma-nm is a plasmashell widget, not a tray program |
| Notifications | `mako` | plasma notifications come out of plasmashell |

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

The mac types them with `alt+u` followed by the vowel. No linux layout offers that
dead key, which is why KDE could not reproduce it either — and the keyboard cannot
fix it, because QMK has only HID codes and no keycode for `ä`.

So the layout provides it: `.config/xkb/symbols/usmac` is a variant that includes
`us(altgr-intl)` and overrides a single key, putting `dead_diaeresis` on the third
level of `u`.

```
AltGr+u, then a / o / u   ->   ä ö ü
```

Same gesture as on the mac, with the right Alt instead of the left. The left one is
part of MEH and Hyper and cannot be spent on this.

xkbcommon reads `~/.config/xkb/symbols/` without root, so the variant ships through
this package like everything else. After a reload the keyboard should report it:

```sh
swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name'
# English (US, macOS umlaut)
```

If it says anything else the variant did not load, and sway silently fell back.

`Caps` still switches the whole keyboard to `de`, where the umlauts sit on their own
keys. No compose key is configured: every key xkb offers for it is either missing on
both keyboards or a home-row mod on the Corne.

## Bindings

Every binding across sway, zellij and nvim lives in
[docs/sway-cheatsheet.md](../docs/sway-cheatsheet.md) — one table per layer, so a
rebind only has to be written down once. The rules worth knowing here:

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
- `Super+Tab` — fuzzy-jump to a window, the same move `room` makes inside zellij,
  one level up. It sits on Tab because that is where the mac's cmd+tab reflex
  lands; `back_and_forth` moved to `Super+grave`.

The calculator is the exception: it opens `qalc` in a floating ghostty rather than
in fuzzel. Fuzzel's dmenu mode only returns entries that exist in its list, so a
calculator prompt would need a live-eval hook it does not have — and an interactive
qalc keeps its history and unit conversions on top.

## Secret service

Sway starts nothing that is not in its config, and without a secret service on the
bus browsers, chat clients and SSO flows fail to store credentials — silently,
which makes it an annoying thing to debug.

KWallet covers this. It serves `org.freedesktop.secrets` since KDE Frameworks 5.97
and runs fine without plasma, but it ships no dbus service file for that interface,
so nothing finds it until one exists. `scripts/bootstrap` writes it to
`~/.local/share/dbus-1/services/`. The checkbox under
*System Settings > KDE Wallet > Use KWallet for the Secret Service interface* does
the same thing.

No unlock handling is needed here: `pam_kwallet` already runs at the display
manager, so the wallet is open before sway starts.

## Why waybar is masked in systemd

The waybar package ships a systemd unit bound to `graphical-session.target`. That
target is not up at login — it gets activated later, when some other service pulls
it in. The result is a second bar appearing mid-session next to the one sway's
`exec` already started.

`scripts/bootstrap` masks the unit. The `exec` line stays, because it is the one
that actually fires when sway does.

## Corporate tooling

- **Kerberos** is unaffected by the window manager. It hangs off PAM, SSSD and
  `krb5.conf`, so a session started from the same display manager gets the same
  ticket. `klist` after login is the whole test.
- **The VPN client window** is parked by `scripts/park-vpn`, which matches the
  window title — it scans the tree once at startup and then watches sway's event
  stream, so the order in which the client and the session come up does not matter.
  Sway runs no XDG autostart entries, so that order is not fixed. Two attempts at an `app_id` or
  `class` rule missed, and the title is the one thing that is known. `Super+z`
  brings it back. A floating window always stacks above tiled ones in sway, so
  moving it out of the way is the only real fix.
- **Tray-based VPN and proxy clients** are the part to verify before relying on
  this session. Waybar's tray implements StatusNotifierItem; clients that still use
  the legacy XEmbed tray show no icon — under any wayland session, GNOME included.
  If the icon is missing, the daemon is usually still running and reachable from
  the CLI.

Keep the old desktop installed and pick sway as a second session in the display
manager until both have been checked on the machine.

## Wallpaper

Drop any image at `~/.local/share/wallpaper` — no extension, swaybg reads the
format itself. Without it the background stays the flat Catppuccin base; the colour
after `fill` is swaybg's fallback, so a missing file is not an error.

That path is deliberately outside the stow tree. `~/.config/sway` is a symlink into
this repo, so a file dropped there would land in a public repository.

`azote` or `waypaper` are worth a look if you would rather click through candidates
than move files around.

## Displays

`scripts/displays` applies the layout from whatever is connected, so no monitor
name is hardcoded: externals go side by side in connector order, each at the
highest mode it offers, and the laptop panel is placed to their right.

With **two** externals the laptop panel is switched off, and that is not a
preference: the graphics unit drives two panels, not three, so one would stay dark
anyway. Unplugging one proved it. With a single external both fit and both run.

The script runs on every reload and when the lid opens. Left-to-right follows the
connector name, which may not match where the monitors physically stand; swapping
the cables is the fix, since sway cannot know. `wdisplays` is useful for trying an
arrangement out live, but it does not persist anything.

## Laptop specifics

- Idle: lock after 5 min, screens off after 10, lock before sleep.
- Closing the lid disables `eDP-1` — check the output name with
  `swaymsg -t get_outputs` if the laptop screen does not come back.
- `XDG_CURRENT_DESKTOP=sway` is pushed into the dbus activation environment,
  otherwise screen sharing in meeting apps picks the wrong portal backend.
