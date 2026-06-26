#!/usr/bin/env bash
# PreToolUse(Bash) guard: block `git commit` / `git push` from a main checkout.
# Convention: commit in a worktree, never in the main checkout (parallel sessions).
# Opt out per repo by creating `.allow-main-commit` at the repo root (e.g. dotfiles).
#
# Best-effort: only inspects the hook's cwd. `git -C <path> commit` from another
# directory is not caught — treat this as a safety net, not a hard guarantee.
set -euo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" \
  | /usr/bin/python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null || true)

case "$cmd" in
  *"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

gitdir=$(git rev-parse --git-dir 2>/dev/null) || exit 0
case "$gitdir" in
  *"/worktrees/"*) exit 0 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[ -n "$root" ] && [ -f "$root/.allow-main-commit" ] && exit 0

echo "Blocked: git commit/push im Hauptcheckout (${root:-?}). Konvention: in einem Worktree committen (git worktree add <tmp> origin/main -b <branch>). Opt-out fuer dieses Repo: 'touch ${root:-.}/.allow-main-commit'." >&2
exit 2
