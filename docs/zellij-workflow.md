# Claude Code in Zellij

Arbeitsmodell: **ein Tab pro Claude-Session** in einer Zellij-Session. Supacode
selbst (Package + Hooks) bleibt koexistent installiert; die hier beschriebenen
Bausteine sind außerhalb von Supacode aktiv und innerhalb inaktiv.

## Tab-Status: zellaude

[zellaude](https://github.com/ishefi/zellaude) (v0.5.1, vendored) ersetzt die
Tab-Bar und zeigt pro Tab den Claude-Code-Status — thinking, running bash,
editing, waiting for permission (⚠), waiting for prompt (▶), done (✓), idle (○).
So sieht man auf einen Blick, welche Claude-Session in welchem Tab worauf wartet.
Gesetzt über `default_layout "zellaude"` (Layout `layouts/zellaude.kdl`).

Beim ersten Laden schreibt das Plugin selbst `~/.config/zellij/plugins/zellaude-hook.sh`
und registriert den Hook in der app-verwalteten `~/.claude/settings.json`. Diese
plugin-generierten Dateien (`zellaude-hook.sh`, `zellaude.json`) sind in
`.gitignore`, da sie durch den stow-Symlink im Repo landen würden. Laufzeit-Deps:
`jq`; optional `terminal-notifier` für click-to-focus-Notifications.

**Aktivierung:** eine frische Zellij-Session starten (Plugin/Layout laden beim
Session-Start). Voraussetzung Kompatibilität: zellaude v0.5.1 ist gegen
`zellij-tile 0.43.1` gebaut = unsere Zellij-Version.

### Review-Tab

`review` (Alias in `.zshrc`) öffnet per `zellij action new-tab --layout review`
einen Tab mit nvim (Diff/Review, 55%) neben Claude Code + Shell (45%), Layout
`layouts/review.kdl`. Nutzt dieselbe zellaude-Bar wie das Default-Layout, sodass
mehrere Review-Tabs oben ihren jeweiligen Claude-Status zeigen.

## Notifications: `macos-notify.sh`

Der Hook feuert bei `Stop` (Agent fertig) ein macOS-Banner mit Sound; der
Zellij-Session-Name steht im Titel. Permission-/Waiting-Meldungen übernimmt
**zellaude** (Bar-Symbol + eigenes Banner), daher ist der `Notification`-Zweig
bewusst **nicht** verdrahtet — sonst doppelte Banner. Innerhalb von Supacode ist
der Hook ein No-op (`SUPACODE_SOCKET_PATH` / Bundle-ID).

Das Skript selbst kommt über den `hooks`-Symlink automatisch mit `task setup`.
Die **Verdrahtung** muss dagegen von Hand in die app-verwaltete
`~/.claude/settings.json` (siehe unten) — einmal pro Maschine, idempotent:

```sh
tmp=$(mktemp)
jq '
  (.hooks.Stop //= []) |
  .hooks.Stop |= (if any(.[].hooks[]?; .command | test("macos-notify")) then . else . + [{"hooks":[{"type":"command","command":"bash ~/.claude/hooks/macos-notify.sh","timeout":10}]}] end)
' ~/.claude/settings.json > "$tmp" && cat "$tmp" > ~/.claude/settings.json && rm -f "$tmp"
```

Schreibt Claude Code / Supacode die Datei neu und entfernt dabei den Eintrag,
das Snippet einfach erneut ausführen. (Redirect statt `mv`, weil `mv` per
`common-aliases` als `mv -i` interaktiv nachfragt.)

## settings.json ist app-verwaltet

`~/.claude/settings.json` wird von Claude Code und Supacode zur Laufzeit neu
geschrieben (Format + agent-integration Hooks). Sie ist daher bewusst **nicht**
gestowt (`claude/.stow-local-ignore` schließt sie aus), sondern bleibt eine
echte, app-verwaltete Datei. Eigene Hooks werden wie oben in die Live-Datei
gemergt, nicht ins Repo committet. Der Rest des `claude`-Packages (`agents`,
`hooks`, `skills`, `CLAUDE.md`, …) wird normal gestowt.

## Erststart nach dem Merge

```sh
cd ~/dotfiles && task setup
```

Danach den Notify-Hook wie oben in die Live-`settings.json` einpflegen.
