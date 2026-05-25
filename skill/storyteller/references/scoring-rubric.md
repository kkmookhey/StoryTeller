# Scoring Rubric: Jennifer Filter

Score each Signal for post-worthiness against KK Mookhey's LinkedIn audience filter (Jennifer Chen). Produce one score per signal, in input order, as strict JSON.

## REQUIRED: Load the voice skill first

Before applying this rubric, load the `kk-voice` skill (installed at `~/.claude/skills/kk-voice/`). The Jennifer Chen audience profile inside `kk-voice` — including the 7-item pre-publish checklist, the "what she stops scrolling for" list, and the instant-unfollow triggers — is the **single source of truth** for what counts as Jennifer-worthy.

This rubric is a numeric distillation of that checklist. Do **not** infer Jennifer's profile from this file alone. If `kk-voice` is not loaded, stop and load it.

## The 5-criterion rubric

Each criterion contributes 0, 1, or 2 points. Sum the five. Cap the total at 10.

| # | Criterion | 0 | 1 | 2 |
|---|---|---|---|---|
| 1 | **Specific operational substance** — named tools, real numbers, concrete scenario | Abstract/generic ("vuln management is broken"); no named tools, no numbers | Some specificity (one tool OR one number) but rest is hand-wavy | Named tools AND numbers AND a concrete scenario Jennifer recognises from her own seat |
| 2 | **Borrowable insight** — Jennifer can paraphrase in her next meeting and sound sharper | No reusable takeaway; pure announcement, log entry, or status update | Has a takeaway but it's well-known or only narrowly useful | Distinct, transferable mental model, framework, or numbered finding she'd screenshot for her CISO |
| 3 | **Receipts vs generalities** — real outcomes, not abstract claims | Pure claims with no evidence ("AI will transform X") | Mix: some evidence, some assertion without backup | Concrete outcome with the numbers/diff/before-after that prove it actually happened |
| 4 | **Operator voice over founder voice** — centers "what we saw doing the work" | Founder-journey framing ("how we built", "our ARR", "excited to announce") | Neutral — neither operator nor founder voice dominates | Practitioner-first: centers the engineering decision, the trade-off, what broke, what we learned doing the work |
| 5 | **Problem-before-product** — if Transilience appears, problem dominates first 80% | Product (Transilience) leads; problem appears late or not at all | Product and problem are balanced or interleaved | Problem dominates the first 80%; product (if present) only appears in the closing |

**Criterion 5 is conditional.** If Transilience does not appear in the signal at all, criterion 5 defaults to 2 (not applicable, no penalty). This is the spec's intent — the criterion exists to discipline product-pitchy posts about Transilience specifically.

**Score = sum, capped at 10.** Five criteria × 2 = 10 max, so the cap rarely binds, but apply it defensively.

## Precedence

Apply checks in this order, and stop at the first that fires:

1. **Hard-zero check.** If the signal matches any hard-zero rule below, score = 0, write `why_postworthy` naming which rule fired, set `suggested_angle` to `"(hard-zero; no draft)"`. Skip the rubric.
2. **5-criterion rubric.** If no hard-zero fires, score each criterion 0-2, sum, cap at 10.

Edge case: a signal that contains "excited to announce" phrasing BUT ALSO contains substantive receipts and an extractable lesson is NOT a hard-zero — fall through to the rubric. The hard-zero rule is for material whose entire purpose IS the announcement, with no transferable substance.

## Hard zeros — score 0 and move on

If any of the following apply, the signal is unpostable. Score 0 regardless of the rubric and explain briefly in `why_postworthy`. Do not waste a draft slot.

- **Internal HR / admin** — vacation announcements, team restructures, hiring posts with no extractable insight, org-chart changes
- **Customer-confidential without an extractable lesson** — anonymising would gut the substance
- **India / ME regional only with no universal lesson** — DPDPA, SAMA, NCA, India-specific regulatory content used as subject, not color (per kk-voice anti-patterns)
- **"Excited to announce" material** — launches, awards, conference logos, milestones without an underlying lesson
- **Pure dependency bumps, lint fixes, trivial chore PRs** — `bump foo from 1.2 to 1.3`, formatting-only changes, README typo fixes, CI config tweaks with no narrative

## What to score against

Use both `summary` and `raw.body_excerpt` together. The `summary` is the scorer-friendly synthesis from the source adapter; `body_excerpt` is the raw evidence. If they disagree, trust `body_excerpt` for substance and use `summary` for framing. The `title` is the hook — use it to gut-check the "would Jennifer stop scrolling" instinct from criterion 1.

## Worked examples

**Example A — typical infra PR (likely low score):**
- Title: `chore(deps): bump axios from 1.6.0 to 1.7.2`
- Expected score: **0** (hard zero: pure dependency bump)
- `why_postworthy`: "Dependency bump with no narrative or lesson — falls under hard-zero rule."
- `suggested_angle`: "Skip — no Jennifer-relevant insight to extract."

**Example B — substantive product PR (mid-to-high score):**
- Title: `feat(cme-v2): rewrite tables for 5 AI frameworks (source-verified)`
- Body mentions: 65 source-verified entries across MITRE ATLAS, OWASP LLM Top 10, EU AI Act, NIST AI RMF, NIST AI 600-1; surfaces real upstream label-drift bugs (ATLAS v4 labels outdated, EUAI-52 vs Article 50 numbering bug).
- Expected score: **6-8** — named frameworks (criterion 1: 2), borrowable insight about scanner-vendor taxonomy drift (criterion 2: 1-2), real bug receipts (criterion 3: 2), operator voice (criterion 4: 2), product appears but problem-first (criterion 5: 1-2).
- `why_postworthy`: "Names 5 specific AI frameworks and surfaces concrete taxonomy drift bugs (ATLAS v4, EUAI-52) that any Deputy CISO running scanner output sees but rarely names publicly."
- `suggested_angle`: "Lead with 'your scanner is lying to you about which framework you're failing' — then the three concrete drift examples."

## Error handling

Source-level failures must NEVER propagate as exceptions or prose. The orchestrator expects this prompt to always return a valid JSON array.

- If the input is an empty array `[]`, return `[]` (no scores to produce).
- If a signal is missing any of these 4 fields the rubric actually reads — `id`, `title`, `summary`, or `raw.body_excerpt` — score it 0, write `why_postworthy` naming the missing field, and continue with the rest. Other Signal fields (`source`, `url`, `timestamp`, `author`) are NOT required by this rubric and their absence is not an error here. Adapter-level field completeness is the orchestrator's concern, not the scorer's.
- If a signal has `id` but no usable content, still emit an entry with the correct `signal_id` so the orchestrator can zip positionally.
- Never throw. Never return prose. Never return `null`. Always return a JSON array (possibly empty).

## Output

Return a strict JSON array, one object per input signal, in the same order as the input. No prose around it, no markdown fence, no commentary. The first character of the output must be `[` and the last `]`.

```json
[
  {
    "signal_id": "<exact id from input>",
    "score": <integer 0-10>,
    "why_postworthy": "<one sentence — what makes this Jennifer-worthy, or why it isn't>",
    "suggested_angle": "<one sentence — angle that would maximise Jennifer-fit>"
  }
]
```

Maintain input order. The orchestrator zips signals with scores positionally — order is part of the contract.

## Input

Inputs are passed as `{signals_json}` — the orchestrator substitutes the actual JSON array of Signals at call time.
