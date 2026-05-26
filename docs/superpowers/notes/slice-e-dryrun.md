# Slice E Dry-Run Findings

**Date:** 2026-05-26
**Mode:** `/storyteller --dry-run` (workflow reorder validation, GitHub-only since Slack still disabled in user config)

## Signal counts
- GitHub: 21 merged PRs in last 7 days from `kkmookhey/ciso-copilot`
- Slack: 0 (source `enabled: false` in user config — gracefully skipped, no MCP calls)
- After dedupe vs `~/.storyteller/state.jsonl`: 14 candidates (7 dropped, already drafted in prior runs)
- After score-cutoff (≥ 4): 13 above threshold
- Top-`menu_size` (10) kept for menu: 10
- Below cutoff: 1 (pr#19 = 3, hard-zero territory)

## Auto-picks (scheduled-mode simulation in dry-run)
- Picked top-`top_n` = 3:
  - `pr#24` (score 8) — AI-powered SOC Slice 1 (AWS Config drift + AI enrichment)
  - `pr#3` (score 7) — Chat-first front door
  - `pr#20` (score 6) — CME-v2 Slice 4 mapping disclaimers

## Drafts produced
- 12 total (3 picked signals × 4 formats), 0 failures
- LinkedIn long-post: 3 (would push to Postiz)
- X thread: 3 (would push to Postiz)
- Instagram caption: 3 (held — `hold: true`, would save to `pending-video/`)
- Reels script: 3 (held — `hold: true` + `video_pending: true`)
- All passed structural validation (banned phrases, word count, char limits, hashtag formats)
- All Reels scripts had 4 sections (HOOK/SETUP/PAYOFF/CLOSE) with ≥4 timestamp markers

## Voice quality
- Sample LinkedIn draft (pr#24, top pick): 119-char hook (mobile-fold safe), real receipts (LiteLLM, EventBridge, Aurora, SQS), borrowable insight ("drift detection without enrichment is a louder queue"), Transilience absent, all 7 Jennifer checklist items pass qualitatively
- All 3 picked signals were classified as `audience: rohan` for Instagram/Reels (correct — engineering-receipt PRs)

## Token-economy validation
- Candidates after cutoff: 13
- Menu shown: top 10 (3 candidates excluded from menu — would have wasted tokens)
- Picked: 3
- **Drafts produced: 12 (3 × 4), NOT 52 (13 × 4)**
- Confirmation: drafting cost scales with PICKS, not menu width. The Slice E reorder works as designed.

## Postiz date fix
- All 6 `postiz posts:create` commands use `SCHEDULE_DATE=2026-05-27T17:41:44Z` (now + 24h)
- NOT the legacy `2099-01-01T00:00:00Z` (hidden from UI)
- NOT `now` (hidden from UI per Postiz Cloud past-date behavior)

## safe_signal_id encoding
- `github:kkmookhey/ciso-copilot:pr#24` → `github_kkmookhey_ciso-copilot_pr_24`
- Hyphens in the repo name preserved correctly; only `:` `/` `#` mapped to `_`

## Issues / regressions surfaced
1. **X drafter sometimes generates a 281-char post that needs tightening.** The structural validator caught this on first generation — implementer tightened to 259 chars before accepting. Worth surfacing that the X drafter prompt should be MORE emphatic about "aim ≤270 with hard cap 280" so the orchestrator doesn't need a retry-tighten cycle.
2. **`menu_size: 10` is genuinely absent from `~/.storyteller/config.yaml`** (user config drift from sample). The default applied correctly per SKILL.md step 4. Worth surfacing to KK to add it explicitly to make the default visible.
3. **No regressions vs Slice D.** Same 12-draft output for the same 3 auto-picks. The new menu+pick steps add interactive surface without breaking the underlying drafter contracts.

## Outstanding KK actions (Task 8 + Task 10)
1. **Enable Slack source** by adding channel IDs to `~/.storyteller/config.yaml > sources.slack.channels` (suggested: from probe — `C0EXAMPLE01` #dev_all, `C0EXAMPLE02` #dev-marketing, `C0EXAMPLE04` #transilience-omega-secops)
2. **Set `sources.slack.enabled: true`** in user config
3. **Run interactive `/storyteller`** to exercise the menu + pick path live (Task 10)
