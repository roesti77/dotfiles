# Claude Code in Zellij

Arbeitsmodell: **ein Tab pro Claude-Session** in einer Zellij-Session. Supacode
selbst (Package + Hooks) bleibt koexistent installiert; die hier beschriebenen
Bausteine sind außerhalb von Supacode aktiv und innerhalb inaktiv.

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
