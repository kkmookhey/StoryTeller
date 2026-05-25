# Test: drafting-linkedin

## Given
A single ScoredSignal (Signal + score + why_postworthy + suggested_angle) chosen from the scoring output with score >= 7.

## When
The `skill/storyteller/references/drafting-linkedin.md` prompt is applied with both `kk-voice` skill and `skill/storyteller/references/_drafting-shared.md` loaded.

## Then expect (structural)
A single JSON object with these top-level keys:
- `status` == "ok"
- `platform` == "linkedin"
- `format` == "long-post"
- `content` (string) — within 140-300 words (hard band); 150-280 is the target (no warn)
- `hashtags` (array of strings, each starts with "#", 2-5 items)
- `internal_notes` (string)

## Then expect (qualitative — second Claude call)
Apply the kk-voice Jennifer pre-publish checklist (7 items) to the `content` field. Must pass all 7.

## Fail conditions
- `status` is missing or not `"ok"`
- `platform` or `format` mismatched
- Word count catastrophically off (< 140 or > 300)
- Hashtags count outside 2-5 (or any tag missing "#" prefix)
- Content contains any phrase from `tests/banned-phrases.txt`
- Content fails any of the 7 Jennifer filter items

## Warn conditions (non-fatal)
- Word count 140-149 or 281-300: requires explicit explanation in `internal_notes` for why the draft landed outside the 150-280 target.

## Structural validator (bash)
```bash
python3 -c '
import json, pathlib
d = json.load(open("/tmp/linkedin-draft.json"))
assert d.get("status") == "ok", f"status not ok: {d.get(\"status\")}"
assert d["platform"] == "linkedin" and d["format"] == "long-post"
wc = len(d["content"].split())
if wc < 140 or wc > 300:
    raise AssertionError(f"word count {wc} catastrophic (outside 140-300)")
warn_band = "" if 150 <= wc <= 280 else f" (WARN: {wc} outside 150-280 — should be explained in internal_notes)"
tags = d["hashtags"]
assert isinstance(tags, list) and 2 <= len(tags) <= 5
for t in tags: assert t.startswith("#")
banned = [l.strip() for l in pathlib.Path("tests/banned-phrases.txt").read_text().splitlines() if l.strip()]
lower = d["content"].lower()
hits = [b for b in banned if b in lower]
assert not hits, f"banned phrases found: {hits}"
print(f"PASS: {wc} words, {len(tags)} hashtags, no banned phrases{warn_band}")
'
```
