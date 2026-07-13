# Zellij-Worktree-Workflow (Supacode-Ersatz)

Dieser Workflow bildet die Supacode-Orchestrierungsebene in Ghostty + Zellij nach.
Grundmodell bleibt **ein git-Worktree = eine Zellij-Session**. Supacode selbst
(Package + Hooks) bleibt koexistent installiert; die hier beschriebenen Bausteine
sind außerhalb von Supacode aktiv und innerhalb inaktiv.

| Supacode-Feature | Ersatz |
|---|---|
| ⌘N neuer Worktree, Archive | `wt new` / `wt done` |
| ⌘P / ⌃1-⌃0 Worktree-Switching | `zj-sessionizer` auf `Ctrl f` |
| GitHub-Sidebar (PRs/Checks) | gh-dash-Pane im `dev`-Layout + Pane-Mode `g` |
| Statusbar | compact-bar (Default) bzw. optional zjstatus |
| Agent-Badges/Sounds | Claude-Code-Hook `macos-notify.sh` |
| Session-Persistenz (zmx) | Zellijs `session_serialization` (bereits aktiv) |

## Worktrees: `wt`

```sh
wt new <branch> [repo-pfad]   # Worktree von origin/main + Session öffnen
wt done                       # Worktree, Branch und Session aufräumen
wt list                       # Worktrees + Session-Status
```

- Worktree-Pfad: `~/worktrees/<repo>/<branch>`, Session-Name: `<repo>-<branch>`
  (Sonderzeichen im Branch werden zu `-`).
- Ohne `repo-pfad` wird das Repo des aktuellen Verzeichnisses genommen.
- `wt done` bricht bei uncommitteten Änderungen ab und löscht die eigene Session
  zuletzt (kappt dabei die laufende Shell — gewollt, wie Supacodes Archive).

## Switching: `Ctrl f`

`Ctrl f` öffnet den Sessionizer (fzf) in einer Floating Pane: Auswahl aus
laufenden Sessions, `~/repos/*/*` und `~/worktrees/*/*`. Innerhalb von Zellij
wird über das `zellij-switch`-Plugin gewechselt (nested `attach` ist unmöglich),
außerhalb via `attach --create`.

## PR-Status: gh-dash

- Das `dev`-Layout (Default) hat auf dem ersten Tab eine permanente gh-dash-Pane
  (25% rechts). Neue Tabs bleiben ohne Sidebar.
- In anderen Tabs: Pane-Mode (`Ctrl p`) dann `g` öffnet gh-dash on-demand rechts.
- gh-dash ist cwd-unabhängig; die angezeigten Queries stehen in
  `~/.config/gh-dash/config.yml` (Default: `is:open involves:@me`).
- Nach einer wiederhergestellten Session (Serialization) steht die gh-dash-Pane
  suspendiert da („Press Enter to re-run") — ein Tastendruck startet sie neu.

## Statusbar: zjstatus (optional)

Standard ist die `compact-bar` (Layout `dev`). Optional gibt es die Variante
`dev-zjstatus` (Layout `dev-zjstatus.kdl`) mit zjstatus: Mode, Session, Tabs,
PR-State des fokussierten Panes und Uhrzeit.

Umschalten / Rückbau über `default_layout` in `config.kdl`:

- `default_layout "dev-zjstatus"` — zjstatus-Bar + Sidebar
- `default_layout "dev"` — compact-bar + Sidebar
- `default_layout "compact"` — Stock, keine Sidebar

Der zjstatus-Teil liegt bewusst in einer eigenen Layout-Datei, damit ein
`git revert` des zjstatus-Commits (oder ein `default_layout`-Flip) die
Sidebar-Konfiguration unangetastet lässt.

## Notifications: `macos-notify.sh`

Der Hook feuert bei den Claude-Code-Events `Notification` (Agent wartet auf
Input) und `Stop` (Agent fertig) ein macOS-Banner mit Sound; der Zellij-Session-
Name steht im Titel. Innerhalb von Supacode ist der Hook ein No-op
(`SUPACODE_SOCKET_PATH` / Bundle-ID), damit keine doppelten Benachrichtigungen
entstehen.

Das Skript selbst kommt über den `hooks`-Symlink automatisch mit `task setup`.
Die **Verdrahtung** muss dagegen von Hand in die app-verwaltete
`~/.claude/settings.json` (siehe unten) — einmal pro Maschine, idempotent:

```sh
tmp=$(mktemp)
jq '
  (.hooks.Notification //= []) | (.hooks.Stop //= []) |
  .hooks.Notification |= (if any(.[].hooks[]?; .command | test("macos-notify")) then . else . + [{"hooks":[{"type":"command","command":"bash ~/.claude/hooks/macos-notify.sh","timeout":10}]}] end) |
  .hooks.Stop |= (if any(.[].hooks[]?; .command | test("macos-notify")) then . else . + [{"hooks":[{"type":"command","command":"bash ~/.claude/hooks/macos-notify.sh","timeout":10}]}] end)
' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
```

Schreibt Claude Code / Supacode die Datei neu und entfernt dabei den Eintrag,
das Snippet einfach erneut ausführen.

## settings.json ist app-verwaltet

`~/.claude/settings.json` wird von Claude Code und Supacode zur Laufzeit neu
geschrieben (Format + agent-integration Hooks). Sie ist daher bewusst **nicht**
gestowt (`claude/.stow-local-ignore` schließt sie aus), sondern bleibt eine
echte, app-verwaltete Datei. Eigene Hooks werden wie oben in die Live-Datei
gemergt, nicht ins Repo committet. Der Rest des `claude`-Packages (`agents`,
`hooks`, `skills`, `CLAUDE.md`, …) wird normal gestowt.

## Erststart nach dem Merge

```sh
cd ~/dotfiles && task setup   # foldet ~/bin, installiert gh-dash
```

Anschließend eine frische Zellij-Session starten (nicht eine wiederhergestellte),
damit das `dev`-Layout greift.
