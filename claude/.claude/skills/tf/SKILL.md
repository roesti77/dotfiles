---
name: tf
description: "Quality gate for Terraform / OpenTofu changes. Use before declaring IaC changes done or PR-ready. Runs fmt check, validate, lint, and a config security scan."
---

# Gate: Terraform / OpenTofu

`tofu` bevorzugen, auf `terraform` zurückfallen, wenn `tofu` fehlt. Fehlt ein Tool →
**INCONCLUSIVE**, nicht PASS.

```bash
TF=$(command -v tofu || command -v terraform) || echo "INCONCLUSIVE: tofu/terraform fehlt"

"$TF" fmt -check -recursive
"$TF" init -backend=false >/dev/null && "$TF" validate

command -v tflint >/dev/null && tflint || echo "INCONCLUSIVE: tflint fehlt"

# Security/Policy-Scan (eines davon)
command -v trivy >/dev/null && trivy config . \
  || { command -v checkov >/dev/null && checkov -d . ; } \
  || echo "INCONCLUSIVE: trivy/checkov fehlt"
```

## Konventions-Checks (siehe `coding-rules`)

- `description` bei Variablen/Outputs nur bei echtem Mehrwert — keine Echo-Descriptions.
- Einzeilige Variablen wenn nur `type` gesetzt wird.
- Keine Boilerplate-Kommentare / Platzhalter für künftige Phasen.

`plan` ist KEIN Gate-Schritt (braucht echtes Backend/Credentials) — separat und bewusst
ausführen, nie blind `apply`.
