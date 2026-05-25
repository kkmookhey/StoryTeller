# Postiz CLI Findings

**Date:** 2026-05-24
**CLI version:** 2.0.14 (installed via `npm install -g postiz`)
**Auth:** `POSTIZ_API_KEY` env var (Bearer token, 64 chars)

## Command for drafts

```bash
postiz posts:create \
  -c "<content text>" \
  -t draft \
  -s "<any ISO 8601 date>" \
  -i "<integration-id>[,<integration-id>...]"
```

- **Draft mechanism:** `-t draft` (explicit type flag, choices: `schedule` or `draft`, default: `schedule`)
- **`-s` is REQUIRED even for drafts** — the CLI rejects calls without it. The date is meaningless when `-t draft` (post is not scheduled). Use any reasonable future date as a placeholder.
- **`-i` is REQUIRED** — comma-separated list of integration IDs. At least one.

## Return shape (stdout)

```json
[
  {
    "postId": "cmpknxfqj043mma0yw45b6m3j",
    "integration": "<your-linkedin-integration-id>"
  }
]
```

- One entry per integration targeted.
- Extract draft IDs via `jq -r '.[].postId'`.
- Pair with integration via `jq -r '.[] | "\(.integration):\(.postId)"'` for state.jsonl logging.

## Multi-integration behavior

✓ Confirmed: one call can target multiple integrations via `-i "id1,id2"`. The return array has one entry per integration. This is efficient for cross-platform posting (LinkedIn + X in one call).

**Slice D consideration:** LinkedIn and X drafts have different `content` shapes (long-post string vs thread array). They can't share a single `posts:create` call because the thread (`-c` repeated) syntax only makes sense per integration. **Recommendation: one `posts:create` call per (signal, platform) pair, not multi-integration.**

## Threads (for X)

```bash
postiz posts:create \
  -c "Thread post 1" \
  -c "Thread post 2" \
  -c "Thread post 3" \
  -d 0 \
  -t draft \
  -s "2026-06-01T12:00:00Z" \
  -i "<x-integration-id>"
```

- Repeated `-c` flags = thread posts
- `-d <minutes>` = delay between posts (use `-d 0` so they fire as a true thread)

## Integration mapping (KK's chosen accounts)

| Platform | Integration ID | Profile |
|---|---|---|
| linkedin | `<your-linkedin-integration-id>` | kkmookhey |
| x | `<your-x-integration-id>` | kkmookhey |
| instagram | — (not yet connected; add for Slice F) | |
| youtube | — (not yet connected; add for Slice G) | |

## Verification test (passed)

```bash
export POSTIZ_API_KEY="$(tr -d '[:space:]' < 'Postiz Key.txt')"
postiz auth:status
# → ✅ Credentials are valid. 2 integration(s) connected.

postiz posts:create -c "test" -t draft -s "2026-06-01T12:00:00Z" -i "<linkedin-id>"
# → ✅ Post created successfully (postId returned)
```

## Media handling

Per Postiz plugin SKILL.md Hard Rule 2: any media file MUST go through `postiz upload` first; the returned `.path` is what gets passed to `-m`. Out of scope for Slice D (text-only) but relevant for Slice F/G.

```bash
RESULT=$(postiz upload ./image.png)
URL=$(echo "$RESULT" | jq -r '.path')
postiz posts:create ... -m "$URL" ...
```

## Quirks observed

- `-s` is mandatory even when `-t draft` makes the date meaningless. Pass a placeholder ISO date.
- Auth via `POSTIZ_API_KEY` env var is read fresh on each invocation — must be present in the shell environment when Bash runs the command.
- The Claude Code Bash tool does NOT persist exports across calls. Either inline `export POSTIZ_API_KEY=... && postiz ...` per call, or set the env var in the user's shell profile (~/.zshrc) so it's inherited.
- `--shortLink` defaults to `true`. Set `--shortLink false` if you want raw URLs in posts (not relevant for KK voice — kk-voice doesn't use trackable shortlinks).
- Platform-specific settings (X reply restrictions, YouTube tags, Reddit subreddits) pass via `--settings '<json>'`. Document per-platform when needed.

## Implications for the storyteller skill

1. **One Bash call per (signal, platform) pair.** Don't try to batch LinkedIn + X in one call — content shapes diverge.
2. **Date placeholder:** use a fixed future date for draft creation (`2026-12-31T00:00:00Z` or similar). Postiz ignores it for drafts.
3. **State.jsonl entry:** record `{postId, integration}` from the returned JSON. Schema becomes:
   ```json
   {"signal_id":"...","drafted_at":"...","postiz_drafts":[{"platform":"linkedin","postId":"...","integration":"..."}]}
   ```
4. **Env var persistence:** the install script (Task 3) should remind KK to add `export POSTIZ_API_KEY=$(cat 'Postiz Key.txt')` to `~/.zshrc` for permanent availability.
