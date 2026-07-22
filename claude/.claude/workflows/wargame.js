export const meta = {
  name: 'wargame',
  description: 'Adversarial wargame: red attacks, blue defends, white adjudicates each finding, purple synthesizes a backlog',
  whenToUse: 'Heavy variant of the wargame skill for large targets or many findings per round. Pass { target, maxRounds } as args.',
  phases: [
    { title: 'Attack', detail: 'team-red finds weaknesses' },
    { title: 'Defend', detail: 'team-blue triages findings and designs mitigations' },
    { title: 'Adjudicate', detail: 'team-white rules each finding in parallel' },
    { title: 'Synthesize', detail: 'team-purple builds the prioritized backlog' },
  ],
}

const target = typeof args === 'string' ? args : (args?.target ?? '')
const maxRounds = args?.maxRounds ?? 3
if (!target) {
  log('No target passed as args — pass the spec/plan text, a path, "PR <n>", or "working".')
}

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['mode', 'belowThreshold', 'findings'],
  properties: {
    mode: { enum: ['pre-mortem', 'security-mindset'] },
    belowThreshold: { type: 'boolean' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'title', 'detail', 'severity', 'basis'],
        properties: {
          id: { type: 'string' },
          title: { type: 'string' },
          detail: { type: 'string' },
          severity: { enum: ['low', 'medium', 'high', 'critical'] },
          basis: { enum: ['OBSERVED', 'HYPOTHESIS', 'RECALLED', 'ABSENT'] },
          resolve: { type: 'string' },
        },
      },
    },
  },
}

const DEFENSE_SCHEMA = {
  type: 'object',
  required: ['responses', 'residualRisks'],
  properties: {
    responses: {
      type: 'array',
      items: {
        type: 'object',
        required: ['findingId', 'stance', 'response'],
        properties: {
          findingId: { type: 'string' },
          stance: { enum: ['accept', 'contest', 'defer'] },
          response: { type: 'string' },
        },
      },
    },
    residualRisks: { type: 'array', items: { type: 'string' } },
  },
}

const RULING_SCHEMA = {
  type: 'object',
  required: ['findingId', 'verdict', 'rationale'],
  properties: {
    findingId: { type: 'string' },
    verdict: { enum: ['real', 'mitigated', 'refuted'] },
    rationale: { type: 'string' },
  },
}

const BACKLOG_SCHEMA = {
  type: 'object',
  required: ['actions', 'acceptedRisks', 'summary'],
  properties: {
    actions: {
      type: 'array',
      items: {
        type: 'object',
        required: ['priority', 'title', 'action', 'acceptance'],
        properties: {
          priority: { enum: ['P0', 'P1', 'P2'] },
          title: { type: 'string' },
          source: { type: 'string' },
          action: { type: 'string' },
          acceptance: { type: 'string' },
        },
      },
    },
    acceptedRisks: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
}

const TARGET = `## Target under review\n${target}`
const rounds = []
let converged = false
let stopReason = 'max rounds reached'

for (let round = 1; round <= maxRounds && !converged; round++) {
  const prior = rounds.length
    ? `\n\n## Rulings from prior rounds (do NOT re-raise refuted or mitigated findings; open REAL findings may be deepened)\n` +
      JSON.stringify(rounds.map((r) => ({ round: r.round, rulings: r.rulings })), null, 2)
    : ''

  const red = await agent(
    `Wargame round ${round}. Attack this target and report findings with unique ids (r${round}-1, r${round}-2, ...). ` +
      `Set belowThreshold=true only if the target is too small or mechanical for adversarial review.\n\n${TARGET}${prior}`,
    { agentType: 'team-red', label: `red:r${round}`, phase: 'Attack', schema: FINDINGS_SCHEMA },
  )
  if (!red || red.belowThreshold || red.findings.length === 0) {
    converged = true
    stopReason = red?.belowThreshold ? 'below red-team threshold' : 'red found nothing new'
    log(`Round ${round}: ${stopReason}.`)
    break
  }
  log(`Round ${round}: red raised ${red.findings.length} finding(s).`)

  const blue = await agent(
    `Wargame round ${round}. Defend the target against these red findings. Respond to every finding by id.\n\n` +
      `${TARGET}\n\n## Red findings\n${JSON.stringify(red.findings, null, 2)}`,
    { agentType: 'team-blue', label: `blue:r${round}`, phase: 'Defend', schema: DEFENSE_SCHEMA },
  )

  const rulings = (
    await parallel(
      red.findings.map((f) => () =>
        agent(
          `Wargame round ${round}, single-finding adjudication. Rule on exactly this finding given blue's response. ` +
            `Verify disputed claims yourself before ruling.\n\n${TARGET}\n\n## Finding\n${JSON.stringify(f, null, 2)}\n\n` +
            `## Blue response\n${JSON.stringify(blue?.responses.find((r) => r.findingId === f.id) ?? 'none — rule REAL', null, 2)}\n\n` +
            `## Blue residual risks\n${JSON.stringify(blue?.residualRisks ?? [], null, 2)}`,
          { agentType: 'team-white', label: `white:${f.id}`, phase: 'Adjudicate', schema: RULING_SCHEMA },
        ),
      ),
    )
  ).filter(Boolean)

  rounds.push({ round, findings: red.findings, defense: blue, rulings })
  const open = rulings.filter((r) => r.verdict === 'real').length
  converged = open === 0
  if (converged) stopReason = 'converged: no open REAL findings'
  log(`Round ${round} adjudicated: ${open} REAL, ` +
    `${rulings.filter((r) => r.verdict === 'mitigated').length} mitigated, ` +
    `${rulings.filter((r) => r.verdict === 'refuted').length} refuted.`)
}

phase('Synthesize')
const synthesis = rounds.length
  ? await agent(
      `The wargame is over (${stopReason}). Synthesize the full transcript into a prioritized backlog ` +
        `and accepted residual risks.\n\n${TARGET}\n\n## Transcript\n${JSON.stringify(rounds, null, 2)}`,
      { agentType: 'team-purple', label: 'purple', schema: BACKLOG_SCHEMA },
    )
  : null

return { roundsPlayed: rounds.length, stopReason, rounds, synthesis }
