---
name: gate
description: "Quality gate before declaring work done or PR-ready. Use when asked 'is this ready', 'are we good', before opening a PR, or before claiming a change works. Detects which stacks changed and applies the matching stack gate (k8s, tf, go, ansible)."
---

# Quality Gate

Harte Schwelle zwischen „ich glaube es passt" und „es ist fertig". Niemals „done",
„fertig", „funktioniert" oder „PR-reif" behaupten, bevor das passende Gate **grün**
ist. Eine bestandene Aktion ≠ bestandenes Gate.

## 1. Scope bestimmen

```bash
git status -s
git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only
```

## 2. Nach Dateityp das passende Stack-Gate anwenden

| Geänderte Dateien | Gate |
|---|---|
| `*.yaml` unter charts/, `Chart.yaml`, `values*.yaml`, `kustomization.yaml`, K8s-Manifeste | `k8s` |
| `*.tf`, `*.tofu`, `*.tfvars` | `tf` |
| `*.go`, `go.mod` | `go` |
| `playbook*.yaml`, `roles/`, `inventory`, sonstiges YAML | `ansible` |

Mehrere Stacks betroffen → alle zutreffenden Gates laufen lassen.

## 3. Verdikt

- **PASS** — alle anwendbaren Checks grün. Erst jetzt „fertig" sagen.
- **FAIL** — mindestens ein Check rot → zurück zur Arbeit (kein Workaround, siehe `rca`).
- **INCONCLUSIVE** — ein Tool fehlt / Check nicht ausführbar → explizit so benennen,
  NICHT als PASS verkaufen. Robert sagen, was fehlt.

## 4. Anschluss

Grünes Gate ist Voraussetzung für `pr-flow`. Für Laufzeit-/Deploy-Aussagen
(„Komponente ist aktiv") zusätzlich `rca` (enabled-flag + live-state).
