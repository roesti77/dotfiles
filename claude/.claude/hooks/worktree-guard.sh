#!/usr/bin/env bash
# PreToolUse(Bash) guard: block `git commit` / `git push` from a main checkout.
# Convention: commit in a worktree, never in the main checkout (parallel sessions).
# Opt out per repo with `.allow-main-commit` at the repo root (e.g. dotfiles, a
# single-author repo with no parallel-session WIP).
#
# Best-effort: catches plain `git commit|push` and `git -C <path> commit|push`,
# checked against the repo at each -C path and (for a flagless commit|push) the
# session cwd. Every commit|push target in a compound command must clear the guard.
# Shell tricks (cd first, aliases, wrappers) are not caught — safety net, not a wall.
#
# no-jq: fail-open — without jq the command cannot be parsed, so the guard is inert
# and the commit/push proceeds. Consistent with the best-effort posture above.
set -euo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null || true)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null || true)

printf '%s' "$cmd" \
  | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(commit|push)([[:space:]]|$)' \
  || exit 0

blocked_root=''
is_main_checkout() {
  dir=${1/#\~/$HOME}
  gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null) || return 1
  case "$gitdir" in *"/worktrees/"*) return 1 ;; esac
  root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$root" ] && [ -f "$root/.allow-main-commit" ]; then
    return 1
  fi
  blocked_root=$root
  return 0
}

while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  if is_main_checkout "$dir"; then
    echo "Blocked: git commit/push im Hauptcheckout (${blocked_root:-?}). Konvention: in einem Worktree committen (git worktree add <tmp> origin/main -b <branch>). Opt-out fuer dieses Repo: 'touch ${blocked_root:-.}/.allow-main-commit'." >&2
    exit 2
  fi
done <<EOF
$(printf '%s' "$cmd" | grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+[[:space:]]+(commit|push)' | sed -E 's/git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+(commit|push)/\1/')
EOF

if printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(commit|push)([[:space:]]|$)'; then
  if is_main_checkout "${cwd:-.}"; then
    echo "Blocked: git commit/push im Hauptcheckout (${blocked_root:-?}). Konvention: in einem Worktree committen (git worktree add <tmp> origin/main -b <branch>). Opt-out fuer dieses Repo: 'touch ${blocked_root:-.}/.allow-main-commit'." >&2
    exit 2
  fi
fi

exit 0
