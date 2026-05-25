# Test: drafting-x-thread

## Given
A single ScoredSignal (Signal + score + why_postworthy + suggested_angle) chosen from the scoring output with score >= 7.

## When
The `skill/storyteller/references/drafting-x-thread.md` prompt is applied with both `kk-voice` skill and `skill/storyteller/references/_drafting-shared.md` loaded.

## Then expect (structural)
A single JSON object with these top-level keys:
- `status` == "ok"
- `platform` == "x"
- `format` == "thread"
- `content` (array of 3-5 strings, each `<= 280` chars)
- `hashtags` (array of strings, 0-3 items, each starts with "#")
- `internal_notes` (string)

## Then expect (qualitative — second Claude call)
Apply the kk-voice Jennifer pre-publish checklist (7 items) to the JOINED thread (concatenate posts in `content` with `\n\n` for the judge call). Must pass all 7.

## Fail conditions
- `status` is missing or not `"ok"`
- `platform` or `format` mismatched
- Thread length outside 3-5 posts
- Any post in `content` exceeds 280 chars
- Hashtag count > 3 (X threads are noisy — keep tags minimal)
- Any hashtag missing the "#" prefix
- Any post contains a phrase from `tests/banned-phrases.txt`
- Joined thread fails any of the 7 Jennifer filter items

## Structural validator (bash)
```bash
python3 -c '
import json, pathlib
d = json.load(open("/tmp/x-thread.json"))
assert d.get("status") == "ok", f"status not ok: {d.get(\"status\")}"
assert d["platform"] == "x" and d["format"] == "thread"
assert isinstance(d["content"], list)
assert 3 <= len(d["content"]) <= 5, f"thread length {len(d[\"content\"])} outside 3-5"
for i, p in enumerate(d["content"]):
    assert isinstance(p, str), f"post {i} not a string"
    assert len(p) <= 280, f"post {i} is {len(p)} chars, exceeds 280"
tags = d["hashtags"]
assert isinstance(tags, list) and 0 <= len(tags) <= 3, f"hashtag count {len(tags)} outside 0-3"
for t in tags: assert t.startswith("#"), f"hashtag missing #: {t}"
banned = [l.strip() for l in pathlib.Path("tests/banned-phrases.txt").read_text().splitlines() if l.strip()]
for i, p in enumerate(d["content"]):
    lower = p.lower()
    hits = [b for b in banned if b in lower]
    assert not hits, f"post {i} banned phrases: {hits}"
total_chars = sum(len(p) for p in d["content"])
print(f"PASS: {len(d[\"content\"])} posts, {total_chars} chars total, {len(tags)} hashtags, no banned phrases")
'
```
