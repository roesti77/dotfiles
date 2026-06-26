---
name: rca
description: "Root-cause discipline for errors, incidents, and failures. Use when debugging a failure, diagnosing an incident, or before claiming a component/feature is active or deployed. Enforces evidence-before-action and the enabled-flag + live-state verification."
---

# Root-Cause-Analyse — Ursache vor Aktion

## Kein trial-and-error

Kein Restart, Neuversuch, Workaround oder „probier mal X", bevor die Root-Cause durch
Evidenz belegt ist.

## Vorgehen

1. **Symptom exakt erfassen** — was genau, wo, seit wann, wie reproduzierbar.
2. **Hypothese** formulieren.
3. **Gezielter Test / Isolation / Logs / Status**, der die Hypothese be- oder widerlegt.
4. Erst nach **belegter Ursache** den Fix.

## Variablen einzeln isolieren

Nicht mehrere Dinge gleichzeitig neustarten. Eine Variable nach der anderen — z. B.
zuerst klären: ist es app- oder infra-weit?

## Tool-eigene Diagnose zuerst

Logs und Tool-Diagnose lesen, bevor in Low-Level-Internals geraten wird:
`*-dbg`, `monitor`, `status`, drop-reasons, Status-Conditions.

## „Vorhanden/aktiv" erst nach Verifikation behaupten

Eine Config, die auf etwas zeigt, beweist NICHT, dass das Ziel läuft. Nie aus einer
gerenderten Config-Sektion, einem Default oder einer referenzierenden URL (`*_url`,
`alertmanager_url`, ein gesetzter Endpoint, ein `[[plugin]]`-Block) schließen, dass
eine Komponente deployt/aktiv ist.

**Immer den maßgeblichen Schalter prüfen:**
- Helm `<component>.enabled`, replica count
- `--<feature>-bind-address` / `--metrics-bind-address`
- CRD `spec.enabled`

**Und — wenn erreichbar — den Live-State:**
```bash
kubectl get pods,svc -n <ns>
helm get values <release> -n <ns>
```

Konkreter Anlass: „Mimir hat den Alertmanager dabei" wurde aus dem gerenderten
`alertmanager:`-Block + `ruler.alertmanager_url` geschlossen — tatsächlich war
`alertmanager.enabled: false`, kein AM-Pod. Die darauf gebaute Entscheidung war falsch.
