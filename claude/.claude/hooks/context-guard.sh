#!/usr/bin/env bash
# PreToolUse(Bash) guard: block mutating cluster commands against non-allowed contexts.
# Convention: local playground contexts are always allowed; every remote context must
# be listed (glob per line, # = comment) in ~/.claude/allowed-contexts. Fail-closed.
#
# Covered: kubectl, helm, talosctl, argocd. Target context comes from an explicit
# --context/--kube-context flag, else the current context of the matching tool.
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
elif printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])argocd[[:space:]]+app[[:space:]]+(sync|delete|create|set|unset|patch|rollback|terminate-op)([[:space:]]|$)'; then
  mutating='argocd'
else
  exit 0
fi

ctx=$(printf '%s' "$cmd" | sed -nE 's/.*--(kube-)?context[= ]([^[:space:]]+).*/\2/p')
if [ -z "$ctx" ]; then
  case "$mutating" in
    kubectl|helm|argocd)
      ctx=$(kubectl config current-context 2>/dev/null || true) ;;
    talosctl)
      ctx=$(talosctl config info 2>/dev/null | sed -nE 's/^[[:space:]]*Current context:[[:space:]]*([^[:space:]]+).*/\1/p' || true) ;;
  esac
fi
[ -n "$ctx" ] || exit 0

if printf '%s' "$ctx" | grep -qE "^(${LOCAL_PATTERNS})$"; then
  exit 0
fi

if [ -f "$ALLOWFILE" ]; then
  while IFS= read -r pattern; do
    case "$pattern" in ''|'#'*) continue ;; esac
    # shellcheck disable=SC2254
    case "$ctx" in $pattern) exit 0 ;; esac
  done < "$ALLOWFILE"
fi

echo "Blocked: mutierendes ${mutating}-Kommando gegen Context '${ctx}' (nicht in ${ALLOWFILE}). Lokale Contexts (kind-*, minikube, ...) sind immer erlaubt. Freigeben: 'echo \"${ctx}\" >> ${ALLOWFILE}' — bewusst, pro Cluster." >&2
exit 2
