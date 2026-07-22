#!/usr/bin/env bash
# PreToolUse(Bash) guard: block mutating cluster commands against non-allowed contexts.
# Convention: local playground contexts are always allowed; every remote context must
# be listed (glob per line, # = comment) in ~/.claude/allowed-contexts. Fail-closed
# once the command parses: a mutating command whose target context cannot be resolved
# or is not allowed is blocked.
#
# no-jq: fail-open — without jq the command cannot be parsed, so the guard is inert
# and the mutating command runs. The Fail-closed guarantee holds only when jq is
# present (it is, on the target machines). See hooks/THREAT-MODEL.md.
#
# Covered: kubectl, helm, talosctl, argocd. Target context comes from explicit
# --context/--kube-context flags, else the current context of the matching tool.
# A compound command (;, &&, ||, &) is evaluated against every candidate context —
# all must be allowed. A context whose NAME looks local but whose server endpoint is
# remote is NOT exempted (kube tools); talosctl local exemption stays name-only.
# Best-effort: shell tricks (cd, aliases, wrappers, env -i) are not caught.
set -euo pipefail

ALLOWFILE="$HOME/.claude/allowed-contexts"
LOCAL_PATTERNS='kind-.+|k3d-.+|minikube|docker-desktop|colima|rancher-desktop|orbstack'

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

mutating=''
if printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])kubectl[[:space:]]+(.*[[:space:]])?(apply|delete|edit|patch|replace|create|scale|drain|cordon|uncordon|taint|set|label|annotate|rollout|expose|autoscale)([[:space:]]|$)'; then
  mutating='kubectl'
elif printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])helm[[:space:]]+(.*[[:space:]])?(install|upgrade|uninstall|rollback|delete)([[:space:]]|$)'; then
  mutating='helm'
elif printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])talosctl[[:space:]]+(.*[[:space:]])?(apply-config|patch|edit|reset|reboot|shutdown|bootstrap|upgrade|upgrade-k8s)([[:space:]]|$)'; then
  mutating='talosctl'
elif printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])argocd[[:space:]]+(app|proj|repo|cluster|appset|account|cert|gpg)[[:space:]]+(create|delete|rm|add|set|unset|patch|rollback|sync|terminate-op|update-password)([[:space:]]|$)'; then
  mutating='argocd'
else
  exit 0
fi

host_is_local() {
  case "$1" in
    127.*|::1|localhost|0.0.0.0|host.docker.internal) return 0 ;;
    10.*|192.168.*) return 0 ;;
    172.1[6-9].*|172.2[0-9].*|172.3[01].*) return 0 ;;
    *) return 1 ;;
  esac
}

ctx_allowed() {
  ctx=$1
  [ -n "$ctx" ] || return 1
  if printf '%s' "$ctx" | grep -qE "^(${LOCAL_PATTERNS})$"; then
    if [ "$mutating" = talosctl ]; then return 0; fi
    server=$(kubectl config view --minify --context="$ctx" -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)
    host=${server#*://}; host=${host%%[:/]*}
    host_is_local "$host" && return 0
  fi
  if [ -f "$ALLOWFILE" ]; then
    while IFS= read -r pattern; do
      case "$pattern" in ''|'#'*) continue ;; esac
      case "$pattern" in
        '*'|'?'|'['*)
          echo "context-guard: ignoring wildcard allowlist entry '${pattern}' in ${ALLOWFILE} (would match every context)." >&2
          continue ;;
      esac
      # shellcheck disable=SC2254
      case "$ctx" in $pattern) return 0 ;; esac
    done < "$ALLOWFILE"
  fi
  return 1
}

flag_ctxs=$(printf '%s' "$cmd" | grep -oE -- '--(kube-)?context[=[:space:]][^[:space:]]+' | sed -E 's/^--(kube-)?context[=[:space:]]//' || true)
n_flags=$(printf '%s' "$flag_ctxs" | grep -c . || true)
compound=0
printf '%s' "$cmd" | grep -qE '[;&]|\|\|' && compound=1

current=''
if [ -z "$flag_ctxs" ] || [ "$compound" = 1 ] || [ "$n_flags" -gt 1 ]; then
  case "$mutating" in
    kubectl|helm|argocd)
      current=$(kubectl config current-context 2>/dev/null || true) ;;
    talosctl)
      current=$(talosctl config info 2>/dev/null | sed -nE 's/^[[:space:]]*Current context:[[:space:]]*([^[:space:]]+).*/\1/p' || true) ;;
  esac
  if [ -z "$flag_ctxs" ] && [ -z "$current" ]; then
    echo "Blocked: mutierendes ${mutating}-Kommando, aber Ziel-Context nicht auflösbar (kein --context, current-context leer). Fail-closed." >&2
    exit 2
  fi
fi

candidates=$(printf '%s\n%s\n' "$flag_ctxs" "$current" | grep -v '^$' | sort -u || true)
while IFS= read -r c; do
  [ -n "$c" ] || continue
  if ! ctx_allowed "$c"; then
    echo "Blocked: mutierendes ${mutating}-Kommando gegen Context '${c}' (nicht in ${ALLOWFILE}). Lokale Contexts (kind-*, minikube, ...) sind erlaubt, wenn ihr Endpoint lokal ist. Freigeben: 'echo \"${c}\" >> ${ALLOWFILE}' — bewusst, pro Cluster." >&2
    exit 2
  fi
done <<EOF
$candidates
EOF

exit 0
