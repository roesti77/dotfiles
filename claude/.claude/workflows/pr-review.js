export const meta = {
  name: 'pr-review',
  description: 'Multi-dimension PR review with adversarial verification of every finding',
  whenToUse: 'Pass a PR number (e.g. "42") or "working" for the uncommitted diff. Reviews across correctness, security, conventions and infra, then tries to refute each finding so only real ones survive.',
  phases: [
    { title: 'Review', detail: 'parallel dimensions over the diff' },
    { title: 'Verify', detail: 'adversarially refute each finding' },
  ],
}

const target = typeof args === 'string' && args.trim() ? args.trim() : 'working'
const diffCmd = target === 'working' ? 'git diff HEAD' : `gh pr diff ${target}`
log(`PR review target: ${target} (diff via: ${diffCmd})`)

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['title', 'file', 'severity'],
        properties: {
          title: { type: 'string' },
          file: { type: 'string' },
          line: { type: 'string' },
          severity: { enum: ['low', 'medium', 'high'] },
          detail: { type: 'string' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['refuted', 'reason'],
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
}

const DIMENSIONS = [
  { key: 'correctness', agentType: 'reviewer', lens: 'bugs, logic errors, unhandled edge cases, error handling' },
  { key: 'security', agentType: 'security', lens: 'vulnerabilities, leaked secrets, unsafe defaults, RBAC/permissions' },
  { key: 'conventions', agentType: 'claude-md-compliance-checker', lens: 'CLAUDE.md + coding-rules: English code/comments, no what-comments, commit/PR conventions, English-only in Talos base repos' },
  { key: 'infra', agentType: 'kubernetes-expert', lens: 'for k8s/helm/manifest/IaC changes: enabled-flags vs actually-deployed state, resource correctness. If no infra files changed, return no findings' },
]

phase('Review')
const results = await pipeline(
  DIMENSIONS,
  (d) =>
    agent(
      `Run \`${diffCmd}\` to get the diff. Review ONLY through the ${d.key} lens: ${d.lens}. ` +
        `Report concrete findings with file and line. No nitpicks.`,
      { agentType: d.agentType, label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA },
    ),
  (review, d) =>
    parallel(
      (review.findings || []).map((f) => () =>
        agent(
          `Adversarially verify this review finding — try to REFUTE it. Default to refuted=true if ` +
            `uncertain or if it is a stylistic nitpick. Use \`${diffCmd}\` and the repo for context.\n\n` +
            `Finding: ${JSON.stringify(f)}`,
          { agentType: 'reviewer', label: `verify:${d.key}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ).then((v) => ({ ...f, dimension: d.key, verdict: v })),
      ),
    ),
)

const confirmed = results
  .flat()
  .filter(Boolean)
  .filter((f) => f.verdict && !f.verdict.refuted)
  .sort((a, b) => ({ high: 0, medium: 1, low: 2 }[a.severity] - { high: 0, medium: 1, low: 2 }[b.severity]))

log(`Confirmed findings: ${confirmed.length} (high: ${confirmed.filter((f) => f.severity === 'high').length})`)
return { target, confirmed }
