---
name: coding-rules
description: "Style and language rules for generated code. Apply when writing or modifying code, comments, commit messages, Terraform/OpenTofu, YAML, or taskfiles."
---

# Anweisungen für Code-Generierung

## Sprache

- Code, Kommentare, Variablen-Descriptions, Commit-Messages: **immer Englisch**
- Kommunikation mit mir: Deutsch
- Niemals Sprachen innerhalb einer Datei mischen

## Kommentare

- Schreibe **keine** Kommentare die den Code wiederholen. `# Wait for cluster networking` über einem Resource-Block namens `wait_for_cluster` ist überflüssig.
- Schreibe **keine** Datei-Header-Kommentare (`# bootstrap.tf – does X`). Der Dateiname reicht.
- Schreibe **keine** Section-Separator wie `# --- Control Plane VMs ---` oder `# === Config ===`.
- Kommentare nur wenn sie das **Warum** erklären, nicht das **Was**. Gut: `# FortiGate API returns 500 if connector already exists`. Schlecht: `# Create the FortiGate SDN connector`.
- Maximal 1 Zeile pro Kommentar. Keine mehrzeiligen Erklärblöcke.

## Terraform / OpenTofu

- `description` bei Variablen **nur** wenn sie echten Mehrwert liefert. `description = "Cilium Helm chart version"` auf `variable "cilium_version"` ist wertlos — weglassen.
- Descriptions bei Outputs weglassen wenn der Output-Name selbsterklärend ist.
- Einzeilige Variablen bevorzugen wenn nur `type` gesetzt wird: `variable "cluster_name" { type = string }`
- Keine Boilerplate-Kommentare wie `# Added in later phases` oder Platzhalter für Features die noch nicht existieren.

## YAML / Taskfiles

- Task-`desc` Felder kurz halten — eine Halbzeile, keine Sätze.
- Keine Echo-Messages die erklären was als nächstes passiert (`echo "Next kubectl command will trigger re-authentication."` → weglassen oder maximal `echo "Done."`).

## Commits

- Commit-Messages knapp: Subjekt ohne Punkt, max 50 Zeichen. Kein Body nötig bei kleinen Änderungen.
- **Nicht** jeder Commit muss dem Conventional-Commit-Format folgen. `fix typo in cilium values` ist ok.
- Ein Commit = eine logische Änderung. Keine Bulk-Commits mit 15+ Dateien und 300+ Zeilen.
- Wenn ich nicht explizit nach einem Commit frage, keinen erstellen.

## Stil

- Keinen Code generieren der "zu sauber" ist. Perfekte Strukturierung, lückenlose Dokumentation und null TODOs wirken künstlich.
- Kein Over-Engineering: keine Extra-Validierungen, keine vorausschauenden Abstraktionen, keine Konfigurierbarkeit die niemand braucht.
- Bestehenden Code-Stil der Datei/des Repos übernehmen, nicht einen eigenen aufzwingen.
- Keine `Co-Authored-By` Zeilen in Commits.
