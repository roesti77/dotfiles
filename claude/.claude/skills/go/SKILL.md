---
name: go
description: "Quality gate for Go changes. Use before declaring Go code done or PR-ready. Runs build, vet, race-enabled tests, lint, and format check."
---

# Gate: Go

Fehlt ein Tool → **INCONCLUSIVE**, nicht PASS.

```bash
go build ./...
go vet ./...
go test ./... -race -count=1

command -v golangci-lint >/dev/null && golangci-lint run \
  || echo "INCONCLUSIVE: golangci-lint fehlt"

# Format: gofumpt bevorzugt, sonst gofmt
if command -v gofumpt >/dev/null; then
  out=$(gofumpt -l .); [ -z "$out" ] || { echo "FAIL: ungefmt'et:"; echo "$out"; }
else
  out=$(gofmt -l .); [ -z "$out" ] || { echo "FAIL: ungefmt'et:"; echo "$out"; }
fi
```

## Konventions-Checks (siehe `coding-rules`)

- Code/Kommentare englisch; Kommentare nur fürs Warum, nicht fürs Was.
- Keine Datei-Header- oder Section-Separator-Kommentare.
