---
name: sdd
description: "Spec-driven development pipeline for non-trivial features and changes. Use when building something with real requirements, architecture, and quality bars (not a quick fix). Drives Spec → Plan → Implement → Gate → Verify, with the spec as source of truth. Wire in the sdd-plan workflow for heavy orchestration."
---

# Spec-Driven Development

Für alles, was *echte* Anforderungen, Architektur und Qualität braucht — nicht für
Einzeiler. Leitidee: **Die Spec ist die Source of Truth.** Code wird gegen sie gebaut
und gegen sie verifiziert; bei Drift gewinnt die Spec (oder die Spec wird bewusst
geändert), nie der Zufall.

Für größere Vorhaben das Orchestrierungs-Skript nutzen: `Workflow({name: "sdd-plan"})`
(mehrere Agenten parallel). Dieser Skill ist der manuelle, schrittweise Ablauf.

## Phase 1 — Spec (Source of Truth)

Spec-Datei aus dem Template anlegen: `.claude/template/spec.md` dieses Skills →
`docs/specs/<feature>.md` (oder Issue-Body). Verpflichtend gefüllt:
Intent, Context, Requirements, **Non-Goals**, Acceptance, Architektur-Entscheidungen.

- Vor dem Schreiben Kontext ziehen (MCP: github/bookstack/notion, vectorcode, Repo-Docs).
- Issue anlegen + auf in-progress → Skill `pr-flow`.
- **Nicht implementieren, bevor die Spec steht und unklare Punkte geklärt sind.**
  Lieber 2–3 Rückfragen als eine falsche Annahme.

## Phase 2 — Plan

Spec in einen Umsetzungsplan zerlegen. Bei Mehrdeutigkeit/Breite den Planer-Agenten
nehmen:

```
Agent(subagent_type: "castiel", prompt: "<spec> → schrittweiser Implementierungsplan,
kritische Dateien, Architektur-Trade-offs")
```

Plan referenziert konkrete Dateien + Reihenfolge. Risiken/Annahmen explizit.

## Phase 3 — Implement

Im Worktree gegen Plan + Spec umsetzen (`pr-flow`, NIE Hauptcheckout). Pro logischem
Schritt ein Commit. Code/Kommentare englisch (`coding-rules`). Keine Features bauen,
die nicht in der Spec stehen (Non-Goals respektieren).

## Phase 4 — Gate

Quality-Gate für den geänderten Stack: Skill `gate` (→ `k8s` / `tf` / `go` / `ansible`).
Rot → zurück zur Arbeit nach `rca` (Ursache vor Aktion, kein Workaround). Erst grün
weiter.

## Phase 5 — Verify gegen die Spec

Unabhängig prüfen, ob die Implementierung die Spec *tatsächlich* erfüllt — nicht nur
ob es kompiliert:

```
Agent(subagent_type: "sam",   prompt: "Verifiziere Implementierung gegen <spec> —
  Lücken zwischen Requirements/Acceptance und Code?")
Agent(subagent_type: "bobby", prompt: "Ist das wirklich fertig oder nur scheinbar?
  Was fehlt zur Acceptance?")
```

Für Laufzeit-/Deploy-Aussagen zusätzlich `rca` (enabled-flag + live-state, nie aus der
Config schließen).

## Phase 6 — PR

Erst nach grünem Gate + bestandener Verifikation: PR via `pr-flow` (`Closes #N`),
Spec im PR verlinken. Review-Etikette → `pr-review`.

## Disziplin

- Jeder Schritt hat ein Artefakt (Spec, Plan, Diff, Gate-Report, Verify-Verdikt).
- Bei jeder Todo-Grenze ein Stand-Checkpoint (fertig / als Nächstes).
- Acceptance-Kriterien sind die Definition von „done" — nichts anderes.
