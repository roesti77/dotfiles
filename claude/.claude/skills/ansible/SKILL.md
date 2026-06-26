---
name: ansible
description: "Quality gate for Ansible and plain YAML changes. Use before declaring playbooks, roles, or YAML config done or PR-ready. Runs yamllint, ansible-lint, and playbook syntax-check."
---

# Gate: Ansible / YAML

Fehlt ein Tool → **INCONCLUSIVE**, nicht PASS. `yamllint`/`ansible-lint` sind nicht
global installiert — sie kommen per-Projekt via `devbox shell`; das Gate also im
Projekt-Kontext laufen lassen.

```bash
command -v yamllint >/dev/null && yamllint . || echo "INCONCLUSIVE: yamllint fehlt"

command -v ansible-lint >/dev/null && ansible-lint || echo "INCONCLUSIVE: ansible-lint fehlt"

command -v ansible-playbook >/dev/null && \
  ansible-playbook --syntax-check <playbook>.yaml \
  || echo "INCONCLUSIVE: ansible-playbook fehlt"
```

## Konventions-Checks (siehe `coding-rules`)

- Task-`desc`/`name` kurz halten — keine ganzen Sätze.
- Keine Echo-Messages, die ankündigen, was als Nächstes passiert.
