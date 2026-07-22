#!/usr/bin/env node
// Validate the conformance suite's own integrity. Run in harness-ci.
// Checks: schema_version, id format + uniqueness, closed enums, required keys,
// and that every `governing` path resolves to a real harness file.
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'

const evalDir = dirname(fileURLToPath(import.meta.url))
const harnessRoot = resolve(evalDir, '..') // claude/.claude
const errors = []
const REQUIRED = ['id', 'tags', 'observability', 'prompt', 'governing', 'expected', 'forbidden', 'rubric', 'discrimination_status']
const OBSERVABILITY = ['mechanical', 'hybrid', 'judged']
const DISCRIMINATION = ['verified', 'unverified']
const ID_RE = /^S\d{2}-[a-z0-9-]+$/

let doc
try {
  doc = JSON.parse(readFileSync(resolve(evalDir, 'scenarios.json'), 'utf8'))
} catch (e) {
  console.error(`scenarios.json: unparseable — ${e.message}`)
  process.exit(1)
}

if (doc.schema_version !== 1) errors.push(`schema_version must be 1, got ${JSON.stringify(doc.schema_version)}`)
if (!Array.isArray(doc.scenarios) || doc.scenarios.length === 0) errors.push('scenarios must be a non-empty array')

const seen = new Set()
for (const [i, s] of (doc.scenarios ?? []).entries()) {
  const at = `scenario[${i}]${s?.id ? ` (${s.id})` : ''}`
  for (const k of REQUIRED) if (!(k in s)) errors.push(`${at}: missing required key '${k}'`)
  if (s.id !== undefined) {
    if (!ID_RE.test(s.id)) errors.push(`${at}: id must match ${ID_RE}`)
    if (seen.has(s.id)) errors.push(`${at}: duplicate id`)
    seen.add(s.id)
  }
  if (s.observability !== undefined && !OBSERVABILITY.includes(s.observability))
    errors.push(`${at}: observability must be one of ${OBSERVABILITY.join('|')}`)
  if (s.discrimination_status !== undefined && !DISCRIMINATION.some((d) => String(s.discrimination_status).startsWith(d)))
    errors.push(`${at}: discrimination_status must start with ${DISCRIMINATION.join('|')}`)
  for (const arr of ['tags', 'governing', 'expected', 'forbidden']) {
    if (s[arr] !== undefined && (!Array.isArray(s[arr]) || s[arr].length === 0))
      errors.push(`${at}: '${arr}' must be a non-empty array`)
  }
  for (const g of Array.isArray(s.governing) ? s.governing : []) {
    try {
      readFileSync(resolve(harnessRoot, g))
    } catch {
      errors.push(`${at}: governing path '${g}' resolves to no harness file`)
    }
  }
}

if (errors.length) {
  for (const e of errors) console.error(`::error::${e}`)
  console.error(`\nconformance suite invalid: ${errors.length} problem(s)`)
  process.exit(1)
}
console.log(`conformance suite valid: ${doc.scenarios.length} scenarios, all governing paths resolve`)
