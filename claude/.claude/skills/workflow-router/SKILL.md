---
name: workflow-router
description: "Ermittelt den passendsten Multi-Agent-Workflow für eine Aufgabe (decision, sdd-plan, wargame, pr-review-deep, audit, rca-fleet) — oder sagt, dass keiner passt. Use when unsure which workflow/skill fits, when asked 'womit angehen', 'welcher workflow', or before opting into a heavy multi-agent run."
---

# Workflow-Router — welches Verfahren passt?

Vor jedem Multi-Agent-Lauf: das *passendste* Verfahren wählen, nicht das
erstbeste. Dieser Skill **empfiehlt nur** — er startet nichts. Workflows spawnen
viele Agenten und sind Opt-in; die Wahl trifft am Ende Robert.

## 1. Kern-Achse: In welchem Zustand ist die Arbeit?

Die sechs Verfahren unterscheiden sich am Zustand des Artefakts, nicht am Thema.
Erst diese Frage beantworten, dann Zeile lesen:

| Zustand der Arbeit | Verfahren | Was es tut |
|---|---|---|
| Mehrere Optionen, noch nichts gewählt („A oder B?", go/no-go) | **decision** | steelman ↔ devil je Option → judge empfiehlt |
| Spec existiert, Umsetzungsplan muss her/geprüft werden | **sdd-plan** | plan → parallele Kritik-Lenses (spec-coverage, risk, simplicity) → synth |
| *Eine* Lösung/Plan/Design gewählt, Schwächen suchen (pre-mortem) | **wargame** | red greift an → blue verteidigt → white rult → loop → purple-Backlog |
| Konkreter Code-Diff / PR liegt vor | **pr-review-deep** | parallele Review-Dimensionen → jedes Finding adversariell widerlegen |
| Bestehendes K8s/IaC-System prüfen (config-vs-live, drift, security) | **audit** | multi-modaler Sweep → Live-State-Verifikation der „deployt"-Claims |
| Etwas ist kaputt, Ursache unbekannt, Raten ist teuer | **rca-fleet** | konkurrierende Hypothesen → je isoliert testen → auf Ursache konvergieren |

Kein Treffer → **kein Workflow** (siehe §4).

## 2. Verwechselbare Paare abgrenzen

- **decision vs. wargame** — mehrere Optionen *fair vergleichen* (decision) vs. *eine
  bereits gewählte* Lösung auf Bruchstellen stressen (wargame). Wählen ≠ härten.
- **wargame vs. pr-review-deep** — Plan/Design/Spec *vor* dem Bauen angreifen (wargame,
  pre-mortem) vs. *fertigen Code-Diff* auf Bugs/Security/Konventionen prüfen (pr-review-deep).
- **sdd-plan vs. wargame** — *einen* Plan gegen die Spec auf Lücken kritisieren (sdd-plan,
  konstruktiv) vs. einen Plan adversariell brechen (wargame, gegnerisch).
- **audit vs. pr-review-deep** — *bestehendes* System / Repo-Stand als Ganzes (audit,
  inkl. Live-Cluster) vs. *die Änderung* eines Diffs/PRs (pr-review-deep).
- **rca-fleet vs. audit** — *ein akuter Fehler* mit unbekannter Ursache (rca-fleet,
  diagnostisch) vs. *proaktive* Bestandsaufnahme ohne konkreten Incident (audit).

## 3. Light vs. Heavy

`decision` und `wargame` gibt es als **Skill** (leicht, sequenziell) *und* als
**Workflow** (schwer, parallel, Schema-Outputs). Faustregel:

- Kleiner Umfang / wenige Optionen / kurzer Plan → **Skill** (`Skill(decision)` / `Skill(wargame)`).
- Viele Optionen, großes Target, viele Findings pro Runde, „gründlich"/„ultracode" → **Workflow**.

`sdd-plan`, `pr-review-deep`, `audit`, `rca-fleet` sind reine Workflows.

## 4. Wann GAR kein Workflow

Workflows sind Fan-out mit Kosten — nicht der Default. Kein Workflow, wenn:

- **Ein Agent reicht** — eine fokussierte Frage/Aufgabe → direkt der passende Agent
  (`dean` fürs Debuggen, `castiel` fürs Planen, `code-quality-pragmatist` /
  `/simplify` für Over-Engineering, `/code-review` für den eigenen Diff).
- **Trivial/mechanisch** — kurze Edits, Doku, Dep-Bumps → inline erledigen.
- **Es gibt einen spezifischeren Skill** — Qualitäts-Gate → `gate`; PR öffnen →
  `pr-flow`; Version pinnen → `upstream-version`; Wissen ablegen → `second-brain`.

## 5. Bericht

Ein Verfahren (oder „keins") empfehlen, **mit Begründung über die Zustands-Achse**,
und den konkreten Aufruf angeben — z. B.:

```
Workflow(name: "rca-fleet", args: { symptom: "…", maxRounds: 3 })
Workflow(name: "decision", args: { decision: "…", options: ["A","B"], criteria: ["…"] })
Workflow(name: "pr-review-deep", args: "42")   // oder "working" für den uncommitteten Diff
```

Bei echter Mehrdeutigkeit (zwei Verfahren plausibel) nicht raten — die
unterscheidende Frage an Robert stellen (z. B. „gewählte Lösung härten oder noch
zwischen Optionen wählen?"). Die Empfehlung ist Rat, kein Mandat: den Workflow
erst nach Roberts Opt-in starten.
