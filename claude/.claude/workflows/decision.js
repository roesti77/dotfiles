export const meta = {
  name: 'decision',
  description: 'Weigh a decision: steelman FOR and devil AGAINST each option, then a neutral judge recommends',
  whenToUse: 'Choosing between options or a go/no-go where fair comparison matters. Pass { decision, options?, criteria? } as args.',
  phases: [
    { title: 'Argue', detail: 'steelman + devil per option, in parallel' },
    { title: 'Decide', detail: 'judge weighs all cases and recommends' },
  ],
}

const decision = typeof args === 'string' ? args : (args?.decision ?? '')
const options = args && Array.isArray(args.options) && args.options.length ? args.options : [decision || 'the proposed action']
const criteria = (args && Array.isArray(args.criteria) && args.criteria.length) ? args.criteria : null
if (!decision) {
  log('No decision passed — pass { decision, options?, criteria? } as args.')
}

const FOR_SCHEMA = {
  type: 'object',
  required: ['strongestCase', 'strengths'],
  properties: {
    strongestCase: { type: 'string' },
    bestConditions: { type: 'array', items: { type: 'string' } },
    strengths: {
      type: 'array',
      items: {
        type: 'object',
        required: ['point', 'impact'],
        properties: { point: { type: 'string' }, impact: { type: 'string' } },
      },
    },
    acknowledgedCosts: { type: 'array', items: { type: 'string' } },
  },
}

const AGAINST_SCHEMA = {
  type: 'object',
  required: ['strongestCaseAgainst', 'failureConditions'],
  properties: {
    strongestCaseAgainst: { type: 'string' },
    failureConditions: {
      type: 'array',
      items: {
        type: 'object',
        required: ['condition', 'mechanism'],
        properties: { condition: { type: 'string' }, mechanism: { type: 'string' }, outcome: { type: 'string' } },
      },
    },
    hiddenCosts: { type: 'array', items: { type: 'string' } },
    precedent: { type: 'string' },
  },
}

const DECISION_SCHEMA = {
  type: 'object',
  required: ['criteria', 'recommendation', 'confidence', 'decisiveFactor', 'flipConditions'],
  properties: {
    criteria: { type: 'array', items: { type: 'string' } },
    criteriaInferred: { type: 'boolean' },
    recommendation: { type: 'string' },
    confidence: { enum: ['low', 'medium', 'high'] },
    decisiveFactor: { type: 'string' },
    runnersUp: {
      type: 'array',
      items: {
        type: 'object',
        required: ['option', 'reason'],
        properties: { option: { type: 'string' }, reason: { type: 'string' } },
      },
    },
    flipConditions: { type: 'array', items: { type: 'string' } },
  },
}

const CTX = `## Decision\n${decision}\n\n## Options\n${options.map((o, i) => `${i + 1}. ${o}`).join('\n')}` +
  (criteria ? `\n\n## Criteria\n${criteria.map((c) => `- ${c}`).join('\n')}` : '\n\n## Criteria\nNone given — infer and state them.')

phase('Argue')
const cases = await parallel(
  options.map((opt) => () =>
    parallel([
      () =>
        agent(
          `${CTX}\n\nBuild the strongest HONEST case FOR this option only: "${opt}". No strawmen, no fabricated benefits, acknowledge real costs.`,
          { agentType: 'decision-steelman', label: `for:${opt}`, phase: 'Argue', schema: FOR_SCHEMA },
        ),
      () =>
        agent(
          `${CTX}\n\nBuild the strongest HONEST case AGAINST the best version of this option only: "${opt}". Attack the steelman, not a strawman. Propose no alternative.`,
          { agentType: 'decision-devil', label: `against:${opt}`, phase: 'Argue', schema: AGAINST_SCHEMA },
        ),
    ]).then(([forCase, againstCase]) => ({ option: opt, forCase, againstCase })),
  ),
)

phase('Decide')
const verdict = await agent(
  `${CTX}\n\n## Cases per option\n${JSON.stringify(cases.filter(Boolean), null, 2)}\n\n` +
    `Weigh each option's FOR case against its AGAINST case on the criteria (infer and state them if none were given). ` +
    `Recommend one option (or an explicit "no clear winner" with what would settle it). Name the decisive factor, ` +
    `the runners-up with the criterion each lost on, and the flip conditions.`,
  { agentType: 'decision-judge', label: 'judge', schema: DECISION_SCHEMA },
)

log(`Recommendation: ${verdict?.recommendation ?? 'n/a'} (confidence: ${verdict?.confidence ?? 'n/a'})`)
return { decision, options, cases: cases.filter(Boolean), verdict }
