---
name: storyteller
description: Use when KK wants to surface recent newsworthy product or company activity for social media posting. Triggers on /storyteller, "find me post ideas", "what's worth posting this week", "anything good from this week's PRs", scheduled Cowork runs, or any request to identify content-worthy moments from GitHub, Slack threads, or Confluence/Jira updates.
---

# StoryTeller — Signals to Ranked Drafts to Postiz

Orchestrate the pipeline. Detail lives in `references/`.

## Workflow

1. **Load config** `~/.storyteller/config.yaml`. Stop if `sources.github.repos` or `publishing.postiz.integrations.linkedin`/`.x` empty; report what's missing.
2. **Fetch signals in parallel** from each `enabled: true` source per `references/source-<name>.md`. Merge into one `Signal[]`.
3. **Dedupe** vs `~/.storyteller/state.jsonl`: drop signals whose `id` already appears. Prune entries older than `config.state.retention_days` (default 90).
4. **Score** in ONE batched call via `references/scoring-rubric.md` with `kk-voice` loaded. Drop `score < 4`. Sort desc. Keep top `config.scoring.menu_size` (default 10) — candidate pool. Thin weeks = shorter menu, no padding.
5. **Present idea menu** (interactive). Render candidates as markdown table: index, score, source, title, `why_postworthy`, `suggested_angle`. Mirror to `~/.storyteller/last-ideas.json`.
6. **Wait for user pick** (interactive) per `references/pick-parser.md`. Scheduled: auto-pick top-`config.scoring.top_n`.
7. **Draft** each PICKED signal in every `enabled: true` format per `references/drafting-*.md`. On `status: "error"` with routing hint, log and continue; otherwise save input to `~/.storyteller/failed-pushes/<safe_signal_id>-<format>.json`.
8. **Review loop** (interactive). Loop on edits ("tighten 2's hook", "redraft 1") until "ship it".
9. **Publish + notify + write state.** Per `references/publish-postiz.md`: for each draft NOT `hold: true`, invoke Postiz CLI to create a **draft** (never published); for `hold: true`, save to `~/.storyteller/pending-video/<safe_signal_id>-<platform>.json`. Retry once; second failure → `~/.storyteller/failed-pushes/`. Send `notification.slack.template` via `mcp__claude_ai_Slack__slack_send_message` to `notification.slack.target`. Append per drafted signal to `~/.storyteller/state.jsonl`: `{"signal_id":"...","drafted_at":"<ISO>","postiz_drafts":[{"platform":"...","postId":"...","integration":"..."}]}`.

## Modes
- **Interactive:** `/storyteller`. Includes steps 5, 6, 8 (menu, pick, review).
- **Scheduled (Cowork):** Skips 5, 6, 8. Auto-picks top-`top_n`.

## Flags
- `--dry-run`: run 1-7; step 6 auto-ships first N picks; step 9 skips push/state/Slack.
- `--source <name>`: in step 2, only fetch named source.
- `--no-postiz`: skip step 9 push; still save held and write state.
- `--no-notify`: skip Slack send; still write state.

## Failure-mode anti-patterns
- Do NOT publish to Postiz — always draft per `references/publish-postiz.md`. Auto-posting forbidden.
- Do NOT skip dedupe — same signal will redraft every run.
- Do NOT draft BEFORE scoring — only candidates get drafted.
- Do NOT draft BEFORE the user picks in interactive mode — drafting is reserved for picked signals.
- Do NOT silently swallow scoring/drafting failures — surface in Slack.
- Do NOT push `hold: true` drafts; they go to `~/.storyteller/pending-video/`.
- Do NOT pass raw paths or URLs to `postiz posts:create -m` — upload via `postiz upload` first.

## Prerequisites
- `gh` authenticated (`gh auth status` OK).
- `postiz` installed; `POSTIZ_API_KEY` set.
- Slack MCP (`mcp__claude_ai_Slack__*`) available.
- `~/.storyteller/config.yaml` exists; if missing, copy `sample-config.yaml` and pause for repos.

**REQUIRED VOICE SKILL:** `kk-voice` — load before scoring or drafting.
**REQUIRED FORMAT SKILL:** `kk-short-form` — load before drafting Instagram or Reels.
**REQUIRED BACKGROUND:** `superpowers:test-driven-development` — applies when validating skill behavior during development.
