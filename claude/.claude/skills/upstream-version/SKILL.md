---
name: upstream-version
description: "Use when integrating, pinning, or bumping an external application/dependency — Helm chart, container image, operator, CRD bundle, or GitHub-released CLI/tool (e.g. ArgoCD in k8s). The model's version knowledge is stale by construction; verify the REAL current upstream version (and match any base/production parity) BEFORE pinning a version number."
---

# Upstream-Version prüfen vor dem Pinnen

Modell-Wissen zu Versionen ist **per Knowledge-Cutoff veraltet**. Eine „aus dem Kopf"
gepinnte Version ist fast immer zu alt — oft einen ganzen Major daneben. **Niemals eine
Version aus Modell-Wissen pinnen.** Vor jedem Einbinden/Bumpen einer externen Komponente
die echte aktuelle Upstream-Version abfragen und bewusst wählen.

Auslöser: PR `devobagmbh/talos-platform-apps#471` — lokales ArgoCD lief auf Chart `7.7.0`
(v2.13.0, aus Modell-Wissen), Basis/Prod auf `9.4.5` (v3.3.2). Ein ganzer Major daneben,
das E2E-Setup gegen die falsche ArgoCD-Version validiert.

## Regel (projektübergreifend)

Bei jeder Einbindung/Aktualisierung einer externen Komponente (Helm-Chart, Container-Image,
Operator, CRD-Bundle, CLI-Tool):

1. **Echte aktuelle Version abfragen** — Lookup je Quelle (unten). Nicht raten.
2. **Parität schlägt Neuheit:** Gibt es eine Referenz-Wahrheit (base-Substrat, Prod-Cluster,
   anderer Consumer), auf **die** pinnen — nicht blind aufs Neueste. (#471: der lokale Pfad
   muss die base-Version spiegeln, sonst wird gegen eine andere Major getestet.) Ohne
   Referenz → aktuelle Stable-Version.
3. **Delta zum Modell-Wissen benennen** + Quelle & Datum im PR/Commit dokumentieren
   („geprüft gegen `helm search repo` am <Datum> → X.Y.Z").

## Lookups je Quelle

```bash
# --- Helm-Chart (klassisches repo): alle Versionen + appVersion ---
helm repo add <name> <url> >/dev/null && helm repo update >/dev/null
helm search repo <name>/<chart> --versions | head          # neueste Chart-Versionen
helm show chart <name>/<chart> --version <x> | grep -E '^(version|appVersion):'

# --- OCI-Helm-Chart / OCI-Image-Tags ---
skopeo list-tags docker://<registry>/<repo> 2>/dev/null | head -40
# Alternativen: `crane ls <repo>` · `regctl tag ls <repo>`

# --- GitHub-Releases (Operator / CLI / Projekt): latest + Liste ---
gh release view --repo <owner>/<repo> --json tagName,publishedAt \
  -q '.tagName + "  " + .publishedAt'
gh release list --repo <owner>/<repo> --limit 10
# keine Releases? → Tags:
gh api repos/<owner>/<repo>/tags --jq '.[].name' | head

# --- Container-Image (Registry-Tags, semver-Sortierung grob) ---
skopeo list-tags docker://<image> 2>/dev/null \
  | python3 -c "import json,sys,re; t=json.load(sys.stdin)['Tags']; \
    print('\n'.join(sorted([x for x in t if re.match(r'^v?\d+\.\d+',x)])[-15:]))"
```

## Referenz-Wahrheit finden (für die Parität)

- **Talos-Stack:** `talos-platform-base` seedet Versionen (z. B. `argocd_chart_version`,
  Cilium-Chart im `talos-cluster`-Modul). Consumer- und lokale Pfade **müssen spiegeln** —
  vor dem Pinnen die base-Pin lesen (Modul-`ref`/`versions.tf`/Chart-Default).
- **Prod/Live:** aktuelle Version am laufenden Cluster prüfen — `helm list -A`,
  `kubectl get <res> -o jsonpath=...`, Image-Tag am Deployment.

## Verifikation vor „fertig"

- Gegen die **gewählte** Version rendern: `helm template <rel> <chart> --version <x> -f <values>`
  → auf umbenannte/entfernte Values achten (Breaking Changes v. a. bei Major-Sprüngen).
- Major-Upgrade-Fallstricke (CRD-Migration, in-place `helm upgrade` auf Live-Cluster) im
  PR ausdrücklich benennen.
- Danach das `k8s`-Gate (bzw. passendes Stack-Gate) laufen lassen.

Anschluss: `k8s` (Render-/Lint-Gate), `pr-flow` (Issue/PR — Version + Quelle + Datum in die
Beschreibung).
