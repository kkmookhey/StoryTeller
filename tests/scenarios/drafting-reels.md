# Test: drafting-reels

## Given
A single ScoredSignal (Signal + score + why_postworthy + suggested_angle) chosen from the scoring output with score >= 7.

## When
The `skill/storyteller/references/drafting-reels.md` prompt is applied with `kk-voice`, `kk-short-form`, and `skill/storyteller/references/_drafting-shared.md` loaded.

## Then expect (structural)
A single JSON object with these top-level keys:
- `status` == "ok"
- `platform` == "reels"
- `format` == "script"
- `content_markdown` (string, markdown-formatted script with timestamps — this is the SHOOTING SCRIPT, not a single text block)
- `caption_for_post` (string, <=2200 chars — the Instagram/Shorts caption to publish alongside the video once produced)
- `hashtags` (array of strings, 3-7 items, each starts with "#")
- `audience` (string, one of `"meera"`, `"rohan"`, `"story"`)
- `hold` == true (orchestrator routes to `~/.storyteller/pending-video/<signal_id>-reels.json`)
- `video_pending` == true (Slice G Descript hook reads this flag to know the file is awaiting hydration into actual video)
- `internal_notes` (string)

## Then expect (script structure within `content_markdown`)
- Has a header line starting with `# TITLE:`
- Has metadata lines: `AUDIENCE: meera|rohan|story` and `LENGTH TARGET: <range>`
- Has FOUR timestamped sections (HOOK, SETUP, PAYOFF, CLOSE) each with `[MM:SS–MM:SS]` markers (en-dash or hyphen — validator accepts `[MM:SS` prefix)
- Each section has VO, Text-overlay, and Visual lines

## Then expect (qualitative — second Claude call)
Apply the kk-short-form Pre-Publish Checklist (10 items, in `skill/kk-short-form/SKILL.md`) to the script in `content_markdown`. All 10 must pass — NO deferrals are allowed because this IS the video script, so video-specific items 4 (mute test), 9 (text overlay cadence), 10 (length fits type) apply directly to the script.

## Fail conditions
- `status` missing or not `"ok"`
- `platform` or `format` mismatched
- Missing `content_markdown` or `caption_for_post`
- `hold` is not `true`
- `video_pending` is not `true`
- `audience` not in `["meera", "rohan", "story"]`
- Script missing any of the 4 timestamped sections (HOOK, SETUP, PAYOFF, CLOSE)
- Fewer than 4 timestamp markers (`[MM:SS`)
- `content_markdown` contains banned Reels hooks (greeting bans + lazy hooks listed below) OR any phrase from `tests/banned-phrases.txt` (case-insensitive)
- `caption_for_post` > 2200 chars
- Hashtag count outside 3-7
- Any hashtag missing the `#` prefix
- Script fails any of the 10 kk-short-form checklist items

## Banned Reels hooks (auto-fail in `content_markdown` VO lines)
Per kk-short-form's greeting ban and "Hook formulas to AVOID":
- "hey guys"
- "hi everyone"
- "welcome back"
- "welcome to my channel"
- "the biggest news in"
- "bombshell news"
- "the internet is going crazy about"
- "let me tell you about"
- "guys, you won't believe" (and curly-quote variant)
- "guys you won't believe"
- "in today's video"
- "today we're going to talk about"

## Structural validator (bash)

```bash
python3 -c '
import json, pathlib, re
d = json.load(open("/tmp/reels-script.json"))
assert d.get("status") == "ok", f"status not ok: {d.get(\"status\")}"
assert d["platform"] == "reels" and d["format"] == "script"
assert d["hold"] is True, "hold must be true"
assert d["video_pending"] is True, "video_pending must be true (Slice G reads this)"
assert d["audience"] in ("meera", "rohan", "story"), f"audience invalid: {d[\"audience\"]}"

md = d["content_markdown"]
# Normalize curly quotes to straight quotes for matching
md_norm = md.replace("’", "'").replace("‘", "'").replace("“", "\"").replace("”", "\"")
md_lower = md_norm.lower()

# Header check
assert "# TITLE:" in md, "script missing `# TITLE:` header"
assert "AUDIENCE:" in md, "script missing AUDIENCE metadata line"
assert "LENGTH TARGET:" in md, "script missing LENGTH TARGET metadata line"

# Must have >=4 timestamp markers
ts_markers = re.findall(r"\[\d{2}:\d{2}", md)
assert len(ts_markers) >= 4, f"need >=4 timestamp markers, found {len(ts_markers)}"

# Must have the 4 named sections
for section in ("HOOK", "SETUP", "PAYOFF", "CLOSE"):
    assert section in md, f"script missing section: {section}"

# Banned Reels-specific hooks (normalize quotes before matching)
banned_hooks = [
    "hey guys",
    "hi everyone",
    "welcome back",
    "welcome to my channel",
    "the biggest news in",
    "bombshell news",
    "the internet is going crazy about",
    "let me tell you about",
    "guys, you won't believe",
    "guys you won't believe",
    "in today's video",
    "today we're going to talk about",
]
for b in banned_hooks:
    assert b not in md_lower, f"banned Reels hook found in script: {b!r}"

# General banned phrases
banned = [l.strip() for l in pathlib.Path("tests/banned-phrases.txt").read_text().splitlines() if l.strip()]
hits = [b for b in banned if b in md_lower]
assert not hits, f"banned phrases in script: {hits}"

# Caption length
cap = d["caption_for_post"]
assert isinstance(cap, str), "caption_for_post must be a string"
assert len(cap) <= 2200, f"caption {len(cap)} > 2200"

# Hashtags
tags = d["hashtags"]
assert isinstance(tags, list) and 3 <= len(tags) <= 7, f"hashtag count {len(tags)} outside 3-7"
for t in tags: assert t.startswith("#"), f"hashtag missing #: {t}"

print(f"PASS: audience={d[\"audience\"]}, {len(ts_markers)} timestamps, 4 sections, caption {len(cap)} chars, {len(tags)} hashtags, no banned hooks")
'
```

## Voice-judge validator (kk-short-form 10-item checklist, no deferrals)

A second Claude call reads `/tmp/reels-script.json`, applies all 10 items from kk-short-form's Pre-Publish Checklist to `content_markdown` (the script), and writes per-item JSON to `/tmp/short-form-judgment-reels.json` as an array:

```json
[{"item": 1, "name": "<short>", "passes": true|false, "reason": "<one sentence>"}, ...]
```

Unlike the Instagram-caption judge, NO items may be deferred — this is the video script itself, so items 4 (mute test), 9 (text overlay cadence), and 10 (length fits type) apply directly and must pass on their merits.

```bash
python3 -c '
import json
items = json.load(open("/tmp/short-form-judgment-reels.json"))
assert len(items) == 10, f"expected 10 items, got {len(items)}"
failed = [i for i in items if not i["passes"]]
if failed:
    print("FAILED items:")
    for f in failed:
        print(f"  - #{f[\"item\"]} {f[\"name\"]}: {f[\"reason\"]}")
    raise SystemExit(1)
print("PASS: all 10 kk-short-form checks (no deferrals — this IS the video script)")
'
```
