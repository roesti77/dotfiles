# Guard & permission threat model

The authoritative contract for what the harness's safety layer prevents — and,
just as importantly, what it does not. If a guard's code diverges from the intent
stated here, the code is the bug. Reviewers: check changes against this file.

The guards are **best-effort safety nets, not a security boundary**. They assume a
non-adversarial operator whose real risk is a mistake (wrong context, wrong
checkout), plus an LLM that can be steered by a malicious prompt into a plausible
but wrong command. They do not defend against an operator who actively wants to
defeat them — every guard is bypassable by a shell trick (see Shared non-goals).

## context-guard.sh (PreToolUse: Bash)

- **Prevents**: a mutating `kubectl` / `helm` / `talosctl` / `argocd` command from
  running against a remote cluster that is not listed in `~/.claude/allowed-contexts`.
- **Fail-closed**: a mutating command whose target context cannot be resolved (no
  `--context`, empty current-context) is blocked. A compound command is evaluated
  against every candidate context — all must be allowed. A context whose *name*
  looks local but whose server *endpoint* is remote is not exempted (kube tools).
- **Non-goals / known bypasses**:
  - Shell tricks (see Shared non-goals).
  - talosctl local exemption is name-only (no endpoint check) — a remote talos
    context named like a local one is exempted.
  - An RFC1918 / loopback endpoint is treated as local; a remote cluster reachable
    on a private-range address and named to match `LOCAL_PATTERNS` is exempted.
  - Read-only commands are not inspected — data exfiltration is the permission
    layer's job, not this guard's.

## worktree-guard.sh (PreToolUse: Bash)

- **Prevents**: `git commit` / `git push` from a main checkout (the convention is to
  commit in a worktree so parallel sessions don't collide).
- **Fail-closed**: every commit/push target in a compound command is checked — each
  `-C <dir>` and the session cwd for a flagless commit/push; any main-checkout target
  blocks. The opt-out (`.allow-main-commit` at the repo root) is honored whenever the
  file is present.
- **Non-goals / known bypasses**:
  - Shell tricks (see Shared non-goals).
  - It enforces a workflow convention, not a security property — a present
    `.allow-main-commit` disarms it for that repo.
  - **Accepted residual**: `.allow-main-commit` is tracked in dotfiles (a sanctioned
    single-author exception), so it ships to every clone. In a multi-author repo a
    committed opt-out would silently disarm the guard for all clones — do not track
    it there.

## permission deny-list (settings.seed.json)

- **Prevents**: the obvious secret reads — `kubectl get secret*`, `kubectl describe
  secret*`, `helm get values` / `helm get all`.
- **Fail-open by nature**: it is a command-string matcher, not a content filter. It
  cannot express "no secret content".
- **Non-goals / known bypasses**:
  - `kubectl get <resource> -o yaml/jsonpath` on any secret-bearing object (a
    ServiceAccount token, a ConfigMap of credentials, a workload with inline env
    secrets) still exfiltrates them.
  - Arbitrary resource aliasing / CRDs holding secret material are not enumerable.
  - Durable closure needs an allow-only-non-secret model, not attempted.

## Shared non-goals (all guards)

- **Shell tricks defeat every guard**: `cd` into the target then a bare command,
  shell aliases, wrapper scripts, `env -i`, or a command built at runtime evade the
  regex-over-one-command inspection. With the global skip-prompt flags on
  (`skipDangerousModePermissionPrompt`), there is no interactive backstop behind the
  guards — a bypassed destructive command executes unprompted.
- The guards cover four cluster CLIs and git; every other tool (`rm`, `curl | sh`,
  arbitrary Bash) runs unguarded. See the README settings section for the blast
  radius of the skip-prompt flags.
