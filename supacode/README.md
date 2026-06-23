# supacode

Stow-Package für [supacode](https://supacode.sh/) — native macOS-GUI-App auf Basis von
*libghostty*, die mehrere Coding-Agents parallel in isolierten git-worktrees orchestriert.
Voraussetzung: macOS 26 Tahoe.

## Integrationsmodell: supacode *über* zellij, nicht statt zellij

Tabs/Panes laufen weiterhin ausschließlich über zellij. supacode übernimmt nur die Ebene
darüber:

| Ebene | Tool | Verantwortung |
|---|---|---|
| Orchestrierung | **supacode** | Welcher Worktree / welcher Agent? Parallele Agents, PR-Status, Notifications |
| Multiplexing *innerhalb* eines Worktrees | **zellij** | Tabs + Panes + neovim — unverändertes Setup |

Regel: **ein supacode-Worktree = eine zellij-Session.** supacodes eigene Splits/Tabs werden
nicht genutzt. Konfliktfrei, weil supacode Cmd-basiert ist und zellij unter `Ctrl-g` läuft.

Das `templates/supacode.json` setzt das um: `setupScript`/`runScript` hängen sich beim
Worktree-Erstellen bzw. per `⌘R` in eine nach dem Worktree benannte zellij-Session, der
`archiveScript` räumt sie beim Archivieren wieder ab.

## Terminal-Config kommt aus ghostty

supacode rendert über GhosttyKit und liest die **bestehende ghostty-Config** (Theme, Font,
Keybinds) — die ist bereits über das `ghostty`-Package gestowt. Es gibt daher hier bewusst
*keine* eigene Terminal-/Keybind-Config.

## Tastatur (keyboard-only)

| Aktion | Shortcut |
|---|---|
| Command Palette | `⌘P` |
| Neuer Worktree (Branch + worktree) | `⌘N` |
| Worktree direkt anspringen | `⌃1` … `⌃0` |
| Nächster / vorheriger Worktree | `⌃⌘↓` / `⌃⌘↑` |
| Run-/Setup-Script starten / stoppen | `⌘R` / `⌘.` |
| Sidebar togglen | `⌘[` |
| PRs öffnen | `⌃⌘G` |

`⌃1`–`⌃0` greift supacode auf App-Ebene ab, *bevor* zellij sie sieht. Da zellijs
Tab-Navigation unter dem `Ctrl-g`-Leader liegt (nicht rohes `Ctrl+Ziffer`), kollisionsfrei —
beim ersten Test einmal verifizieren.

## Installation / stow

```sh
cd ~/dotfiles
stow -t ~ supacode
```

Das verlinkt `~/.supacode/templates/supacode.json` (per-repo-Vorlage, s.u.).

### settings.json — app-verwaltet, per --adopt einbinden

`~/.supacode/settings.json` ist **kein handgepflegtes File**: die App schreibt dort laufend
State rein (`global`-Preferences, aber auch maschinenlokales wie `repositories`,
`repositoryRoots`, `pinnedWorktreeIDs`, Reihenfolgen, lastFocused). Daher nicht vorab von
Hand schreiben, sondern nach dem ersten Start adoptieren:

```sh
# 1. supacode einmal starten, im GUI Preferences setzen
#    (Notifications an, Default-Editor = nvim, Update-Channel …), dann beenden.
# 2. Die von der App erzeugte settings.json ins Package ziehen + zurückverlinken:
cd ~/dotfiles
stow -t ~ --adopt supacode
# 3. git diff prüfen: nur portable Keys behalten, maschinenlokalen State ggf. zurücksetzen.
git -C ~/dotfiles add -p supacode
```

Hinweis: Da die App durch den Symlink hindurch schreibt, dirtyt sie das Repo bei Nutzung.
Vor dem Commit gezielt `git add -p` nutzen und maschinenlokale Keys auslassen.

## Per-repo Setup (zellij-Integration)

Die zellij-Anbindung gehört pro Projekt in eine `supacode.json` im jeweiligen Repo-Root
(nicht ins dotfiles-Repo). Vorlage liegt unter `~/.supacode/templates/supacode.json`:

```sh
cp ~/.supacode/templates/supacode.json /pfad/zum/projekt/supacode.json
```

Anschließend `setupScript`/`runScript`/`openActionID` pro Projekt anpassen (z. B. zusätzlich
`pnpm install` im setupScript).
