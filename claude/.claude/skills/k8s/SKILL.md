---
name: k8s
description: "Quality gate for Kubernetes / Helm / Kustomize changes. Use before declaring Helm charts, values, or K8s manifests done or PR-ready. Runs helm lint, schema validation (kubeconform), and kustomize build, then cross-checks deployed-state claims."
---

# Gate: Kubernetes / Helm / Kustomize

Vor jedem Check Tool-Verfügbarkeit prüfen; fehlt eines → **INCONCLUSIVE**, nicht PASS.

## Checks

```bash
# Helm-Charts
command -v helm >/dev/null && helm lint <chart-dir> || echo "INCONCLUSIVE: helm fehlt"

# Schema-Validierung der gerenderten Manifeste
command -v kubeconform >/dev/null && \
  helm template <release> <chart-dir> -f <values> \
  | kubeconform -strict -summary -kubernetes-version <ver> \
      -schema-location default \
      -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  || echo "INCONCLUSIVE: kubeconform fehlt"

# Kustomize-Overlays
command -v kustomize >/dev/null && kustomize build <overlay> >/dev/null \
  || echo "INCONCLUSIVE: kustomize fehlt"
```

## Konventions-Checks (manuell)

- Code/Kommentare englisch; keine Was-Kommentare (siehe `coding-rules`).
- Keine ungenutzten Werte / Platzhalter für noch nicht existierende Features.

## „Aktiv/deployt" niemals aus der Config schließen

Eine gerenderte `*.enabled`-Sektion oder eine referenzierende `*_url` beweist NICHT,
dass die Komponente läuft. Vor jeder Deploy-Aussage `<component>.enabled` + Live-State
prüfen — Details siehe `rca`.

```bash
kubectl get pods,svc -n <ns>
helm get values <release> -n <ns>
```
