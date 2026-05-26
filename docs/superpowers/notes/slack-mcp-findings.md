# Slack MCP Findings

**Date probed:** 2026-05-26
**Auth:** OAuth as KK (`U0EXAMPLE01`), workspace `your-workspace.slack.com` (Transilience AI). Also has access to additional workspaces (`mixedbread.slack.com`, `kwanzooinc.slack.com`) via shared channels.

## Available tools (all verified present)

| Tool | Purpose |
|---|---|
| `mcp__claude_ai_Slack__slack_search_public_and_private` | Cross-channel search with filter operators (primary for Stage 1) |
| `mcp__claude_ai_Slack__slack_search_public` | Same shape but public-only (no DMs/private) |
| `mcp__claude_ai_Slack__slack_search_channels` | Find channel IDs by keyword |
| `mcp__claude_ai_Slack__slack_read_channel` | Read N most-recent messages from a channel; supports `oldest`/`latest` Unix ts bounds |
| `mcp__claude_ai_Slack__slack_read_thread` | Read parent + replies for a given `(channel_id, message_ts)` |
| `mcp__claude_ai_Slack__slack_read_user_profile` | Resolve user ID -> display name (probably needed sparingly) |

All four tools required by the Slice E plan are available.

## Tool chosen for the Slack source adapter

**PRIMARY: `slack_read_channel` with `response_format: "detailed"` + `oldest=<lookback-unix-ts>` per channel.**

Rationale: `slack_read_channel` (detailed format) is the ONLY call that returns BOTH reaction names+counts AND thread reply-count inline in a single round trip. The search tools' result rows do NOT include reaction counts (only reply count, only when the message is a thread root).

**SECONDARY: `slack_search_public_and_private` with `has::<emoji>:` operator** — useful only when we want to cross-channel-find reaction-flagged messages WITHOUT enumerating channels. Slice E enumerates configured channels in config, so the per-channel `slack_read_channel` path is preferred.

**TERTIARY (Stage 2 enrichment if ever needed): `slack_read_thread`** to deep-read a high-signal thread. Not needed for Stage 1 or Stage 2 of the v1 adapter — deferred to Slice F per spec §17.

## Server-side reaction filtering

**`has::<emoji>:` operators work server-side** in `slack_search_*`. Verified examples (all returned matches):

- `has::thumbsup: in:<#C0EXAMPLE01>` -> 5 results
- `has::fire: in:<#C0EXAMPLE03>` -> 1 result
- `has::raised_hands: in:<#C0EXAMPLE01>` -> 3 results
- `has:reactions in:<#C0EXAMPLE01> after:2026-05-01` -> 10 results (any-reaction filter)

**BUT**: the search-result rows do NOT include reaction count or reaction names — only the message text, author, channel, ts, permalink, and (for thread roots) `Reply count: N`. So `has::thumbsup:` tells you "this message has a thumbsup somewhere" but not how many.

**Practical implication**: server-side reaction-emoji filtering is a coarse pre-filter, not a count threshold. To filter by `reaction_count >= 3`, the adapter must either:

1. Use `slack_read_channel` per channel (which DOES return reaction counts inline) and filter client-side — **chosen approach**.
2. Use search with `has::<emoji>:` to narrow candidates, then call `slack_read_thread` per match to enrich with reaction counts — 1 extra round trip per candidate. Rejected as wasteful when path 1 exists.

## Server-side query syntax confirmed

| Operator | Works? | Notes |
|---|---|---|
| `in:<#C12345678>` | yes | Angle brackets are literal for channel IDs |
| `in:#channel-name` | yes (untested but documented) | Names |
| `from:<@U12345678>` | yes | Verified with `from:<@U0EXAMPLE01>` |
| `after:YYYY-MM-DD` | yes | Verified `after:2026-05-01` and `after:2026-05-19` |
| `before:YYYY-MM-DD` | yes (documented, untested) | |
| `has::<emoji>:` | yes | Use raw emoji name, no surrounding spaces |
| `has:reactions` | yes | Any-reaction filter |
| `has:link` / `has:file` / `has:pin` | yes (documented) | |
| `is:thread` | yes (documented) | |
| `-in:<#C123>` | yes (documented, exclude) | |

## Result shape — search vs read_channel vs read_thread

### `slack_search_public_and_private` — formatted-text, NOT JSON

Each result is plain-text formatted like:

```
### Result N of M
Channel: #dev_all (ID: C0EXAMPLE01)
From: KK Mookhey (ID: U0EXAMPLE01)
Time: 2026-05-06 08:47:38 PDT
Message_ts: 1778082458.254019
Reply count: 11                    <-- ONLY when message is a thread root
Permalink: [link](https://your-workspace.slack.com/archives/...)
Text:
<text body, multi-line>
```

Missing fields (vs adapter needs):
- reaction names
- reaction counts
- file attachments
- user display name (only the user_id and a name string are shown; not sure if that's display_name or real_name)

### `slack_read_channel` with `response_format: "detailed"` — formatted-text, richer

```
=== Message from Teammate-B (U0EXAMPLE07) at 2026-05-18 05:35:57 PDT ===
Message TS: 1779107757.459559
Hey all, try running apps on <https://app-test.transilience.cloud/> ...
Thread: 4 replies (latest: 2026-05-18 05:51:37 PDT)
Reactions: eyes (1), party_parrot (1)
```

Has reactions inline, has reply count inline, has files inline when present. This is the goldmine for the adapter.

### `slack_read_thread` — formatted-text with structured per-message reaction lines

```
=== THREAD PARENT MESSAGE ===
From: KK Mookhey (U0EXAMPLE01)
Time: 2026-05-06 08:47:38 PDT
Message TS: 1778082458.254019
Folks - did another thing. ...
Reactions: two_hearts (2), +1 (1)
Files: Shasta Voice Demo.mp4 (ID: F0B1USAP7PD, video/mp4, 5.7 MB)

=== THREAD REPLIES (3 total) ===
--- Reply 1 of 3 ---
From: Teammate-A ...
```

## Permalink resolution

**Built-in `Permalink: <url>` field** — always present in search results AND `slack_read_*` outputs. No client-side construction needed.

Format example: `https://your-workspace.slack.com/archives/C0EXAMPLE01/p1778082458254019?thread_ts=...&cid=C0EXAMPLE01`. The `p<ts-without-dot>` form is the standard Slack permalink encoding.

## Pagination

- `limit` parameter: max 20 for search tools, max 100 for `slack_read_channel`, max 1000 for `slack_read_thread`.
- `cursor` returned in `pagination_info` field as `For the next page of results use cursor \`<opaque>\``.
- For lookback-window reads, `oldest` + `latest` Unix-ts params are simpler than pagination — the adapter sets `oldest = now - lookback_days * 86400` and reads up to `limit=100` per channel. If a single channel emits >100 messages in 7 days the adapter paginates; in practice KK's signal channels don't hit that.

## Authentication & access

- OAuth user-scoped: results scoped to channels KK is a member of. Private channels work via `slack_search_public_and_private`.
- DM channels (`D`-prefixed IDs) ARE accessible via `channel_types=im` but per spec they're OUT OF SCOPE for the Slack source adapter — adapter MUST skip any `D`-prefixed channel.
- Bot messages (`is_bot: true`) excluded by default in search; pass `include_bots: true` to include them. Slice E v1 default: include only human messages; revisit in Slice F if bot postings carry team signal (e.g., Datadog alerts reacted to with `:fire:`).

## Quirks observed

1. **Slack ts format**: `<unix_seconds>.<microseconds>` as a string (e.g., `"1778082458.254019"`). To convert to ISO 8601: `parseFloat(ts) * 1000` → milliseconds → `new Date(ms).toISOString()`. The fractional part is NOT timezone — it's microseconds of the unix ts.

2. **Concise vs detailed format**: `response_format: "concise"` STRIPS reactions and reply counts. The adapter MUST request `detailed` for `slack_read_channel`.

3. **Search rows have NO reaction count** — the highest-friction quirk. This is why the adapter prefers `slack_read_channel` per channel for Stage 1, not search.

4. **`Reply count` only shown for thread roots in search**. A reply inside a thread (e.g., the `thread_ts != ts`) does not display `Reply count`. The permalink encodes `?thread_ts=<root_ts>&cid=<channel>` so the adapter can detect "is this a thread reply?" by checking whether the permalink has `thread_ts` AND whether it differs from `ts`. Replies are usually noise; the adapter filters them out at Stage 1 (only thread ROOTS or unthreaded messages with reactions are signals).

5. **User display name**: search shows `From: <Name> (ID: U...)` but the "Name" is the user's profile display_name or real_name — not the `@username`. For Slack adapter purposes the ID + the rendered name string is enough; we don't need a separate `slack_read_user_profile` round trip.

6. **Reaction name `+1` is literal** — the thumbs-up reaction comes back as `+1 (4)` not `thumbsup (4)`. The query operator is `has::thumbsup:` (the colon-emoji form). Mismatched naming between query (`thumbsup`) and result (`+1`) is something the adapter must tolerate. For other emojis (`fire`, `eyes`, `raised_hands`, `tada`, etc.) the names match.

7. **Workspace inference from permalink**: KK's primary workspace is `your-workspace.slack.com`. Other workspaces (mixedbread, kwanzooinc) appear in shared/external channels. The adapter shouldn't hardcode workspace.

8. **No `is:reaction-count:>=N` operator** — Slack's search syntax has no count threshold for reactions. Confirmed by docs and probe. This is the architectural reason Stage 1 uses `slack_read_channel` + client-side count filter, not search.

## Adapter design implications

1. **Primary fetch path** per channel: `slack_read_channel(channel_id=C, oldest=<7d-ago-unix>, limit=100, response_format="detailed")`. Parse the formatted text, extract per-message: `ts`, `user_id`, `user_display_name`, `text`, `reactions[]` (name + count), `reply_count`, `files[]`, `permalink` (constructable from channel_id + ts, or available in subsequent enrichment).

2. **Stage 1 (reaction-flagged)**: client-side filter `sum(reactions[*].count) >= config.sources.slack.min_reactions` (default 3).

3. **Stage 2 (thread-root fallback)**: client-side filter `reply_count >= config.sources.slack.min_replies` (default 3) AND `(channel_id, ts) NOT IN stage1_signals`. Run ONLY when `len(stage1) < fallback_threshold` (default 6 = 2 * top_n).

4. **Permalink**: extract from `slack_read_channel` output. The detailed format does not show permalink inline for every message — only files have IDs. Permalink construction fallback: `https://<workspace>.slack.com/archives/<channel_id>/p<ts.replace(".", "")>`. The workspace prefix is the only blocker; adapter can either (a) hardcode `your-workspace.slack.com` for now (KK's primary), or (b) make one `slack_search_public_and_private` call per channel and harvest the permalink format from one result. Option (a) is simpler and acceptable for v1.

5. **Skip rules**: filter out (a) `D`-prefixed channel IDs at config-load (DM exclusion), (b) bot messages (`is_bot: true`), (c) thread REPLIES (only roots + unthreaded), (d) Slackbot system messages (`USLACKBOT`).

6. **`response_format` MUST be `"detailed"`** — concise strips the reaction and reply-count fields.

## Sample fixture

See `tests/fixtures/slack-search-sample.json` — 5 normalized message objects representing what the adapter sees AFTER parsing `slack_read_channel` formatted-text output. Includes:

- 1 high-reaction (11 reactions, 4 distinct emojis) thread root with file attachment — Stage 1 hit
- 1 medium-reaction (6) non-thread message — Stage 1 hit
- 1 thread root with low reactions (3) but 8 replies — Stage 1 hit on reaction count, also a thread root
- 1 low-reaction (1) non-thread — should be FILTERED OUT (below `min_reactions: 3`)
- 1 thread root with 6 replies but only 2 reactions — should be picked up by STAGE 2 only

Content anonymized: real customer/teammate names replaced with `[REDACTED-*]` tokens. Channel IDs and ts values are real (low-sensitivity infrastructure metadata).
