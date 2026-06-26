# Global Claude-Code Memory

Globale Konventionen + Pointer, die über alle Projekte hinweg gelten.

## Arbeitskonventionen

- **Immer ein Issue zu einem PR.** Vor jedem PR ein GitHub-Issue aufmachen (Intent/Context/Acceptance), der PR referenziert es (`Closes #N`). Gilt projektübergreifend, nicht nur bei Repos mit explizitem Issue-Workflow.
- **Source-Code + Code-Kommentare immer Englisch.** Auch Inline-Kommentare, Variable-Descriptions, Manifest-Kommentare. Nur reine Doku/Prosa darf lokalisiert sein. **company-Talos-Plattform speziell:** nur `platform-docs` bleibt komplett deutsch; alle anderen Repos (`platform-base`, `platform-apps`, `seeder-cluster`, `talos-lab-cluster`) sind durchgängig englisch (Code UND Doku/READMEs). colleague weist base-PRs mit deutschen Kommentaren ab.
- **GitHub-Issues auf „in progress" setzen, sobald sie angefasst werden.** Wenn ich an einem Issue zu arbeiten beginne (Code/PR dafür, Triage, aktive Bearbeitung), setze ich es auf „in progress" — Projects-Board-Status falls vorhanden, sonst ein `status: in-progress`-Label (analog zu `status: triage`/`status: ready`). Gilt projektübergreifend.
- **Bei Fehlern/Incidents: Ursachenanalyse vor Aktion — NICHT raten.** Kein trial-and-error (Restart, Neuversuch, Workaround, „probier mal X") bevor die Root-Cause durch Evidenz belegt ist. Vorgehen: Symptom exakt erfassen → Hypothese → gezielter Test/Isolation/Logs/Status, der die Hypothese be- oder widerlegt → erst nach belegter Ursache den Fix. Variablen einzeln isolieren (z. B. ist es app- oder infra-weit?), nicht mehrere Dinge gleichzeitig neustarten. Logs/Tool-eigene Diagnose (`*-dbg`, `monitor`, `status`, drop-reasons) zuerst lesen, nicht in Low-Level-Internals raten. Gilt projektübergreifend.
- **Approve-Verdikt = formales GitHub-Approve, nicht nur Kommentar.** Immer wenn ich ein PR mit „APPROVE" beurteile, setze ich auch den GitHub-Review-Status (`gh pr review <N> --approve`), nicht nur einen `--comment` — sonst zählt es nicht aufs Merge-Gate (CODEOWNERS/required review). Ausnahme: eigene PRs blockt GitHub mit HTTP 422 beim Self-Approve → dort `--comment` (der formale Approve kommt von einem anderen Reviewer). Bewusst nur-`--comment` ist für NICHT-Approve-Verdikte (COMMENT/REQUEST_CHANGES, z. B. ein Draft den ich noch offen lassen will). Gilt projektübergreifend.
- **Review nur (re-)requesten, wenn es etwas Neues für den Reviewer gibt.** Ein Review-Request/`--add-reviewer` ist ein Signal „jetzt dran" — kein Status-Ping. Berechtigt: (a) ein frischer Push, der die Findings adressiert (Re-Request nach `CHANGES_REQUESTED` — GitHub re-requestet da NICHT automatisch); (b) eine PR, auf der der Reviewer noch NICHT angefragt ist. NICHT taggen, wenn er via CODEOWNERS beim PR-Open ohnehin schon als Reviewer in der Queue steht und sich nichts geändert hat — das ist nur redundantes Notification-Rauschen. Vor dem Taggen prüfen, ob er schon angefragt ist (`gh pr view --json reviewRequests,reviews`). Gilt projektübergreifend.
- **Immer in Git-Worktrees committen, NIE im Hauptcheckout.** Robert hat häufig mehrere Sessions parallel offen → der Hauptcheckout eines Repos hängt meist auf einem fremden Feature-Branch mit uncommitteter WIP. Darum vor JEDEM Commit/Branch nicht den Hauptcheckout-Branch annehmen: `git fetch origin <ziel>` → `git worktree add <tmp> origin/<ziel> -b <branch>` (Ziel i. d. R. `main`), dort arbeiten/committen/pushen/PR, danach `git worktree remove --force <tmp>` + `git worktree prune`. Den Hauptcheckout NIE wechseln/stashen/resetten (zerstört die Arbeit der Parallel-Session). Vor dem Worktree-Anlegen den aktuellen Branch + `git status` des Hauptcheckouts prüfen, um die fremde WIP zu erkennen. Live-Cluster-Aktionen (sops-d|kubectl apply etc.) laufen branch-unabhängig und können aus dem Worktree erfolgen. Gilt projektübergreifend.
- **„Vorhanden/aktiv" erst behaupten nach Verifikation des enabled-Flags + (wenn erreichbar) des Live-States — Config-Sektion ≠ deployt.** Nie aus einer gerenderten Config-Sektion, einem Default-Wert oder einer referenzierenden URL (`*_url`, `alertmanager_url`, ein gesetzter Endpoint, ein `[[plugin]]`-Block …) schließen, dass eine Komponente/ein Feature deployt/aktiv ist. Eine Config, die auf etwas zeigt, beweist NICHT, dass das Ziel läuft. Immer den maßgeblichen Schalter prüfen — Helm-`<component>.enabled`, Replica-Count, `--<feature>-bind-address`/`--metrics-bind-address`, CRD-`spec.enabled` — UND, wenn ein Cluster/Tool erreichbar ist, den tatsächlichen Zustand (`kubectl get pods/svc -n <ns>`, `helm get values`, Status-Conditions). Konkreter Anlass: ich hatte „Mimir hat den Alertmanager dabei" aus dem gerenderten `alertmanager:`-Block + `ruler.alertmanager_url` geschlossen — tatsächlich war `alertmanager.enabled: false` (Katalog), kein AM-Pod. Eine darauf gebaute Entscheidung war falsch. Gilt projektübergreifend.
- **Multi-Step-Arbeit mit Todo-Listen führen; vor jedem Todo-Item nach Möglichkeit ein Context-Compact.** Bei jeder Aufgabe mit mehr als einem Schritt eine Todo-Liste anlegen + pflegen (TaskCreate/TaskUpdate: Item beim Start auf `in_progress`, nach Abschluss auf `completed`; pro Item EIN Fokus) — gibt Robert den Überblick und hält den Fokus (Gegenmittel gegen das „Auseinanderlaufen" über lange + parallele Sessions). **Vor dem Start jedes Todo-Items nach Möglichkeit ein Context-Compact ausführen**, damit der Kontext schlank bleibt und der Fokus aufs aktuelle Item liegt; wo ein echtes Compact nicht selbst auslösbar ist, mindestens an jeder Todo-Grenze einen knappen Stand-Checkpoint emittieren (was fertig / was als Nächstes) — so ist die Compaction-Grenze sauber. Gilt projektübergreifend.
- **🚫 ABSOLUT: NIEMALS mit GitHub-Repos interagieren, in denen Robert nicht Member ist.** Kein PR, kein Issue, kein Kommentar, kein Review, kein Fork, kein Branch/Push — KEINE schreibende oder kommunizierende Aktion auf Repos außerhalb der Orgs, in denen Robert Mitglied ist (`company` und explizit bestätigte weitere). Upstream/öffentliche Repos (`grafana-community`, `goharbor`, `helm.goharbor.io`, jedes Drittanbieter-Chart/-Projekt) sind **reine Lese-/Pull-Quellen** (`helm pull`, `clone`, `gh ... view/list`, read) — niemals Ziel einer Aktion. Upstream-Fixes/Beiträge NUR nach ausdrücklicher, fallweiser Freigabe durch Robert, nie eigenmächtig in seinem Namen. Vor jeder `gh pr/issue/api`-Schreibaktion das `--repo`-Ziel prüfen: beginnt es nicht mit einer Robert-Org → ABBRUCH + nachfragen. Auslöser: ein eigenmächtiger PR `grafana-community/helm-charts#637` in Roberts Namen. Keine Ausnahme, projektübergreifend.

## Second Brain (Obsidian-Vault, PARA-Struktur)

**Pfad:** `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Second Brain/`

Persönlicher Obsidian-Vault, iCloud-synced (Mobile + Desktop). PARA-Methode (Tiago Forte). Wenn der User „mein Second Brain", „pack das ins Wissen" oder ähnlich sagt: hier ablegen.

### Struktur (PARA + Inbox + Meta)

| Ordner | Zweck |
|---|---|
| `00_Inbox/` | Schnellnotizen, ungesortet |
| `01_Projects/<Domain>/` | Klares Outcome + Deadline |
| `02_Areas/<Domain>/` | Laufende Verantwortung (kein Endpunkt) |
| `03_Resources/<Topic>/` | Themen-Wissen, projektunabhängig — **hier Tool-Wissen ablegen** |
| `04_Archive/<Domain>/` | Inaktiv / abgeschlossen |
| `90_Meta/` | Templates + Dashboards |
| `99_Attachments/` | Bilder, PDFs |

Domain-Unterordner: `beruf | client | privat | hobby` in `01_/02_/04_`. In `03_Resources/` themenorientiert (`Tech/Kubernetes/`, `Tech/IaC/`, `Tech/Observability/`, `Lichttechnik/`, `AoS/`, `Personen-CRM/`, …).

### Konvention für Notizen

Frontmatter:

```yaml
---
type: projekt | notiz | meeting | person | retro | daily | moc | dashboard
tech: [optional, falls Tech-Notiz]
tags: [frei, lowercase, kebab-case]
created: YYYY-MM-DD
quelle: woher das Wissen kommt
---
```

- Markdown-Format mit Obsidian-Wiki-Links `[[Andere Notiz]]`.
- Dateinamen kebab-case bzw. konsistent zum existierenden Ordner-Stil.
- Bei Tool-/Konzept-Wissen: generisch halten, keine projektspezifischen IPs/Namen/Topologien — die gehören in projekt-spezifische Memory oder Repo-Docs.
- Bestehende Notizen vor Anlegen prüfen (`ls 03_Resources/Tech/<Topic>/`) — eher erweitern als duplizieren.

### Trennung Tool-Wissen ↔ Projekt-Wissen

- **Second Brain** = generisches Tool-/Konzept-Wissen, „wie funktioniert X".
- **Projekt-Memory** (`~/.claude/projects/<projekt>/memory/`) = projektspezifische Entscheidungen, Topologien, Werte.
- **Repo-Docs / ADRs** = Entscheidungs-Historie pro Projekt.

Beim Ablegen also fragen: ist das Wissen über das Tool selbst oder über meinen konkreten Einsatz? Tool → Second Brain, Einsatz → Projekt-Memory.
