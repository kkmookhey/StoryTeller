# Publish — Postiz (via CLI)

Push a single Draft to Postiz as a DRAFT post (never published immediately).

**REQUIRED:** Read `docs/superpowers/notes/postiz-cli-findings.md` for the exact CLI semantics. This reference encodes the operational invocation; that note is the source of truth if the CLI behavior is ever in question.

**REQUIRED BACKGROUND:** The `postiz` Claude Code skill (from `postiz@claude-plugins-official`) — its SKILL.md describes the CLI's hard rules. Specifically: media files MUST go through `postiz upload` first; raw paths or external URLs to `-m` are rejected.

**Image attachment** (Slice F+): if the orchestrator generated a shared image for the signal (`~/.storyteller/images/<safe_signal_id>.png`), upload it once and attach to the corresponding `-c` post. See "Media upload" below.

## Input

A single Draft JSON object — already validated by the drafter, with `status: "ok"` and NOT `hold: true`. In Slice D that means LinkedIn `long-post` or X `thread`.

LinkedIn long-post shape (`content` is a single string):

```json
{
  "status": "ok",
  "platform": "linkedin",
  "format": "long-post",
  "content": "<post body as one string, \\n line breaks between paragraphs>",
  "hashtags": ["#cybersecurity", "..."],
  "internal_notes": "..."
}
```

X thread shape (`content` is an array of strings, one per thread post):

```json
{
  "status": "ok",
  "platform": "x",
  "format": "thread",
  "content": ["<post 1>", "<post 2>", "<post 3>"],
  "hashtags": ["#promptinjection"],
  "internal_notes": "..."
}
```

The publisher also needs `config.publishing.postiz.integrations[draft.platform]` from `~/.storyteller/config.yaml` to look up the integration ID.

## Pre-call validation (defense in depth)

Before invoking `postiz`, validate the input. The orchestrator should have already filtered, but check anyway — a bad call to the CLI is more expensive than a bounce here.

1. `draft.status == "ok"` — else fail-fast.
2. `draft.hold` is NOT `true` — else this draft should have been routed to `~/.storyteller/pending-video/` by the orchestrator; do not publish.
3. `draft.platform` is one of `"linkedin"` or `"x"` (Slice D scope).
4. `config.publishing.postiz.integrations[draft.platform]` exists and is a non-empty string.
5. `POSTIZ_API_KEY` env var is set in the current shell (the CLI will error otherwise — check first for a clearer message).
6. For X threads (`format: "thread"`): `draft.content` is a list of strings, each `<= 280` chars (drafter should have validated, but defense).
7. For LinkedIn (`format: "long-post"`): `draft.content` is a single string (non-empty).

If any precheck fails, return the failure envelope WITHOUT calling the CLI:

```json
{"status": "failed", "platform": "<draft.platform>", "error": "<short reason>", "draft_json": <the input draft>}
```

## Media upload (when an image is available for this signal)

Before calling `posts:create`, upload the image once. Cache the result; if the same image is attached to multiple posts in this run (LinkedIn AND X for the same signal), upload ONCE and reuse the returned reference.

Verified empirically 2026-05-26: `postiz upload <file>` prints a banner line then a JSON object. Pin to the `.path` key, which is the public uploads URL the publishing step needs.

```bash
# The image path returned by gen_image.sh — note extension may be .jpg OR .png
# depending on what Gemini returned. The orchestrator should keep the actual
# path that gen_image.sh echoed.
IMG="$IMG_PATH_FROM_GEN_IMAGE"
MEDIA_REF=""
if [[ -f "$IMG" ]]; then
  UPLOAD_JSON=$(postiz upload "$IMG" 2>&1 | grep -v '^✅')
  MEDIA_REF=$(echo "$UPLOAD_JSON" | jq -r '.path // empty' 2>/dev/null)
  if [[ -z "$MEDIA_REF" ]]; then
    echo "postiz upload returned unexpected shape: $UPLOAD_JSON" >&2
    # Continue text-only; image is enhancement, not gate.
  fi
fi
```

Reference return shape (2026-05-26):
```json
{
  "id": "2baa54d4-50c8-4e64-820d-a6bc3fc6a18b",
  "name": "1CmKuOurNd.jpg",
  "originalName": null,
  "path": "https://uploads.postiz.com/1CmKuOurNd.jpg",
  "thumbnail": null,
  "alt": null
}
```

`.path` is what `posts:create -m` consumes. `.id` is the internal uploads-table ID and is NOT what `-m` accepts.

**Per-format attachment rules:**
- **LinkedIn:** ONE image, attached to the single `-c`. Pass `-m "$MEDIA_REF"` once.
- **X thread:** image attaches to POST 1 ONLY by default — anchor the visual to the hook. Pass `-m "$MEDIA_REF"` ONCE, right after the first `-c`. Subsequent `-c` posts get no `-m`. Per the CLI examples, `-m` applies to the immediately preceding `-c` when used multi-time; a single `-m` after the first `-c` attaches there only.
- **If `MEDIA_REF` is empty** (no image, or upload failed): omit `-m` entirely. Posts publish text-only.

## The Bash invocation (per format)

### LinkedIn long-post (one `-c`, optional one `-m`)

```bash
postiz posts:create \
  -c '<draft.content, shell-escaped>' \
  ${MEDIA_REF:+-m "$MEDIA_REF"} \
  -t draft \
  -s "<current-utc-timestamp>" \
  -i "<integration_id>"
```

The `${MEDIA_REF:+-m "$MEDIA_REF"}` expands to `-m <ref>` when set, or expands to nothing when empty — clean text-only fallback without conditional branching.

### X thread (repeated `-c` per post, `-d 0` for no delay between thread posts)

Image attaches to post 1 only. Place `-m "$MEDIA_REF"` immediately after the first `-c`.

```bash
postiz posts:create \
  -c '<draft.content[0]>' \
  ${MEDIA_REF:+-m "$MEDIA_REF"} \
  -c '<draft.content[1]>' \
  -c '<draft.content[2]>' \
  -d 0 \
  -t draft \
  -s "<current-utc-timestamp>" \
  --settings '{"who_can_reply_post":"everyone"}' \
  -i "<integration_id>"
```

Repeat `-c` for every post in the thread (3 to 5 posts per the X drafter contract).

**X requires `--settings '{"who_can_reply_post":"everyone"}'`.** Without it, the CLI fails with HTTP 400: `posts.0.settings.who_can_reply_post must be one of the following values: everyone, following, mentionedUsers, subscribers, verified`. Verified empirically 2026-05-25. Other valid values (`following`, `mentionedUsers`, `subscribers`, `verified`) restrict who can reply on the published tweet — `everyone` is the default-permissive choice and matches KK's existing X reply settings. LinkedIn does NOT need `--settings`.

### Key invocation rules (from findings doc)

- `-t draft` — explicit draft-type flag. Without this, Postiz defaults to `schedule` and the post would be queued for publish at `-s` time. Always pass `-t draft`.
- `-s "<future-utc-timestamp>"` — REQUIRED even for drafts (the CLI rejects calls without `-s`). Use **now + 24h**, captured via `date -u -v+1d +%Y-%m-%dT%H:%M:%SZ` (macOS) or `date -u -d "+1 day" +%Y-%m-%dT%H:%M:%SZ` (Linux). The Postiz Cloud UI silently hides any post whose `publishDate` is in the past (verified empirically 2026-05-25: drafts with `publishDate=now` were invisible in Calendar across All/Scheduled/Draft/Published filters; only future-dated ones rendered). The date is ignored for the eventual scheduled publish — KK reschedules in the UI before going live — but it gates the draft's visibility while it sits in the review queue. **Anti-patterns to avoid:**
  - `now` / past timestamps → drafts vanish from UI (Postiz hides past-dated drafts).
  - `2099-01-01T00:00:00Z` or other far-future placeholders → drafts fall outside `posts:list` default `[now-30d, now+30d]` window and need explicit `--startDate/--endDate` to find via CLI.
  - `now + 24h` is the sweet spot: future enough for UI, near enough to stay inside the default `posts:list` window.
- `-i "<integration_id>"` — looked up from `config.publishing.postiz.integrations[draft.platform]`. For Slice D: LinkedIn = `<your-linkedin-integration-id>`, X = `<your-x-integration-id>`.
- `-d 0` — X thread only. Zero-minute delay between thread posts so they fire as a true thread when published. Omit `-d` for LinkedIn.
- `POSTIZ_API_KEY` — must be set in the shell environment when invoking. The storyteller skill itself does NOT set it; KK's shell does (via `~/.zshrc`). If missing, precheck #5 catches it.

## Shell-escaping (critical — most likely runtime bug source)

The `content` may contain any of these troublesome characters:

- Double quotes (`"`)
- Single quotes / apostrophes (`'`, `'`)
- Backticks (`` ` ``), dollar signs (`$`), exclamation marks (`!`)
- Newlines (LinkedIn long-posts use `\n` for line breaks; these are literal newlines in the string the drafter emits, not escape sequences)
- Em-dashes (`—`) and other UTF-8 punctuation

**Rules:**

1. **Always use single-quoted Bash strings for `-c` arguments.** Single quotes disable ALL Bash expansion — no `$VAR`, no `` `cmd` ``, no `!history`, no backslash interpretation. The content goes to the CLI verbatim.

   ```bash
   -c 'Your AI compliance scanner is lying to you about which framework you'\''re failing.'
   ```

2. **Single quote inside the content uses the `'\''` close-reopen pattern.** Single quotes cannot be escaped inside a single-quoted Bash string. The pattern is: close the single-quoted string (`'`), insert an escaped single quote (`\'`), reopen the single-quoted string (`'`). Net effect: one literal `'` inside the argument.

   - `It's fine` → `'It'\''s fine'`
   - `don't` → `'don'\''t'`
   - Programmatic transformation: replace every `'` in `content` with `'\''`, then wrap the whole string in `'...'`.

3. **Newlines work inside single-quoted strings as literal newlines.** No escaping needed. LinkedIn paragraph breaks (`\n` in the JSON string, which is a real newline character once parsed) pass through cleanly:

   ```bash
   -c 'Paragraph one.

   Paragraph two starts here.'
   ```

4. **Em-dashes, smart quotes, and other UTF-8 punctuation** pass through single quotes without issue. No escaping needed.

5. **Do NOT use double-quoted strings (`"..."`) for `-c`.** Double quotes still allow `$VAR`, `` `cmd` ``, and `\` expansion — any `$` or backtick in the content would be interpreted by Bash before reaching the CLI. This is the silent-corruption failure mode.

6. **Heredoc via stdin is not supported** by `postiz posts:create` — the CLI reads content from `-c` flags only. Inline single-quoted is the only path.

**Reference algorithm** (for the orchestrator implementing this):

```
escape(content_string):
  return "'" + content_string.replace("'", "'\\''") + "'"
```

## Capturing the return

The CLI prints a status line BEFORE the JSON payload on stdout. Verified output shape (2026-05-25):

```
✅ Post created successfully!
[
  {
    "postId": "cmpknxfqj043mma0yw45b6m3j",
    "integration": "<your-linkedin-integration-id>"
  }
]
```

**Naive `json.loads(stdout)` / `jq` on the raw stdout will fail** — the leading `✅ Post created successfully!` line is not JSON. Parse strategy:

1. Find the first `[` or `{` in stdout and slice from there.
2. Or `grep -v '^✅'` to drop the status prefix, then pipe to `jq`.
3. Or regex `re.search(r'\[.*\]', stdout, re.DOTALL)` in Python and parse the match.

Once parsed, extract:

- `postId`: `jq -r '.[0].postId'`
- `integration`: `jq -r '.[0].integration'`

Note: the return is an ARRAY (one entry per integration). In Slice D we always call with ONE `-i` so we always get one entry. For Slice E+ (multi-integration single call), iterate the array.

**Verification via `posts:list`:** the default date window is `[now - 30d, now + 30d]`. Drafts created with the `now + 24h` convention land in tomorrow's slot and appear here without extra flags. (Historical note: two prior conventions failed for different reasons. (1) `2099-01-01T00:00:00Z` placeholders fell outside the default window and needed explicit `--startDate/--endDate` to find via CLI. (2) `now` / current-timestamp made drafts invisible in the Postiz Cloud UI because the UI silently hides past-dated posts across ALL filters. Both abandoned 2026-05-25 in favor of `now + 24h`.)

## Error handling

On non-zero exit code from `postiz`:

1. Capture stderr.
2. Retry ONCE after sleeping 5 seconds (handles transient API blips and rate-limit bounces).
3. On second failure, return the failure envelope:

   ```json
   {
     "status": "failed",
     "platform": "<draft.platform>",
     "error": "<stderr message, trimmed to first line / 200 chars>",
     "draft_json": <full input draft>
   }
   ```

On JSON parse failure of the return (CLI exited 0 but stdout is not valid JSON):

```json
{
  "status": "failed",
  "platform": "<draft.platform>",
  "error": "postiz returned non-JSON: <first 200 chars of stdout>",
  "draft_json": <full input draft>
}
```

The orchestrator routes any `status: "failed"` envelope to `~/.storyteller/failed-pushes/<signal_id>-<platform>.json` for KK's manual follow-up.

## Output (success)

```json
{
  "status": "ok",
  "platform": "<draft.platform>",
  "postiz_draft_id": "<postId from CLI>",
  "integration_id": "<integration from CLI>"
}
```

## Output (failure)

```json
{
  "status": "failed",
  "platform": "<draft.platform>",
  "error": "<reason>",
  "draft_json": <full input draft for failed-pushes/ logging>
}
```
