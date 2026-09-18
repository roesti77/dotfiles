# sway — wayland session for the linux work laptop

The sway counterpart to the mac setup: same dark palette as ghostty (Catppuccin
Mocha) and a keyboard config that handles the Corne and the built-in keyboard at
the same time.

One stow package holds sway, waybar, mako, wofi and swaylock. They only work as
one session — splitting them into five packages would mean five `stow` calls for a
single desktop.

## Install

```sh
task setup-linux
```

That stows the package and runs `scripts/bootstrap`, which installs the apt
packages, wires KWallet up as the secret service and validates the config. It is
idempotent — re-run it whenever something changed.

For the packages alone, after adding one to the list:

```sh
task sway:deps
```

Same list, just an earlier exit — `bootstrap --deps` stops after the install.

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
export GTK_IM_MODULE=simple         # without it ghostty swallows dead keys
```

That last one is not optional if you want umlauts in the terminal. Since GTK 4.20,
GTK no longer composes dead keys itself under wayland when no input method is
present — and none is here. Ghostty is a GTK application and is affected;
applications that bring their own input method are not, which is why umlauts work
in the launcher and nowhere in the terminal. Harmless unless you actually run ibus
or fcitx.

If qt apps come up unstyled, `qt6ct` is the fallback — install it and point
`QT_QPA_PLATFORMTHEME` at it instead.

## What comes from KDE, and what cannot

This runs on a machine that already has KDE, so the rule is: standalone KDE
services are reused, anything living inside plasmashell or KWin is replaced.

| Piece | Used | Why |
|---|---|---|
| Secret service | KWallet | credentials are already in it |
| Icons, GTK theme | Breeze | already installed, matches the KDE apps |
| Portal, dialogs and appearance | `xdg-desktop-portal-gtk` | backends are picked by `XDG_CURRENT_DESKTOP`, and the KDE one only answers for KDE |
| Portal, screencast | `xdg-desktop-portal-wlr` | the KDE portal screencasts over KWin protocols sway does not speak |
| Network tray | `nm-applet` | plasma-nm is a plasmashell widget, not a tray program |
| Notifications | `mako` | plasma notifications come out of plasmashell |

Dark mode runs through `gsettings`, set by the config itself. GTK applications read
it directly, electron ones ask the portal — and the portal backend reads the same
gsettings, which is why `xdg-desktop-portal-gtk` has to be the one installed.
Installing the KDE backend instead does nothing here: backends are selected by
`XDG_CURRENT_DESKTOP`, which is `sway`, and the KDE one declares itself for `KDE`.

What the portal actually reports:

```sh
busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings Read ss org.freedesktop.appearance color-scheme
# 1 dark, 2 light, 0 no preference — 0 means no backend answered
```

## Keyboard

`Super` is the window-manager modifier. On the mac the terminal swallows `Cmd`,
which is why the Corne's **MEH** exists — under sway nothing competes for `Super`,
so MEH stays entirely with zellij and Hyper is left free.

On the Corne, `Super` is the home-row mod on `s` / `e`, plus layer 3.

The type block sets **no layout at all**. Sway merges type and device settings field
by field, so a layout there and a variant in a device block can pair into a
combination that does not exist. Only the shared settings live in the type block;
every real keyboard names its own layout, which makes a wrong pairing impossible
rather than merely unlikely.

`sway --validate` does not catch any of this — it never compiles a keymap. The only
real test is `swaymsg reload` on the machine.

- **The Corne** runs `usmac` — it sends US HID codes, so anything else mistypes. It
  registers as four devices, so it needs four blocks; a rule on one of them alone
  would only half apply.
- **The built-in keyboard** runs `de` through its own block,
  `1:1:AT_Translated_Set_2_keyboard`.
- **`xkb_numlock enabled`** — the Corne's number layer emits keypad codes, which
  only resolve to `KP_1`..`KP_9` with numlock on. Without it the workspace bindings
  are dead on that keyboard.

There is no layout toggle any more: each keyboard has the layout it needs, so there
is nothing to switch between.

## No drop-down terminal

Ghostty has a quick terminal and since 1.2 it works on linux too, over
`wlr-layer-shell-v1`, which sway speaks. What is missing is a way to trigger it
without ghostty being focused:

- `global:` keybinds are macOS-only. Ghostty's own docs say so — *"This feature is
  only supported on macOS"* — and it drops the prefix silently rather than
  complaining, which is why it behaves the same under KDE.
- The IPC action sway could call, `+toggle-quick-terminal`, is merged (PR #12661)
  but sits on milestone **1.4.0**. The newest tag is v1.3.1.

A scratchpad imitation lived here until then and was removed: it was a stand-in for
something that already exists and is one release away. With 1.4.0 this becomes a
single line and nothing else:

```
bindsym $mod+F12 exec ghostty +toggle-quick-terminal
```

Until then, `Super+Return` opens a normal window.

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
this package like everything else.

The dead key only becomes a character once the application composes it. That takes
a UTF-8 locale, the sequence in `/usr/share/X11/locale/<locale>/Compose` — that path
is libxkbcommon's, nothing to do with X11 — and, for ghostty, `GTK_IM_MODULE=simple`
above. `wev` shows what the keyboard actually sends and separates a layout problem
from a composing one. After a reload the keyboard should report it:

```sh
swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name'
# English (US, macOS umlaut)
```

If it says anything else the variant did not load, and sway silently fell back.

On the built-in keyboard the umlauts sit on their own keys anyway — it runs `de`,
so the dead key is a Corne matter. There is no layout toggle: each keyboard has the
one layout it needs. No compose key either, since every key xkb offers for it is
either missing on both keyboards or a home-row mod on the Corne.

Only options that upstream swaylock knows belong in `swaylock/config`. A bare
`indicator` is swaylock-effects, and upstream exits on it **without locking** —
silently, because `swaylock -f` returns before drawing anything.

## Bindings

Every binding across sway, zellij and nvim lives in
[docs/sway-cheatsheet.md](../docs/sway-cheatsheet.md) — one table per layer, so a
rebind only has to be written down once. The rules worth knowing here:

Splits and layouts stay shallow on purpose: panes are zellij's job, sway only has
to place ghostty next to the browser.

`Super+Shift+1..9` has no keypad twin — `Shift` flips the numlock keysyms
(`KP_1` becomes `KP_End`), so moving windows stays on the number row.

## The raycast pieces

Raycast has no linux counterpart, so its parts are split across wofi and two
scripts:

- `Super+space` — one list of open windows and applications; picking a window
  jumps to it, across workspaces.
- `Super+Shift+v` — clipboard history through `cliphist`. The daemon that fills it
  is the `wl-paste --watch` line in the config.
- `Super+Tab` — fuzzy-jump to a window, the same move `room` makes inside zellij,
  one level up. It sits on Tab because that is where the mac's cmd+tab reflex
  lands; `back_and_forth` moved to `Super+grave`.

The calculator is the exception: it opens `qalc` in a floating ghostty rather than
in the launcher: a dmenu prompt only returns entries that exist in its list, so a
calculator would need a live-eval hook, and an interactive qalc keeps its history
and unit conversions on top.

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

## Why the bar runs as a systemd unit

`exec waybar` starts the bar exactly once and unsupervised. If it fails during the
cold-boot window — tray, bluetooth, pulseaudio and network all coming up in
parallel — nothing restarts it and nothing records why. That is what a reboot
eventually produced: no bar at all, no trace.

`.config/systemd/user/waybar.service` in this package replaces the packaged unit; a
user unit in `~/.config` wins over the one in `/usr/lib`. It sets `Restart=always`,
so a lost race costs two seconds instead of the session, and failures land in
`journalctl --user -u waybar`.

The duplicate bar this used to cause is gone structurally, not by masking: systemd
runs at most one instance per unit name, and the second bar came from sway's `exec`
running a loose process *beside* the packaged service. The unit here deliberately
has no `[Install]` section, so `graphical-session.target` cannot pull it up on its
own — sway starts it explicitly, chained onto
`dbus-update-activation-environment` so `WAYLAND_DISPLAY` and `SWAYSOCK` are in the
systemd environment first. Without them the bar starts blind and exits.

Because the old fix masked the unit, and a mask is a symlink sitting exactly where
this file belongs, unmask before stowing:

```sh
systemctl --user unmask waybar.service
cd ~/dotfiles && stow -R sway && systemctl --user daemon-reload
systemctl --user restart waybar.service
```

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

  The title pattern names a vendor's client, so it is **not** in this repo — it goes
  into `~/.local/share/park-vpn-title`, one line, a regex. Without that file the
  script exits and parks nothing:

  ```sh
  printf '%s\n' '^Exact Window Title' > ~/.local/share/park-vpn-title
  ```

  Make the pattern as narrow as the client allows. A bare prefix also matches
  unrelated windows — a browser tab whose page title starts with the same word gets
  parked mid-use, and re-parked on every title change.
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

Arrange the monitors and put the workspaces where they belong, then capture it once
per location:

```sh
~/.config/sway/scripts/save-displays office
~/.config/sway/scripts/save-displays home
```

**kanshi** does the rest. It watches for monitor changes and applies the matching
profile on hotplug — arriving and docking needs nothing, no reload, no command. That
is the difference to capturing into the sway config, which only took effect on
reload.

Profiles live one per file in `~/.local/share/kanshi/`, outside this repo: they
carry monitor serials, and this repo is public. `.config/kanshi/config` pulls them
in with a glob, so the two sites cannot overwrite each other.

Monitors are matched by make, model and serial rather than by connector, since
`DP-2` is a different screen at each site. The built-in panel keeps its connector
name — it has no serial and there is only one of it.

kanshi assigns no workspaces, so each profile carries `exec swaymsg` lines for that.
Watch the syntax if you edit a profile by hand: kanshi writes `position 1920,0` with
a comma, sway `position 1920 0` with a space.

## On-screen display

Volume, brightness and caps lock draw an overlay through **swayosd**, the way macOS
shows them. The bindings call `swayosd-client` instead of `wpctl` directly — it
changes the same values and draws while doing it. `swayosd-server` runs from the
config.

Should an overlay stop appearing, check the server first: without it the client
changes nothing at all, and the keys go dead rather than silent.

## Resize mode

`Super+r` enters it; inside, keys carry no modifier at all. `h/j/k/l` nudge in
steps, `2`, `3` and `4` set a half, a third or a quarter outright, `v` walks the
full cycle including 2/3 and 3/4, and `Escape` or `Return` leaves.

It replaced `Super+Control+h/j/k/l`. Two home-row mods at once is the awkward part
on the Corne, and a mode needs none — which is also why the ratios can sit on bare
digits here while outside they have to share one key and cycle.

Waybar shows the active mode on the left, and the key hints come with it: a mode's
name is what `sway/mode` prints, so the names at the top of the config carry the
list of keys. There is no second module and nothing to keep in sync beyond those
three `set` lines — but they are the one place to edit when a binding inside a mode
changes, since nothing checks that the hint still matches.

## Display mode

`Super+Shift+p` enters it. Everything display-related lives here; until now all of it was
command line only.

| key | does |
|---|---|
| `a` | switch every output back on — the way out of a dark screen |
| `e` / `d` | built-in panel on / off, the same thing the lid switch does |
| `r` | re-apply the matching kanshi profile |
| `s` | save the current arrangement under a name |

Two keys rather than one `toggle`: sway's `toggle` switches an output back on only
when it finds a stored config with `enabled == 0` and falls through to "off"
otherwise, which is what happens while no explicit `output eDP-1` line exists — so
it only ever switched off. `enable`/`disable` rather than `power`, so the panel's
windows move to a screen that is on instead of sitting on a black one;
sway-output(5) keeps them only for `power`.

If the panel goes dark again right after `e`, kanshi is applying a profile that has
`output "eDP-1" disable` in it. `grep -l disable ~/.local/share/kanshi/*` finds it.

`s` leaves the mode before opening the prompt, because a mode's bindings would
swallow the keys wofi needs for typing. Existing profile names are offered, so
overwriting one does not mean retyping it. If `save-displays` refuses — it does
while a connected monitor is dark — the reason arrives as a notification; there is
no terminal to print it to.

## System mode

`Super+Escape` enters it: `l` locks, `s` suspends, `e` ends the sway session, `r`
reboots, `p` powers off.

The last three go through `swaynag` first — each throws away unsaved work in every
open window, and a mode is a thin guard against a mistyped key. Lock and suspend
need no confirmation, since neither loses anything; suspending also needs no
explicit lock, because swayidle's `before-sleep` handler already does it.

`Hyper+l` stays as the direct way to lock — that happens several times a day and
earns its own key. Rebooting does not, so it lives only here. The former
`Super+Shift+e` for exiting is now the mode's `e`.

## Splits stay flat

New windows split in the direction of the container they join; `Super+b` and
`Super+Shift+b` set it for the next one, `Super+g` flips an existing container.

Pressing the same direction again takes it back. A pending split is a container
holding only the focused window — sway(5) says as much for `split none`, which
undoes a split "if the current container is the only child of a split parent".
While it stands, `Super+g` and `Super+v` act on that container instead of the real
one and appear to do nothing; opening a window resolves it, and so does a second
press. Pressing the *other* direction switches the pending split over rather than
nesting a second container inside it.

Nothing picks the direction automatically, and that is deliberate. **autotiling**
used to, but it nests the tree: windows end up inside sub-containers rather than as
direct children of the workspace. `layout` acts on the focused container, so
`Super+w` then tabbed a subtree and left the rest split — with three windows that
looks like a stubborn 50/50 split. The same reset also undid `Super+g` on the next
focus change. A flat tree keeps both commands acting on the whole workspace.

## Audio output

`Super+o` rotates through the outputs — headset, laptop, dock — and a middle click
on the volume pill does the same. Switching the default sink alone would leave
anything already playing on the old device, so the script moves the running streams
along with it.

## Workspace levels

Three workspaces per level: 1-3 and 4-6. Swiping left or right with **four**
fingers toggles between them — from 1 to 4, from 4 back to 1 — while three fingers
walk the workspaces within a level. `Super+1..9` still reaches every workspace
directly.

Both four-finger directions run the same toggle: with two levels there is nowhere
else to go, and a gesture that does different things depending on direction would
have to be remembered.

A gesture has to be finished by the swipe itself, which is why the window switcher
is not bound to one: it opens a picker that needs the keyboard. That stays on
`Super+Tab`.

## Known gaps

- The `privacy` module needs waybar 0.9.25; ubuntu 24.04 ships 0.9.24, where it
  never appears and waybar says nothing. `waybar --version` tells you which you have.
- `bindswitch` fires on lid *events*, not at startup. Booting docked with the lid
  already closed leaves `eDP-1` enabled behind it until the lid is toggled once.
- `scripts/park-vpn` misses a window that maps between its initial scan and its
  subscription, and its `pkill` would hit any other tool subscribing to sway events.
  Nothing else does here.

## Manually installed applications

The launcher reads `.desktop` files from `~/.local/share/applications` and
`/usr/share/applications`. Anything unpacked into `/opt` puts nothing in either and
stays invisible, so it needs an entry — `.local/share/applications/zen.desktop` is
the example, versioned here rather than written onto the machine by hand.

`StartupWMClass` matters beyond the icon: it is how sway attributes the window to
the entry, and what an `assign` rule would match on to give the browser its own
workspace.

## Window list

Tiling has no minimise — the scratchpad is the equivalent: `Super+Shift+z` parks a
window, `Super+z` brings one back, cycling through what is parked.

`wlr/taskbar` was tried as the visible counterpart and removed again — waybar
stopped starting with it. The list stays invisible.

## Laptop specifics

- Idle: lock after 5 min, screens off after 10, lock before sleep.
- Closing the lid disables `eDP-1` — check the output name with
  `swaymsg -t get_outputs` if the laptop screen does not come back.
- `XDG_CURRENT_DESKTOP=sway` is pushed into the dbus activation environment,
  otherwise screen sharing in meeting apps picks the wrong portal backend.
