---
name: pr-flow
description: "The issue-to-PR workflow. Use when opening a pull request, starting work on an issue, or creating a branch/commit for a change that will become a PR. Covers issue creation, in-progress status, worktree-based commits, conventional commits, and PR linkage."
---

# PR-Flow

Der verbindliche Ablauf von „Idee" bis „PR offen". Gilt projektübergreifend, nicht
nur bei Repos mit explizitem Issue-Workflow.

## 1. Immer ein Issue vor dem PR

Vor jedem PR ein GitHub-Issue aufmachen — auch für kleine Changes.

```bash
gh issue create --title "<knapper titel>" --body "$(cat <<'EOF'
## Intent
<warum>

## Context
<relevanter hintergrund>

## Acceptance
- [ ] <messbares kriterium>
EOF
)"
```

Der PR referenziert es später mit `Closes #N`.

## 2. Issue auf „in progress" setzen

Sobald du anfängst (Code/PR/Triage): Status auf in-progress.
- Projects-Board-Status, falls vorhanden.
- Sonst Label `status: in-progress` (analog zu `status: triage`/`status: ready`).

## 3. Im Worktree arbeiten — NIE im Hauptcheckout

Robert hat oft mehrere Sessions parallel → der Hauptcheckout hängt meist auf einem
fremden Feature-Branch mit uncommitteter WIP. Niemals den Hauptcheckout-Branch
annehmen, wechseln, stashen oder resetten.

```bash
# Erst die fremde WIP im Hauptcheckout erkennen
git -C <repo> status -sb

# Dann sauberen Worktree von origin/<ziel> (meist main)
git -C <repo> fetch origin <ziel>
git -C <repo> worktree add <tmp-pfad> origin/<ziel> -b <branch>
```

Live-Cluster-Aktionen (`sops -d`, `kubectl apply`, …) laufen branch-unabhängig und
dürfen aus dem Worktree erfolgen.

## 4. Committen

- Ein Commit = eine logische Änderung. Keine Bulk-Commits mit 15+ Dateien.
- Subjekt englisch, knapp, kein Punkt, max ~50 Zeichen. Body nur wenn nötig.
- Conventional-Commit-Format wo es passt — aber nicht erzwingen (`fix typo in cilium values` ist ok).
- Commit-Footer wie vom Harness vorgegeben anhängen.

## 5. PR öffnen

```bash
git -C <tmp-pfad> push -u origin <branch>
gh pr create --base <ziel> --title "<titel>" --body "...Closes #N"
```

Für die Review-Etikette danach: siehe Skill `pr-review`.

## 6. Worktree aufräumen

```bash
git -C <repo> worktree remove --force <tmp-pfad>
git -C <repo> worktree prune
```

## company-Talos-Spezifika

- Nur `platform-docs` ist komplett deutsch; alle anderen Talos-Repos
  (`platform-base`, `-apps`, `seeder-cluster`, `talos-lab-cluster`)
  sind durchgängig englisch (Code UND Doku/READMEs). colleague weist base-PRs mit
  deutschen Kommentaren ab.
- NIEMALS schreibend auf Repos außerhalb von Roberts Orgs (`company` + bestätigte).
  Vor jeder `gh pr/issue`-Aktion das `--repo`-Ziel prüfen.
