---
name: pr-review
description: "Reviewing a GitHub PR and recording the verdict. Use when assessing a pull request, deciding approve vs comment vs request-changes, or (re-)requesting a reviewer. Covers the formal-approve rule, self-PR exception, and re-request etiquette."
---

# PR-Review

## Verdikt = formaler GitHub-Status, nicht nur Kommentar

Das Verdikt muss aufs Merge-Gate (CODEOWNERS / required review) zählen.

| Verdikt | Aktion |
|---|---|
| APPROVE | `gh pr review <N> --approve` (NICHT nur `--comment`) |
| COMMENT | `gh pr review <N> --comment` |
| REQUEST_CHANGES | `gh pr review <N> --request-changes` |

**Ausnahme eigene PRs:** GitHub blockt Self-Approve mit HTTP 422 → dort `--comment`
verwenden (der formale Approve kommt von einem anderen Reviewer).

Bewusst nur `--comment` ist auch für Nicht-Approve-Verdikte richtig (z. B. ein Draft,
den du noch offen lassen willst).

## Review nur (re-)requesten, wenn es etwas Neues gibt

Ein Review-Request / `--add-reviewer` ist das Signal „jetzt dran" — kein Status-Ping.

**Berechtigt:**
- (a) frischer Push, der die Findings adressiert (Re-Request nach `CHANGES_REQUESTED` —
  GitHub re-requestet da NICHT automatisch).
- (b) eine PR, auf der der Reviewer noch NICHT angefragt ist.

**Nicht taggen,** wenn er via CODEOWNERS beim PR-Open ohnehin schon in der Queue steht
und sich nichts geändert hat — das ist nur Notification-Rauschen.

Vorm Taggen prüfen:

```bash
gh pr view <N> --json reviewRequests,reviews
```

## Review-Inhalt

Für die eigentliche inhaltliche Prüfung des Diffs `/code-review` bzw. `/review` nutzen;
dieser Skill regelt das *Protokoll* drumherum.
