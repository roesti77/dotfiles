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

Das Skript kommt über den `hooks`-Symlink mit `task setup`. Die **Verdrahtung**
(macos-notify nur bei `Stop`) ist in `claude/.claude/settings.seed.json`
deklariert und landet beim Bootstrap in der app-verwalteten
`~/.claude/settings.json`. Modell + Bootstrap-Schritt (`cp seed → settings.json`,
supacode injiziert seine Hooks live, bewusste Änderungen in die seed zurückfalten)
stehen in `claude/README.md` — hier nicht duplizieren.

## Erststart nach dem Merge

```sh
cd ~/dotfiles && task setup
```

Dann eine frische Zellij-Session starten (zellaude/Layout laden beim Start).
`settings.json` per seed bootstrappen, falls nötig (siehe `claude/README.md`).
