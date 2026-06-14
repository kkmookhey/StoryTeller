# Source: Slack

Normalize raw Slack messages (from `mcp__claude_ai_Slack__slack_read_channel`) into the Fitzroy Signal shape.

**REQUIRED BACKGROUND:** Read `docs/superpowers/notes/slack-mcp-findings.md` for the exact MCP behavior, text-format quirks, and KK's reachable channels.

## Design (one round trip per channel, two-stage filter)

Unlike a naive two-fetch design (search for reactions, then re-read for threads), `slack_read_channel` with `response_format: "detailed"` returns BOTH reaction names+counts AND thread reply_count INLINE in a single call. So this adapter:

1. Fetches each configured channel ONCE.
2. Parses the formatted text into a per-message intermediate.
3. Applies Stage 1 (reactions filter) over the parsed set.
4. If Stage 1 yields fewer hits than `fallback_threshold`, applies Stage 2 (thread-root fallback) over the SAME already-parsed set.
5. Dedupes by `(channel_id, ts)` so a message that satisfies both filters appears once.
6. Transforms survivors into Signal objects.

No second network call. The "two-stage fetch" intent of the spec is preserved as a two-stage FILTER over single-fetch data.

## Fetch (one call per channel)

For each `channel_id` in `config.sources.slack.channels`:

```python
# Compute oldest timestamp (lookback window)
oldest_unix = int(time.time() - config.sources.slack.lookback_days * 86400)
```

Skip any `channel_id` that starts with `D` (DM channels — out of scope per spec §4.4 and findings §Authentication).

Call:
```
mcp__claude_ai_Slack__slack_read_channel(
  channel_id=channel_id,
  oldest=str(oldest_unix),
  limit=100,
  response_format="detailed"
)
```

`response_format` MUST be `"detailed"`. The `"concise"` format strips reactions and reply counts (per findings §Quirks #2).

## Parsing the MCP text output

The MCP returns a FORMATTED TEXT block (NOT JSON). It looks like:

```
=== Messages from channel C... ===
[N messages found]

### Message 1
Author: <name or user_id>
Posted: <ISO 8601 or human-readable timestamp>
TS: 1716537600.001234
Text: <message text, may span multiple lines>
Reactions: +1 (4), fire (2)
Replies: 8
[Permalink not present — construct per findings doc]

### Message 2
...
```

Parse each `### Message N` block into a normalized intermediate object with keys: `ts`, `author`, `text` (full body), `reactions` (list of `{name, count}`), `reaction_count` (int — sum of counts), `reply_count` (int, 0 if absent), `is_thread_root` (bool — true iff reply_count > 0).

### Parsing notes

- `TS:` line gives the Slack message ts (string with decimal, e.g. `1716537600.001234`). USE THIS as the canonical identifier.
- `Reactions:` line format is `name1 (count1), name2 (count2)`. Parse the comma-separated list. If line absent, `reactions = []`, `reaction_count = 0`.
- `Replies: N` line means thread root with N replies. If absent or `Replies: 0`, `reply_count = 0` and `is_thread_root = false`. If present and N > 0, `is_thread_root = true`.
- `Author:` may be a display name or a user_id (starts with `U`). Pass through verbatim — downstream consumers handle either.
- `Text:` body may span multiple lines until the next `Reactions:` / `Replies:` / `### Message` boundary. Capture the full text.
- Reaction name `+1` is literal (the thumbs-up emoji). Do NOT rename it to `thumbsup`. Lowercase reaction names as-is.

### Parsing fragility note

The MCP's text format is implementation-defined and could change. If the parsed-message count is 0 but the raw response contains the substring `Messages from channel` AND a non-zero count, treat it as a parse failure (log to stderr, skip that channel) rather than silently returning empty. A reliable indicator that the format has drifted: zero `### Message ` block markers despite `[N messages found]` with N > 0.

## Skip rules (apply during parsing)

Drop messages where:
- The user_id is `USLACKBOT` (Slack system messages).
- The block indicates a bot post AND `include_bots` was not explicitly enabled. (`slack_read_channel` excludes bots by default; this is belt-and-suspenders.)

Note on thread replies: a reply (where the permalink encodes `thread_ts=<parent_ts>` with `parent_ts != ts`) is NOT excluded by default. If a reply itself carries `reaction_count >= min_reactions`, it's a legitimate signal — the team explicitly emoji-marked it. The reply's own ts is the Signal identifier. Stage 2 (thread-root fallback) still only considers messages with `reply_count > 0` (which are roots by definition), so the fallback path remains root-only.

If `slack_read_channel` returns an error (channel not accessible, permission denied, MCP timeout): log to stderr and SKIP that channel — continue with remaining channels. If ALL channels fail, return `[]` (empty JSON array, NOT an error object — per cross-format error contract, same as `source-github.md`).

## Stage 1 — reactions filter

From the parsed messages across ALL channels, keep those with `reaction_count >= config.sources.slack.min_reactions` (default 3).

Call this set `stage_1`.

## Stage 2 — thread-root fallback (conditional)

If `len(stage_1) >= config.sources.slack.fallback_threshold` (default 6, or `2 × scoring.top_n`): SKIP Stage 2. Sufficient signal already.

If `len(stage_1) < fallback_threshold`: ALSO include messages where `reply_count >= config.sources.slack.min_replies` (default 3) — regardless of reaction count.

Call the union (Stage 1 + Stage 2 hits) `survivors`.

**Dedupe:** A message that satisfies BOTH Stage 1 AND Stage 2 (e.g., 5 reactions AND 8 replies) appears ONCE in `survivors`. Dedupe key: `(channel_id, ts)`.

**Threshold scope:** `fallback_threshold` is compared against the GLOBAL Stage 1 count (summed across ALL configured channels), not per-channel. The whole adapter run decides "do we have enough reaction signal overall" before falling back.

## Per-message → Signal transformation

For each survivor, produce:

```json
{
  "source": "slack",
  "id": "slack:<channel_id>:<ts>",
  "url": "https://<workspace>.slack.com/archives/<channel_id>/p<ts_no_dot>",
  "title": "<first 80 chars of text, newlines replaced by single space, no trailing ellipsis>",
  "summary": "<2-4 sentence synthesis — see rules below>",
  "timestamp": "<ts converted to ISO 8601 UTC, second precision>",
  "author": "<author from parsed Author: line>",
  "raw": {
    "channel_id": "<the channel_id passed to slack_read_channel>",
    "ts": "<message ts as string, e.g., '1716537600.001234'>",
    "reaction_count": <integer; sum of all reaction counts; 0 if no reactions line>,
    "reactions": [<list of lowercased reaction name strings, e.g., ["+1","fire"]>],
    "reply_count": <integer reply count; 0 if absent>,
    "text_excerpt": "<first 500 chars of message text, preserve newlines>",
    "is_thread_root": <true if reply_count > 0, else false>
  }
}
```

### URL construction

The `<ts_no_dot>` is the ts with the `.` removed and prefixed by `p`. Example: ts `1716537600.001234` → URL fragment `p1716537600001234`.

`<workspace>` is the workspace subdomain. Default: `your-workspace` (KK's primary, per findings §Quirks #7). Override via the `{workspace_subdomain}` template variable below. The adapter does NOT hardcode workspace at the prompt level — `your-workspace` is the documented v1 default but the caller is expected to pass the correct subdomain.

If the parsed `Permalink:` field is present in the MCP output for a message, prefer THAT verbatim over the constructed URL (it embeds the correct workspace and thread context). The constructor is the fallback.

### Timestamp conversion

```python
from datetime import datetime, timezone
iso = datetime.fromtimestamp(int(float(ts)), tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
```

Slack ts is Unix seconds with sub-second precision; truncate to second precision for the ISO output.

### Title rules

- Take first 80 chars of the message text.
- Replace `\n` with single space.
- Collapse runs of whitespace to single space.
- Strip leading/trailing whitespace.
- Do NOT add trailing `...` even if the text is longer than 80 chars. (Downstream code can append an ellipsis if it chooses.)

### Summary writing rules (anti-verbatim — same policy as `source-github.md`)

The `summary` is for the scorer to judge post-worthiness. It MUST follow ALL of these rules:

1. **2-4 sentences.** Prose. No bullets, no headings, no markdown.
2. **Synthesize, do not copy.** Must NOT contain any sentence verbatim from `raw.text_excerpt`. If you find yourself copying a phrase longer than ~10 consecutive words, rewrite it.
3. **`summary` MUST differ from `raw.text_excerpt`.** Hard invariant — the validator checks `summary != text_excerpt`.
4. **Describe what the message conveys + the team's reaction signal.** Capture: what was said, why it likely caught reactions/replies, and (if thread root) one-line gist of the conversation.
5. **Don't restate the title verbatim.**
6. **Cite the reaction signal in plain English.** Example: "6 reactions (raised_hands, +1) — team cheered the catch."
7. **Empty/trivial text:** if the message text is empty or under ~30 chars, derive summary from the title + reaction names + reply count, and include the phrase `minimal text provided`.

Example (do):
> Customer X closed on the AI-SPM POC after 3 sales cycles. 11-reply thread — engineering reviewing the win pattern. 11 reactions (fire, +1, rocket) — team thought this was a notable close.

Example (don't, verbatim copy):
> Folks - did another thing. Voice App now integrated with [REDACTED-product]. So real data, real conversations.

## Edge cases

- **Bot messages:** `slack_read_channel` excludes bots by default (`include_bots=false`). If one slips through, exclude unless KK's own reactions to it ARE the signal.
- **File-only messages (text empty, attachment present):** If `text` is empty/whitespace but the message has visible attachments, derive title from the first attachment's title if available, else use `[file attachment]`. The summary should describe the file purpose if discernible from filename.
- **Channel quirks:** Some channels (announcements-only) have high reaction counts on low-substance messages. The scorer downstream filters those (hard-zero "internal/admin").
- **Reactions field absent:** Treat as `reaction_count = 0, reactions = []`. Do NOT error.
- **Replies field absent:** Treat as `reply_count = 0, is_thread_root = false`. Do NOT error.
- **Message with reactions but text is just an emoji or `<@U...>` mention:** Still emit a Signal — the scorer can downweight it. The adapter's job is filter-by-threshold, not judge-substance.

## Output

Return a strict JSON array of Signals. No prose around it, no markdown fence, no commentary. The first character of the output MUST be `[` and the last `]`. If zero survivors, return `[]`.

## Inputs (template variables substituted by caller)

- `{channels_json}` — JSON array of channel IDs to fetch from. DM channels (`D` prefix) are skipped at parse time.
- `{lookback_days}` — integer; default 7.
- `{min_reactions}` — integer; default 3 (Stage 1 threshold).
- `{min_replies}` — integer; default 3 (Stage 2 threshold).
- `{fallback_threshold}` — integer; default `2 × scoring.top_n` (i.e. 6 with default `top_n: 3`).
- `{workspace_subdomain}` — string; default `your-workspace`. Used to construct URLs when MCP `Permalink:` is absent.
