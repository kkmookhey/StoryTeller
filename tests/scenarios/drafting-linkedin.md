# Test: drafting-linkedin

## Given
A single ScoredSignal (Signal + score + why_postworthy + suggested_angle) chosen from the scoring output with score >= 7.

## When
The `skill/storyteller/references/drafting-linkedin.md` prompt is applied with `kk-voice` skill loaded.

## Then expect (structural)
A single JSON object with exactly these top-level keys:
- `platform` == "linkedin"
- `format` == "long-post"
- `content` (string) — between 150 and 280 words
- `hashtags` (array of strings, each starts with "#", 2-5 items)
- `internal_notes` (string)

## Then expect (qualitative — second Claude call)
Apply the kk-voice Jennifer pre-publish checklist (7 items) to the `content` field. Must pass all 7.

## Fail conditions
- `platform` or `format` mismatched
- Word count outside 150-280
- Hashtags count outside 2-5 (or any tag missing "#" prefix)
- Content contains banned phrases from kk-voice (e.g., "leverage", "synergy", "excited to announce", "stakeholder buy-in")
- Content fails any of the 7 Jennifer filter items
