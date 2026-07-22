#!/usr/bin/env bash
# Operator driver for the conformance suite. Prints each scenario's prompt and
# predicates, you run it in a FRESH session and record a verdict. Scoring is
# manual by design — see README.md. Optional: --tag <t> / --governing <fragment>.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
scenarios="$here/scenarios.json"
[ -f "$scenarios" ] || { echo "no scenarios.json next to run.sh" >&2; exit 1; }
command -v jq >/dev/null || { echo "run.sh needs jq" >&2; exit 1; }
node "$here/validate.mjs" >/dev/null || { echo "scenarios.json is invalid — fix it before running (see validate.mjs output)" >&2; exit 1; }

filter='.scenarios[]'
case "${1:-}" in
  --tag) filter=".scenarios[] | select(.tags | index(\"$2\"))" ;;
  --governing) filter=".scenarios[] | select(.governing | map(contains(\"$2\")) | any)" ;;
  '') ;;
  *) echo "usage: run.sh [--tag <t> | --governing <path-fragment>]" >&2; exit 2 ;;
esac

ids=$(jq -r "$filter | .id" "$scenarios")
[ -n "$ids" ] || { echo "no scenarios matched"; exit 0; }

stamp=$(date -u +%Y-%m-%d)
out="$here/baseline-$stamp.json"
results='[]'
bold=$(tput bold 2>/dev/null || true); dim=$(tput dim 2>/dev/null || true); rst=$(tput sgr0 2>/dev/null || true)

while IFS= read -r id; do
  s=$(jq -c ".scenarios[] | select(.id == \"$id\")" "$scenarios")
  printf '\n%s== %s ==%s  (%s)\n' "$bold" "$id" "$rst" "$(jq -r '.observability' <<<"$s")"
  printf '%sprompt:%s %s\n' "$bold" "$rst" "$(jq -r '.prompt' <<<"$s")"
  printf '%sgoverning:%s %s\n' "$dim" "$rst" "$(jq -r '.governing | join(", ")' <<<"$s")"
  printf '%sexpected:%s\n' "$bold" "$rst"; jq -r '.expected[] | "  + " + .' <<<"$s"
  printf '%sforbidden:%s\n' "$bold" "$rst"; jq -r '.forbidden[] | "  - " + .' <<<"$s"
  printf '%srubric:%s %s\n' "$dim" "$rst" "$(jq -r '.rubric' <<<"$s")"
  ds=$(jq -r '.discrimination_status' <<<"$s")
  case "$ds" in unverified*) printf '%sCAVEAT: discrimination unverified — a green here is weak evidence.%s\n' "$dim" "$rst" ;; esac

  verdict=''
  while ! printf '%s' "$verdict" | grep -qiE '^(pass|partial|fail|skip)$'; do
    printf 'verdict [pass/partial/fail/skip]: '
    read -r verdict </dev/tty || { echo; echo 'no tty — aborting' >&2; exit 1; }
  done
  printf 'note (optional): '; read -r note </dev/tty || note=''
  results=$(jq -c --arg id "$id" --arg v "$(printf '%s' "$verdict" | tr '[:upper:]' '[:lower:]')" --arg n "$note" \
    '. += [{id: $id, verdict: $v, note: $n}]' <<<"$results")
done <<<"$ids"

# atomic write
tmp=$(mktemp "$here/.baseline.XXXXXX")
jq -n --arg date "$stamp" --argjson results "$results" \
  '{date: $date, results: $results, summary: ($results | group_by(.verdict) | map({(.[0].verdict): length}) | add)}' > "$tmp"
mv "$tmp" "$out"
printf '\n%swrote %s%s\n' "$bold" "$out" "$rst"
jq -r '.summary | to_entries[] | "  \(.key): \(.value)"' "$out"
