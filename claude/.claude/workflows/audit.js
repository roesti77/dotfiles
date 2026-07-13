export const meta = {
  name: 'audit',
  description: 'Multi-modal audit of a K8s/IaC target: config-vs-deployed-state, security, drift',
  whenToUse: 'Pass the target as args (repo path and/or cluster+namespace). Sweeps manifests/helm/IaC in parallel, then verifies any "is/!is deployed" claim against live state.',
  phases: [
    { title: 'Sweep', detail: 'parallel auditors, one per dimension' },
    { title: 'Verify', detail: 'confirm config-vs-live claims against the cluster' },
  ],
}

const target = typeof args === 'string' && args.trim() ? args.trim() : JSON.stringify(args ?? {})
log(`Audit target: ${target}`)

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['title', 'severity', 'claimsLiveState'],
        properties: {
          title: { type: 'string' },
          where: { type: 'string' },
          severity: { enum: ['low', 'medium', 'high'] },
          detail: { type: 'string' },
          claimsLiveState: { type: 'boolean' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['confirmed', 'evidence'],
  properties: {
    confirmed: { type: 'boolean' },
    evidence: { type: 'string' },
  },
}

const DIMENSIONS = [
  { key: 'k8s-enabled', agentType: 'kubernetes-expert', lens: 'Helm/manifest components: does a referenced component (alertmanager_url, *_url, [[plugin]], a values section) actually have its enabled-flag set AND a workload? Flag config that merely points at something as NOT proven deployed (set claimsLiveState=true).' },
  { key: 'iac', agentType: 'terraform-architect', lens: 'Terraform/OpenTofu: drift risk, unpinned versions, state/backend issues, module hygiene.' },
  { key: 'security', lens: 'secrets in plain text, over-broad RBAC, unsafe defaults, missing network policy.' },
  { key: 'debt', agentType: 'code-quality-pragmatist', lens: 'accumulated debt, deprecated APIs, duplicated config, dead resources.' },
]

phase('Sweep')
const sweep = (
  await parallel(
    DIMENSIONS.map((d) => () =>
      agent(
        `Audit target "${target}" ONLY through the ${d.key} lens: ${d.lens} ` +
          `Use read-only tools (rg, kubectl get, helm get manifest, tofu show) where available. Report concrete findings.`,
        { ...(d.agentType && { agentType: d.agentType }), label: `sweep:${d.key}`, phase: 'Sweep', schema: FINDINGS_SCHEMA },
      ).then((res) => ({ d, res })),
    ),
  )
)
  .filter((x) => x && x.res)
  .flatMap(({ d, res }) => (res.findings || []).map((f) => ({ ...f, dimension: d.key })))

const verifierFor = (dim) => (dim === 'iac' ? 'terraform-architect' : 'kubernetes-expert')
const probeFor = (dim) =>
  dim === 'iac'
    ? 'tofu state list / tofu show — check the actual state, not the config'
    : 'kubectl get pods,svc -n <ns>; helm get manifest <release> — check the enabled-flag AND the running workload'

phase('Verify')
const liveClaims = sweep.filter((f) => f.claimsLiveState)
const verified = await parallel(
  liveClaims.map((f) => () =>
    agent(
      `Verify against ACTUAL live state, not config. Do NOT infer "deployed/active" from a config ` +
        `section or a referencing URL. Probe: ${probeFor(f.dimension)}. Target: ${target}.\n\n` +
        `Claim to check: ${JSON.stringify(f)}`,
      { agentType: verifierFor(f.dimension), label: `verify:${f.where || f.title}`, phase: 'Verify', schema: VERDICT_SCHEMA },
    )
      .then((v) => ({ ...f, verdict: v }))
      .catch(() => ({ ...f, verdict: null })),
  ),
)

const configOnly = sweep.filter((f) => !f.claimsLiveState)
const liveConfirmed = verified.filter((f) => f && f.verdict && f.verdict.confirmed)
const liveUnverified = verified.filter((f) => f && !(f.verdict && f.verdict.confirmed))
log(
  `Findings: ${configOnly.length} config-level + ${liveConfirmed.length} live-confirmed + ` +
    `${liveUnverified.length} live-unverified (of ${liveClaims.length} live claims)`,
)
return { target, configFindings: configOnly, liveFindings: liveConfirmed, unverifiedLiveClaims: liveUnverified }
