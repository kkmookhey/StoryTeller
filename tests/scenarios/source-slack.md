# Test: source-slack adapter

## Given

Fixture at `tests/fixtures/slack-search-sample.json` — array of 5 Slack message objects in NORMALIZED form (already parsed from `slack_read_channel`'s text output; this fixture represents the post-parse state).

Fixture contents (relevant counts):
- msg 1: rc=11, reps=11 (Stage 1 + also a thread root)
- msg 2: rc=6, reps=0 (Stage 1)
- msg 3: rc=3, reps=8 (Stage 1 + also a thread root)
- msg 4: rc=1, reps=0 (below both thresholds)
- msg 5: rc=2, reps=6 (Stage 2 only — thread root, below reaction threshold)

So at `min_reactions = 3`, `min_replies = 3`: Stage 1 = 3 hits, Stage 2-only = 1 hit, total when fallback fires = 4.

## When

The `skill/storyteller/references/source-slack.md` prompt is applied. Treat the fixture as messages already fetched from one channel via `slack_read_channel` and parsed (skip the parsing step).

## Test 1 — Stage 1 only (fallback OFF)

Thresholds: `min_reactions=3`, `min_replies=3`, `fallback_threshold=2`. Stage 1 produces 3 hits, which is `>= fallback_threshold`, so Stage 2 must NOT activate.

**Expected:** exactly **3** signals — only the rc>=3 messages (msgs 1, 2, 3).

## Test 2 — Stage 1 + Stage 2 (fallback ON)

Thresholds: `min_reactions=3`, `min_replies=3`, `fallback_threshold=6`. Stage 1 produces 3 hits, which is `< fallback_threshold`, so Stage 2 activates and adds msg 5 (reps>=3, not already in Stage 1).

**Expected:** exactly **4** signals — msgs 1, 2, 3 from Stage 1 + msg 5 from Stage 2. Msg 4 still excluded (rc=1 AND reps=0).

## Fail conditions (both tests)

- Missing key on any signal
- `id` doesn't match `slack:<channel>:<ts>` regex
- `summary` is verbatim copy of `text_excerpt`
- Stage 2 activates when it shouldn't (Test 1) or fails to activate when it should (Test 2)
- Duplicate `id`s (a message hitting BOTH filter rules must appear ONCE)
- Output is not strict JSON

## Validator script

```bash
python3 << 'PYEOF'
import json, re, sys
path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/source-slack-out.json"
expected = int(sys.argv[2]) if len(sys.argv) > 2 else 3
data = json.load(open(path))
assert isinstance(data, list), "not a list"
assert len(data) == expected, f"expected {expected} signals, got {len(data)}"
required = {"source","id","url","title","summary","timestamp","author","raw"}
seen_ids = set()
for i, s in enumerate(data):
    missing = required - set(s.keys())
    assert not missing, f"signal {i} missing: {missing}"
    assert s["source"] == "slack", f"signal {i} wrong source: {s['source']}"
    assert re.match(r"^slack:[A-Z0-9]+:\d+\.\d+$", s["id"]), f"signal {i} bad id: {s['id']}"
    assert s["id"] not in seen_ids, f"signal {i} duplicate id: {s['id']}"
    seen_ids.add(s["id"])
    assert s["raw"]["text_excerpt"] != s["summary"], f"signal {i} summary verbatim"
    raw_keys = {"channel_id","ts","reaction_count","reactions","reply_count","text_excerpt","is_thread_root"}
    missing_raw = raw_keys - set(s["raw"].keys())
    assert not missing_raw, f"signal {i} raw missing: {missing_raw}"
print(f"PASS: {len(data)} Slack signals validated against expected={expected}")
PYEOF
```

Invoke as:
- `python3 validator.py /tmp/source-slack-out.json 3` (Test 1 — Stage 1 only)
- `python3 validator.py /tmp/source-slack-out-fallback.json 4` (Test 2 — with Stage 2)

## Note on brief vs. fixture reconciliation

The initial Task 2 brief specified `expected_count = 4` for the default-threshold run and `5` for the fallback run. Counting the fixture: 3 messages have `reaction_count >= 3` and 1 additional message has `reply_count >= 3` without enough reactions. So the realisable counts are 3 (Stage 1 only) or 4 (Stage 1 + Stage 2). The 5 in the brief would require including msg 4 (rc=1, reps=0), which neither filter accepts. This scenario file reflects the fixture's actual filter math, with the thresholds re-tuned to exercise both branches of the fallback conditional.
