---
name: lessons-learned
description: "End-of-session self-review: classify the session's OWN mistakes (LLM/skill/agent/tooling) and propose one prevention each on the lightest sufficient surface. Use at session end, after a visible mistake, or when asked 'was lief schief', 'lessons learned', 'retro', 'was können wir draus lernen'. NOT for runtime incidents (→ rca / incident-responder)."
---

# Lessons-Learned — aus den eigenen Fehlern lernen

Selbstreview der *eigenen Arbeit* dieser Session, nicht eines Runtime-Systems
(das ist `rca` / `incident-responder`). Ziel: die Fehler, die real passiert sind,
so festhalten, dass sie nicht wiederkehren — auf der leichtesten tragfähigen
Ebene, nicht mit einer neuen Regel pro Ausrutscher.

## 1. Belege sammeln (bounded, aus dem Transkript)

Aus dem Session-Verlauf, nicht aus dem Gedächtnis:

- **Gruppe A — deterministisch**: was nachweislich schiefging — ein Revert, ein
  gescheiterter Tool-Call den ein Blick vorher verhindert hätte, eine Rückfrage
  die im Code/Kontext schon beantwortet war, ein Fix der einen früheren Fix
  korrigierte, eine vom User widerrufene Annahme.
- **Gruppe B — Urteil**: Muster, die *wahrscheinlich* Zeit kosteten (Umwege,
  doppelte Arbeit), aber nicht hart belegbar sind.

Jede Lesson braucht einen **re-verifizierbaren Locator** — welcher Tool-Call,
welche Datei, welche User-Nachricht. Ohne Locator ist es eine **Hypothese**: so
markieren, keine Maßnahme darauf gründen.

## 2. Klassifizieren — Klasse × Subjekt

Klasse (was für ein Fehler):

- **source-hallucination** — erfundene Quelle/API/Version/Datei (z. B. eine
  Upstream-Version aus Modellwissen gepinnt statt geprüft).
- **plausibility-inference** — plausibel geraten statt verifiziert (behauptet
  „X ist deployt/aktiv/vorhanden" ohne den Live-/enabled-Check).
- **scope-conflation** — Scope vermischt, mehr gebaut als verlangt, zwei Dinge
  in einen Commit.
- **context-loss** — über Compaction / lange Session eine Vorgabe verloren,
  etwas doppelt gemacht, den Faden verloren.

Subjekt (wo sitzt die Ursache): **LLM** (mein Urteil) · **Skill** (eine Anleitung
war lückenhaft/irreführend) · **Agent** (ein Agent-Contract) · **Tooling** (ein
Hook / Script / CI-Defekt).

## 3. Prävention auf der leichtesten Ebene

Pro Fehler **eine** Maßnahme — die leichteste, die greift:

1. **Memory-Eintrag** (Default) — Fakt/Feedback ins Projekt-Memory
   (`~/.claude/projects/<projekt>/memory/`), Frontmatter + `MEMORY.md`-Pointer
   nach der etablierten Konvention (System-Prompt-Regeln / Skill `second-brain`
   fürs Second Brain). „Nächstes Mal so": `type: feedback` mit **Why** +
   **How to apply**.
2. **description-Fix** — hat ein Skill/Agent falsch (nicht) getriggert, dessen
   `description:` schärfen, damit das Routing stimmt.
3. **Contract-Zeile** — tat ein Skill/Agent das Falsche, eine gezielte Zeile im
   Body (MUST / MUST-NOT), kein Umbau.
4. **CLAUDE.md-Konvention** — nur wenn es projektübergreifend und dauerhaft gilt.
   Immer geladen, also teuer — letzte Wahl, nicht erste.

Höher als nötig steigen ist genau der Fehler, den dieser Skill vermeiden soll.

## 4. Freigabe + Grenzen

- **Nichts ungefragt schreiben.** Erst die Liste vorlegen (Fehler → Klasse →
  Subjekt → Locator → Ebene → Maßnahme), dann pro Item auf Freigabe warten.
- **Security-Klasse nur anzeigen, nie auto-draften**: Änderungen an Hooks,
  `settings.seed.json`, den Guards, THREAT-MODEL → als Befund benennen, den Edit
  Robert überlassen.
- **Edits an der immer-geladenen Fläche** (Agent-Contracts, CLAUDE.md) vor dem
  Anwenden gegenlesen lassen — `/code-review`, bei Sicherheitsrelevanz `/wargame`.
- Kein Locator → Hypothese, keine Maßnahme darauf.

## 5. Output

Eine knappe Tabelle: Fehler · Klasse · Subjekt · Locator · Ebene · Maßnahme
(ein Satz). Danach: welche Items Robert freigibt → erst dann anwenden.
