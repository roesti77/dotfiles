export const meta = {
  name: 'sdd-plan',
  description: 'Spec-driven planning: turn a spec into a critiqued, spec-covered implementation plan',
  whenToUse: 'Run after a spec exists, before implementing a non-trivial feature. Pass the spec text or path as args.',
  phases: [
    { title: 'Plan', detail: 'castiel decomposes the spec into steps' },
    { title: 'Critique', detail: 'parallel lenses: spec-coverage, architecture/risk, simplicity' },
    { title: 'Synthesize', detail: 'merge into a final plan with mitigations' },
  ],
}

const spec = typeof args === 'string' ? args : JSON.stringify(args ?? {}, null, 2)
if (!spec || spec === '{}') {
  log('No spec passed as args — pass the spec text or path.')
}

const PLAN_SCHEMA = {
  type: 'object',
  required: ['steps', 'risks', 'openQuestions'],
  properties: {
    steps: {
      type: 'array',
      items: {
        type: 'object',
        required: ['n', 'action', 'files'],
        properties: {
          n: { type: 'number' },
          action: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
          rationale: { type: 'string' },
        },
      },
    },
    risks: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
}

const CRITIQUE_SCHEMA = {
  type: 'object',
  required: ['lens', 'gaps', 'suggestions'],
  properties: {
    lens: { type: 'string' },
    gaps: {
      type: 'array',
      items: {
        type: 'object',
        required: ['issue', 'severity'],
        properties: {
          requirement: { type: 'string' },
          issue: { type: 'string' },
          severity: { enum: ['low', 'medium', 'high'] },
        },
      },
    },
    suggestions: { type: 'array', items: { type: 'string' } },
  },
}

const FINAL_SCHEMA = {
  type: 'object',
  required: ['plan', 'mitigations', 'openQuestions', 'readyToImplement'],
  properties: {
    plan: PLAN_SCHEMA,
    mitigations: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
    readyToImplement: { type: 'boolean' },
  },
}

phase('Plan')
const plan = await agent(
  `You are planning an implementation against this spec (the source of truth):\n\n${spec}\n\n` +
    `Produce a stepwise plan: concrete actions, the files each touches, and rationale. ` +
    `List risks and any open questions that block a clean implementation.`,
  { agentType: 'castiel', label: 'plan', schema: PLAN_SCHEMA },
)

phase('Critique')
const LENSES = [
  {
    key: 'spec-coverage',
    agentType: 'sam',
    prompt:
      `Verify this plan COVERS the spec. For every requirement and acceptance criterion, ` +
      `is there a step that satisfies it? Report uncovered requirements as gaps.`,
  },
  {
    key: 'architecture-risk',
    agentType: 'software-architect',
    prompt:
      `Review this plan for architectural soundness and risk: ordering, hidden coupling, ` +
      `failure modes, infra enabled-flags/dependencies. Report weak points as gaps.`,
  },
  {
    key: 'simplicity',
    agentType: 'code-quality-pragmatist',
    prompt:
      `Review this plan for over-engineering and unnecessary complexity. Flag steps that ` +
      `build more than the spec asks (Non-Goals) or add premature abstraction.`,
  },
]

const critiques = (
  await parallel(
    LENSES.map((l) => () =>
      agent(
        `${l.prompt}\n\n## Spec\n${spec}\n\n## Plan\n${JSON.stringify(plan, null, 2)}`,
        { agentType: l.agentType, label: `critique:${l.key}`, phase: 'Critique', schema: CRITIQUE_SCHEMA },
      ),
    ),
  )
).filter(Boolean)

phase('Synthesize')
const final = await agent(
  `Merge the plan and the critiques into a final implementation plan.\n\n` +
    `## Spec\n${spec}\n\n## Plan\n${JSON.stringify(plan, null, 2)}\n\n` +
    `## Critiques\n${JSON.stringify(critiques, null, 2)}\n\n` +
    `Fold high-severity gaps into concrete plan changes. List residual mitigations and ` +
    `open questions. Set readyToImplement=false if any high-severity gap or blocking ` +
    `open question remains.`,
  { agentType: 'castiel', label: 'synthesize', schema: FINAL_SCHEMA },
)

const highGaps = critiques.flatMap((c) => c.gaps).filter((g) => g.severity === 'high')
log(`Plan ready: ${final.readyToImplement}. High-severity gaps found: ${highGaps.length}.`)

return final
