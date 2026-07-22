# Conformance suite

Behavioral regression tests for the harness itself. Static CI (`harness-ci`)
checks the files are well-formed; this suite checks the contracts actually
change model behaviour — given a prompt, does the harness take the actions its
agents/skills/hooks promise, and avoid the ones they forbid.

## What it is not

It is **not** automated end-to-end. No 2026 tool reads a Claude Code session
transcript and produces a per-contract verdict, so scenario **scoring is manual**
(`run.sh` is an operator driver). What *is* automated is the suite's own
integrity — `validate.mjs` runs in CI and keeps `scenarios.json` well-formed and
every `governing` path pointing at a real harness file.

## scenarios.json

One entry per scenario:

| field | meaning |
|---|---|
| `id` | stable `S<NN>-slug`, immutable once merged |
| `tags` | free grouping (`wargame`, `hooks`, …) |
| `observability` | `mechanical` (verifiable by exit code / tool-trace / file), `hybrid` (needs an operator skim), or `judged` (pure judgment) |
| `prompt` | the input to run in a fresh session |
| `governing` | the harness files the scenario exercises — the coverage key, checked to exist |
| `expected` / `forbidden` | observable predicates that must hold / must not |
| `rubric` | how predicate counts map to PASS / PARTIAL / FAIL |
| `discrimination_status` | honesty field — has the scenario been confirmed to go red when its governing directive is removed? `verified` / `unverified` |

### On `discrimination_status`

A scenario proves nothing if the behaviour survives deleting the directive that
supposedly drives it (trained behaviour, positive framing, cross-contract
redundancy). The honest test is an **ablation**: remove the governing directive
in a scratch copy, re-run, and check the scenario goes red. Until you do that,
the status is `unverified` and the scenario is a documentation of intent, not a
proof of enforcement. Do not hide an `unverified`; it tells the reader how much
to trust a green.

## Running

```sh
node claude/.claude/eval/validate.mjs      # CI-automated: is the suite well-formed?
bash claude/.claude/eval/run.sh            # operator: score scenarios, write a baseline
bash claude/.claude/eval/run.sh --tag hooks   # filter
```

`run.sh` prints each scenario's prompt + expected/forbidden, you run it in a
fresh session, and record PASS/PARTIAL/FAIL/SKIP + a note. It writes
`baseline-<UTC-date>.json` as dated evidence (git-ignored; commit one deliberately
if you want a historical record).

## Adding a scenario

Pick the lightest `observability` that is honest, name real `governing` files,
write `expected`/`forbidden` as things an operator can *see* (a tool call, an
exit code, a file), and set `discrimination_status: unverified` until you have
run the ablation.
