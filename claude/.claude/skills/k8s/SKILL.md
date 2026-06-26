---
name: k8s
description: "Quality gate for Kubernetes / Helm / GitOps (ArgoCD) / Talos changes. Use before declaring Helm charts, values, or K8s manifests done or PR-ready. Runs helm lint, schema validation, deprecated-API check, then cross-checks deployed-state claims against the live cluster."
---

# Gate: Kubernetes / Helm / GitOps / Talos

Tuned to Robert's stack: Helm + ArgoCD (GitOps) on Talos. Vor jedem Check
Tool-Verfügbarkeit prüfen; fehlt eines → **INCONCLUSIVE**, nicht PASS. Per-Projekt
kommen Tools via `devbox shell` — Gate also im Projekt-Kontext laufen lassen.

## Checks

```bash
# Helm-Charts (global vorhanden)
command -v helm >/dev/null && helm lint <chart-dir> || echo "INCONCLUSIVE: helm fehlt"

# Schema-Validierung der gerenderten Manifeste (kubeconform empfohlen — aktuell nicht installiert)
command -v kubeconform >/dev/null && \
  helm template <release> <chart-dir> -f <values> \
  | kubeconform -strict -summary -kubernetes-version <ver> \
      -schema-location default \
      -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  || echo "INCONCLUSIVE: kubeconform fehlt — 'devbox global add kubeconform' (einzige echte Luecke)"

# Deprecated/removed APIs (kubent ist da)
command -v kubent >/dev/null && kubent --helm3 -t <ver> || echo "INCONCLUSIVE: kubent fehlt"

# Kustomize nur falls Overlays vorhanden (Robert nutzt primaer Helm/ArgoCD)
[ -f <overlay>/kustomization.yaml ] && { command -v kustomize >/dev/null && kustomize build <overlay> >/dev/null || echo "INCONCLUSIVE: kustomize fehlt"; }
```

## Konventions-Checks (manuell)

- Code/Kommentare englisch; keine Was-Kommentare (siehe `coding-rules`).
- Talos-Basis-Repos: durchgängig englisch, keine deutschen Kommentare.
- Keine ungenutzten Werte / Platzhalter für noch nicht existierende Features.

## „Aktiv/deployt" niemals aus der Config schließen

Eine `*.enabled`-Sektion oder eine referenzierende `*_url` beweist NICHT, dass die
Komponente läuft. Vor jeder Deploy-Aussage `<component>.enabled` + Live-State prüfen
(Details: `rca`). GitOps heißt: die App-Definition in Git ≠ synced/healthy im Cluster.

```bash
argocd app get <app>            # Sync/Health-Status (GitOps-Wahrheit)
kubectl get pods,svc -n <ns>    # tatsächliche Workloads
helm get values <release> -n <ns>
talosctl -n <node> services     # Node-Ebene, falls relevant
```
