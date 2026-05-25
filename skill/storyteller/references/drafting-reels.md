# Drafting: Instagram Reels / YouTube Shorts script (held content in Slice D)

Draft a single short-form vertical video SCRIPT for KK Mookhey (@settlingforless1 on Instagram, KK Mookhey on YouTube Shorts) from one ScoredSignal. The output is a timestamped SHOOTING SCRIPT (markdown), not a single text block, plus a separate Instagram/Shorts caption that will publish alongside the video once produced.

**REQUIRED:** Load `_drafting-shared.md` first for cross-format conventions (banned phrases, error envelope, routing-hint convention, output strictness, Transilience cross-format rule, internal_notes convention, front-load drift warning). Those rules apply here in full and are not duplicated below.

**REQUIRED VOICE SKILLS:** `kk-voice` AND `kk-short-form` (BOTH — `kk-short-form` is the **authoritative source** for Reels structure, hook formulas, payoff pacing, retention rules, and the Pre-Publish Checklist; `kk-voice` is the voice DNA underneath). If either is not loaded, stop and load it.

**AUDIENCE FILTER:** Meera / Rohan / Story per kk-short-form's 60/30/10 split. **NOT Jennifer.** The Jennifer pre-publish checklist in `kk-voice` does NOT apply to Reels/Shorts. The kk-short-form 10-item Pre-Publish Checklist IS the bar this script must clear.

## Slice D: this script is HELD with two flags

This script does **NOT push to Postiz in Slice D.** Reels need a produced video to ship, and that production is Slice G's job (Descript MCP). The orchestrator saves this draft to:

```
~/.storyteller/pending-video/<signal_id>-reels.json
```

…with both `hold: true` AND `video_pending: true` set in the output. The two flags are how downstream slices route the file:

- `hold: true` → orchestrator stashes the draft instead of pushing to Postiz (same convention as the Instagram caption drafter).
- `video_pending: true` → Slice G's Descript hook scans `~/.storyteller/pending-video/` for files with this flag and hydrates them into actual video (voiceover, B-roll, overlays, export).

Both flags MUST be present and `true`. Missing either one breaks downstream routing.

## Input

A single ScoredSignal — the Signal envelope plus the scorer's verdict (same shape as the other drafters):

```json
{
  "signal": { /* the Signal object: source, id, url, title, summary, timestamp, author, raw */ },
  "score": <integer 0-10>,
  "why_postworthy": "<one sentence — what makes this Jennifer-worthy>",
  "suggested_angle": "<one sentence — angle the scorer recommends>"
}
```

The orchestrator only calls this drafter for signals with `score >= 7`. Note: the scorer is Jennifer-tuned, so `why_postworthy` and `suggested_angle` may carry LinkedIn framing. **Re-target the substrate for Meera/Rohan/Story — do not copy the Jennifer angle verbatim.** Use `signal.title`, `signal.summary`, and `signal.raw.body_excerpt` as the receipts. Do NOT invent numbers, named tools, or scenarios the signal doesn't support.

**Jennifer markers to scrub** (these read fine on LinkedIn but signal "wrong audience" in a Reel script):
- "Deputy CISO", "CISO", "the board" (as framing) — name the person actually affected instead
- "POC", "vendor selection", "compliance taxonomy", "mid-market enterprise" — replace with concrete consumer/tech-adjacent stakes
- "borrowable in your next meeting" / "your QBR" — replace with concrete forward-prompt for Meera or specificity for Rohan
- "board memo", "executive readout" — name the operator-level impact instead

If a Jennifer marker has to stay because it IS the stakes ("this breaks the dashboard the Deputy CISO actually uses"), constrain it to a single noun-of-fact mention in the VO, never the framing.

## Step 1 — Audience classification (do this BEFORE drafting)

Per kk-short-form's 60/30/10 ratio, classify the signal as exactly one of:

- **Meera** (non-tech, 60%). Pattern: named device/threat/scam + concrete action she can take in 3 seconds. Use ONLY when the signal has a clear consumer-safety or family-protection angle ("your phone is doing X", "your mom's WhatsApp", "this scam SMS"). GitHub engineering PRs **rarely qualify** unless they have that "your X is at risk" hook.
- **Rohan** (tech-adjacent, 30%). Pattern: real tool / real finding / real number. Technical specificity that respects intelligence. **Most GitHub PR signals are best as Rohan content** — show the tool, the bug, the receipt.
- **Story** (existing-follower nurture, 10%). Reflective, founder/practitioner perspective. Use sparingly — only for retrospective/philosophical PRs or signals with a clear human-interest arc.

**Default for GitHub PR signals: Rohan.** Use Meera ONLY if there's a clear non-tech-user safety/privacy angle. Use Story ONLY for retrospective/philosophical signals.

**Record the chosen audience in the `audience` field of the output** AND in the `AUDIENCE:` metadata line at the top of `content_markdown`.

If the signal genuinely fits none of the three (e.g., dense compliance taxonomy with no Rohan-grade tool/finding and no consumer angle), OR if the signal is a text-only insight with no demo-able visual or screen recording, emit the error envelope with a routing hint per `_drafting-shared.md`:

```json
{"status": "error", "platform": "reels", "format": "script",
 "error": "no visual hook for reels — recommend x thread"}
```

or

```json
{"status": "error", "platform": "reels", "format": "script",
 "error": "no consumer-safety or technical-receipts angle for reels — recommend linkedin long-post"}
```

## Step 2 — Length target (per audience)

Length determines the timestamp budget for your `[MM:SS]` markers. Per kk-short-form:

- **Meera reel:** 20–35 seconds. Urgent-feeling. Enough to convey the action, not a second more.
- **Rohan reel:** 35–60 seconds. Technical content needs room to show work.
- **Story reel:** 30–45 seconds. Long enough to land the emotional beat, short enough to not drift.

The 25-second rule from kk-short-form: if a reel can deliver full value in 25 seconds, it should. Don't pad to hit the upper end of the range.

State the chosen length range on the `LENGTH TARGET:` metadata line.

## Step 3 — The Four-Part Structure (apply rigidly)

Every script MUST have all four sections, in order, with timestamp markers `[MM:SS–MM:SS]` (en-dash or hyphen). Each section has three lines: VO (voiceover), Text overlay, Visual. The 4-section structure is **non-negotiable** — it's the structural contract Slice G's video hydration reads.

### `[00:00–00:03] HOOK`

This is 80% of whether the reel works. The hook must do three things in 3 seconds:
1. Name a specific audience ("If you have an iPhone…", "If your dev team is using…")
2. Signal specific stakes (what goes wrong, how bad)
3. Open a loop the viewer needs to close

Format:
- **VO:** one sentence, ≤25 words to fit 3 seconds of voiceover. Names the audience and stakes.
- **Text overlay:** bold short overlay, 5–8 words, names the stakes in caps or punchy phrasing.
- **Visual:** B-roll, KK's face mid-warning (NEVER mid-greeting), screen recording, or the thing being discussed.

### `[00:03–00:10] SETUP`

The "why should I care and what is this about" section. 7 seconds.

- **VO:** 1–2 sentences of specific context. Names the CVE, the app, the attack, the version number, the tool. Keeps the loop open — doesn't resolve it yet.
- **Text overlay:** the specific noun (CVE id, app name, framework, tool, device).
- **Visual:** B-roll showing the thing.

Setup rules from kk-short-form: max 2 sentences, specific nouns only, don't resolve the loop yet.

### `[00:10–00:XX] PAYOFF` (the longest section)

The content the hook promised. End time depends on the audience length target.

- **VO:** the actual value — steps (Meera) / technical reveal (Rohan) / story beat (Story).
- **Text overlay:** numbered steps OR key stat OR specific finding (changes every 3–5 seconds).
- **Visual:** screen recording, demonstration, or relevant B-roll.
- **Re-hook every 8–10 seconds:** list 1–3 re-hooks below the section (visual cut, stat-slam, pause, rhetorical question, text-overlay reveal).

**Audience-specific payoff rules** (per kk-short-form):

- **Meera (PSA format):** show the exact thing to do in concrete numbered steps (1, 2, 3) on screen. Name the setting, the button, the exact text of the scam. End with "if you already clicked it, here's what to do next" — adds a second layer of utility.
- **Rohan (technical format):** show the actual tool, code, or finding on screen. Narrate what you're doing, not why it matters (he already knows why). Reveal something specific — a technique, a bug, a result. Receipts over claims.
- **Story (story format):** present tense for past events ("It's 2001. I'm sitting in my office…"), specific years, named people, vivid scenes. Lets details speak; doesn't over-narrate.

### `[MM:SS–MM:SS] CLOSE` (the final 5–10 seconds)

Two jobs: deliver the final punch the hook promised, AND either loop back to the opening or give the viewer a reason to send it. **The CLOSE marker MUST be a real `[MM:SS–MM:SS]` timestamp pair** (e.g., `[00:48–00:58]` for a ~58s Rohan reel) — not a literal `[FINAL 5-10s]` placeholder. The structural validator counts at least 4 `[MM:SS` markers across the script; every section header needs one.

- **VO:** the loop-back line OR the forward-prompt with named recipient.
  - **Meera close:** forward-prompt with named recipient ("Send this to the one person in your family who clicks every link." / "Your mom needs to see this before Sunday."). Named recipient is required for the Meera forward-prompt — never generic "share this!".
  - **Rohan close:** specificity that earns the follow ("More teardowns like this every week" or a borrowable one-liner) — or nothing at all. Never "follow for more."
  - **Story close:** reflective line in KK's voice. The line lands and ends — no CTA.
- **Text overlay:** final punch (or blank for Story closes that land on their own).
- **Visual:** return to opening visual for the loop, OR direct-camera for the forward-prompt.

## Step 4 — Banned Reels hooks (auto-fail if any appear in VO lines)

These are in addition to the cross-format `tests/banned-phrases.txt`:

- "Hey guys" / "Hi everyone" / "Welcome back" / "Welcome to my channel" — the greeting ban from kk-short-form: KK never opens a reel with any variation of these.
- "The biggest news in…" / "Bombshell news" — too generic, forfeits the 3-second window.
- "The internet is going crazy about…" — delegates the hook to someone else.
- "Let me tell you about…" — slow build, dead on arrival in 3 seconds.
- "Guys, you won't believe…" — the "guys" problem plus zero specificity.
- "In today's video" / "Today we're going to talk about" — preamble, not a hook.

The structural validator searches for these in `content_markdown` (case-insensitive, curly quotes normalized to straight quotes).

## Step 5 — Forbidden CTA moves in the CLOSE

Per kk-short-form's "Anti-Patterns" and "What KK never does":

- "Smash the like button" / "Hit that follow button"
- "Don't forget to subscribe"
- "Let me know in the comments"
- "Follow for more"
- "Tag a friend in the comments"

The Meera **forward-prompt** pattern (`"Send this to the one person in your family who clicks every link"`) IS allowed and recommended for Meera closes, because it names a specific recipient and the forwarding behavior is what drives Meera-segment distribution. Generic "share this with your friends" is banned. Never use the forward-prompt pattern in Rohan or Story closes.

## Step 6 — Text overlay cadence (mute test)

Instagram serves ~90% of Reels on mute first. The script MUST indicate when text overlays change — every 3–5 seconds. The mute test from the kk-short-form Pre-Publish Checklist: if you play the reel on mute, does the text overlay sequence alone carry the core claim? If no, add overlays.

Practically: each section's Text overlay line should reflect what's on screen during that beat. For PAYOFF, list the overlay sequence as it changes (e.g., "Step 1: Settings", "Step 2: Security", "Step 3: Install unknown apps OFF") — don't just write one overlay for a 20-second payoff.

## Step 7 — Caption_for_post

A separate Instagram/Shorts caption to publish when the video uploads. Slice G pairs this caption with the produced video and pushes the pair to Postiz. The caption MUST follow the Instagram caption drafter conventions from `drafting-instagram.md`:

- **Length:** aim 1000–1800 chars total, hard max 2200 chars (Instagram's limit).
- **Opening line:** ≤125 characters — the visible-preview hook that renders above Instagram's "... more" fold. Audience-specific opener rules from `drafting-instagram.md` apply (Meera: name device/scam in first 5 words; Rohan: name tool/CVE/finding in first 7 words; Story: declarative claim or scene-set).
- **Forbidden opener framings:** same as `drafting-instagram.md` — no "Hi guys," / "Hey everyone," / "Welcome back" / "Let me tell you about…" / "The biggest news in…" / audience-questions-as-opener.
- **Body:** 2–4 short paragraphs separated by `\n\n`. Specific, not abstract. KK voice rules apply.
- **Forbidden mid-caption moves:** no "Hit follow!", no "Smash the like!", no "Tag a friend!", no "Save this for later!" as a standalone CTA. The Meera forward-prompt with named recipient IS allowed in Meera captions only.
- **Hashtag block at the END:** Instagram convention is to push hashtags below the visible preview using a separator of three single-period lines. The LAST piece of `caption_for_post` MUST be the literal substring `\n.\n.\n.\n` followed by the hashtags. (The structural validator does NOT enforce this separator — that's the caption-drafter's job — but if you skip it, the eventual Instagram render will be ugly.)
- **The Reels script's `content_markdown` does NOT need this `\n.\n.\n.\n` separator** — the script is a shooting document, not a publish-ready string. The dot-period separator belongs ONLY in `caption_for_post`.

The caption is NOT a transcript of the script. It's the accompaniment that earns the view-from-feed and gives screenshot-savers something to refer back to. The script gets the viewer to watch; the caption seals the forward.

## Step 8 — Hashtags

Same convention as the Instagram caption drafter. **3–7 total** hashtags in the `hashtags[]` array; the SAME hashtags also appear in the trailing block of `caption_for_post`. Primary always `#cybersecurity`. Pick the rest per audience:

- **Meera:** `#scamalert`, `#parentsonline`, `#phonesecurity`, `#whatsappscam`, `#onlinesafety`
- **Rohan:** `#aisecurity`, `#pentesting`, `#infosec`, `#appsec`, `#redteam`, `#promptinjection`
- **Story:** `#cybersecurity`, `#startuplife`, `#founderlife`, `#techindustry`

Avoid hashtag soup. 3–7 max — more doesn't help in 2026 per kk-short-form.

## Step 9 — Transilience placement (Reels-specific application of the shared rule)

Per `_drafting-shared.md`: if Transilience appears, it appears ONLY in the **closing 5–10 seconds of the script** — i.e., inside the CLOSE section, never earlier. The preceding HOOK / SETUP / PAYOFF must read as a complete, valuable reel even if the Transilience mention were removed from the CLOSE.

Self-check: mentally delete the CLOSE. Does the reel still earn its keep on its HOOK + SETUP + PAYOFF alone? If no, the Transilience mention is load-bearing — you're pitching, not teaching. Rewrite.

For Meera scripts specifically: Transilience probably has no business in a Meera safety-PSA reel — Meera doesn't care which threat-intel platform spotted the scam, she cares about what to tap on her phone. Default for Meera = skip the Transilience mention entirely.

## Step 10 — Voice cross-check (kk-short-form 10-item checklist)

Before finalizing, mentally walk the kk-short-form Pre-Publish Checklist (10 items, in `skill/kk-short-form/SKILL.md`). For a Reels SCRIPT, **all 10 items apply directly** — no deferrals. Specifically:

1. Hook in 3 seconds — does the HOOK VO + overlay name audience, stake, promise within 3 seconds?
2. Shareability test — would Meera forward this to her mom, or Rohan save this to show his team?
3. Specificity check — named device, named app, named attack, named version. No "many", "users", "threats."
4. Mute test — does the text overlay sequence carry the core claim without audio?
5. Loop or forward — does the CLOSE either loop back or give a specific forward reason?
6. No banned phrases — none of the Reels-specific banned hooks, none of the cross-format banned phrases.
7. Jennifer non-embarrassment — would KK be comfortable if Jennifer scrolled to this on a flight? No false urgency, no clickbait, no overstated threats.
8. KK voice markers — sounds like KK (short sentences, direct, no corporate polish, no AI-slop).
9. Text overlay cadence — new text every 3–5 seconds, key claim on screen when VO says it.
10. Length fits type — Meera under 35s, Rohan under 60s, Story under 45s.

If any of these fail, the script doesn't ship until it's fixed.

## Error handling

Per `_drafting-shared.md`, return the error envelope when input is unusable. Specific Reels cases:

- Missing field:
  `{"status": "error", "platform": "reels", "format": "script", "error": "missing field: <name>"}`
- Malformed input:
  `{"status": "error", "platform": "reels", "format": "script", "error": "malformed input"}`
- Signal has no visual hook (text-only insight, no demo-able screen/B-roll):
  `{"status": "error", "platform": "reels", "format": "script", "error": "no visual hook for reels — recommend x thread"}`
- Signal fits no Reels audience (Meera / Rohan / Story):
  `{"status": "error", "platform": "reels", "format": "script", "error": "no consumer-safety or technical-receipts angle for reels — recommend linkedin long-post"}`

## Output

Return ONLY a single JSON object — per the shared output-strictness rule, no prose around it, no markdown fence (no triple-backtick `json` wrapper). First character `{`, last character `}`.

Draft success shape:

```json
{
  "status": "ok",
  "platform": "reels",
  "format": "script",
  "content_markdown": "# TITLE: <working title>\nAUDIENCE: <meera|rohan|story>\nLENGTH TARGET: <range like 35-60s>\n\n[00:00–00:03] HOOK\nVO: <one sentence, names audience + stakes>\nText overlay: <bold 5-8 word overlay>\nVisual: <what's on screen>\n\n[00:03–00:10] SETUP\nVO: <1-2 sentences of specific context>\nText overlay: <specific noun>\nVisual: <B-roll showing the thing>\n\n[00:10–00:XX] PAYOFF\nVO: <steps / technical reveal / story beat>\nText overlay: <numbered steps / key stat / specific finding — listed as the overlay sequence changes every 3-5s>\nVisual: <screen recording / demonstration / B-roll>\nRe-hook every 8-10s: <list 1-3 re-hooks>\n\n[00:XX–00:YY] CLOSE\nVO: <loop-back line OR forward-prompt with named recipient>\nText overlay: <final punch>\nVisual: <return to opening for loop, or direct-camera for forward>",
  "caption_for_post": "<caption to publish alongside the video when produced; <=2200 chars; opening line <=125 chars; ends with the literal substring \\n.\\n.\\n.\\n followed by the hashtag block>",
  "hashtags": ["#cybersecurity", "..."],
  "audience": "rohan",
  "hold": true,
  "video_pending": true,
  "internal_notes": "<one line: chosen audience + why, plus 2-3 kk-short-form checklist items this script hits hardest, format #<n> <short-name>>"
}
```

Field rules:

- `content_markdown` — the timestamped shooting script. Markdown-formatted. Must include the `# TITLE:`, `AUDIENCE:`, `LENGTH TARGET:` header block and all four `[MM:SS]` sections (HOOK, SETUP, PAYOFF, CLOSE). Each section has VO, Text overlay, Visual lines. Slice G's Descript hook reads this to drive video assembly.
- `caption_for_post` — the Instagram/Shorts caption to publish alongside the produced video. Follows `drafting-instagram.md` conventions including the `\n.\n.\n.\n` separator before the hashtag block.
- `hashtags` — 3–7 hashtags, each starting with `#`. The SAME hashtags appear in the trailing block of `caption_for_post`.
- `audience` — one of `"meera"`, `"rohan"`, `"story"`. The classifier output from Step 1; MUST match the `AUDIENCE:` line in `content_markdown`.
- `hold` — ALWAYS `true` in Slice D. Orchestrator stashes the draft instead of pushing.
- `video_pending` — ALWAYS `true`. Slice G's Descript hook reads this flag to know the file is awaiting video hydration.
- `internal_notes` — per the shared internal_notes convention. Format: `"audience=<x> because <reason>; #<n> <short-name>, #<n> <short-name>"`. Never posted to Postiz or any downstream system.
