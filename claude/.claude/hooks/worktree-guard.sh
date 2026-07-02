#!/usr/bin/env bash
# PreToolUse(Bash) guard: block `git commit` / `git push` from a main checkout.
# Convention: commit in a worktree, never in the main checkout (parallel sessions).
# Opt out per repo by creating `.allow-main-commit` at the repo root (e.g. dotfiles).
#
# Best-effort: catches plain `git commit|push` and `git -C <path> commit|push`,
# checked against the repo at -C path resp. the session cwd from the hook payload.
# Shell tricks (cd first, aliases, wrappers) are not caught — safety net, not a wall.
set -euo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null || true)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // ""' 2>/dev/null || true)

printf '%s' "$cmd" \
  | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(commit|push)([[:space:]]|$)' \
  || exit 0

dir=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+)[[:space:]]+(commit|push).*/\1/p')
[ -n "$dir" ] || dir=${cwd:-.}
dir=${dir/#\~/$HOME}

gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null) || exit 0
case "$gitdir" in
  *"/worktrees/"*) exit 0 ;;
esac

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "")
[ -n "$root" ] && [ -f "$root/.allow-main-commit" ] && exit 0

echo "Blocked: git commit/push im Hauptcheckout (${root:-?}). Konvention: in einem Worktree committen (git worktree add <tmp> origin/main -b <branch>). Opt-out fuer dieses Repo: 'touch ${root:-.}/.allow-main-commit'." >&2
exit 2
