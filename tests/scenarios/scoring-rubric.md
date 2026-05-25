# Test: scoring-rubric

## Given
A list of Signal objects produced by the source-github adapter (or any source adapter — the rubric is source-agnostic).

## When
The `skill/storyteller/references/scoring-rubric.md` prompt is applied to the Signal[], with the `kk-voice` skill loaded.

## Then expect
A JSON array, one object per input signal (same length, same order), each with exactly:
- `signal_id` (string, must equal the input signal's `id` field)
- `score` (integer 0-10)
- `why_postworthy` (string, one sentence — what makes this Jennifer-worthy, or why it isn't)
- `suggested_angle` (string, one sentence — angle that would maximize Jennifer-fit)

## Fail conditions
- Length mismatch with input
- Missing `signal_id` on any item
- `signal_id` doesn't match any input signal's `id`
- `score` out of range (not 0-10) or non-integer
- Any required field missing
- Output is not strict JSON (has prose around it, has markdown fence, has trailing content)
