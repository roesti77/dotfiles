---
name: second-brain
description: "File knowledge into Robert's Obsidian PARA vault. Use when asked to save something to 'mein Second Brain', 'pack das ins Wissen', or to capture tool/concept knowledge for later reference."
---

# Second Brain — Capture

Persönlicher Obsidian-Vault, iCloud-synced (Mobile + Desktop), PARA-Methode.

**Pfad:** `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Second Brain/`

## Wo ablegen? (PARA)

| Ordner | Zweck |
|---|---|
| `00_Inbox/` | Schnellnotizen, ungesortet |
| `01_Projects/<Domain>/` | Klares Outcome + Deadline |
| `02_Areas/<Domain>/` | Laufende Verantwortung (kein Endpunkt) |
| `03_Resources/<Topic>/` | Themen-/Tool-Wissen, projektunabhängig |
| `04_Archive/<Domain>/` | Inaktiv / abgeschlossen |
| `90_Meta/` | Templates + Dashboards |
| `99_Attachments/` | Bilder, PDFs |

- Domain-Unterordner in `01_/02_/04_`: `beruf | privat | hobby`.
- In `03_Resources/` themenorientiert (`Tech/Kubernetes/`, `Tech/IaC/`,
  `Tech/Observability/`, `Lichttechnik/`, `AoS/`, `Personen-CRM/`, …).

## Entscheidung: Tool-Wissen vs. Projekt-Wissen

Fragen: ist das Wissen über das **Tool selbst** oder über **Roberts konkreten Einsatz**?
- Tool/Konzept („wie funktioniert X") → **Second Brain** (`03_Resources/`), generisch
  halten, keine projektspezifischen IPs/Namen/Topologien.
- Projektspezifische Entscheidung/Topologie/Werte → **Projekt-Memory**
  (`~/.claude/projects/<projekt>/memory/`).
- Entscheidungs-Historie pro Projekt → **Repo-Docs / ADRs**.

## Frontmatter

```yaml
---
type: projekt | notiz | meeting | person | retro | daily | moc | dashboard
tech: [optional, falls Tech-Notiz]
tags: [frei, lowercase, kebab-case]
created: YYYY-MM-DD
quelle: woher das Wissen kommt
---
```

## Konventionen

- Markdown mit Obsidian-Wiki-Links `[[Andere Notiz]]`.
- Dateinamen kebab-case, konsistent zum existierenden Ordner-Stil.
- Bestehende Notizen vorm Anlegen prüfen (`ls 03_Resources/Tech/<Topic>/`) — eher
  erweitern als duplizieren.
