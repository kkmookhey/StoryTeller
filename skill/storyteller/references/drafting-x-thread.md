# Drafting: X (Twitter) thread

Draft a single X thread for KK Mookhey from one ScoredSignal.

**REQUIRED:** Load `_drafting-shared.md` for cross-format conventions (voice authority, banned phrases, error envelope, output strictness, Transilience cross-format rule, internal_notes convention, front-load drift warning). Those rules apply here in full and are not duplicated below.

**REQUIRED VOICE SKILL:** `kk-voice` (Jennifer Chen audience — same as LinkedIn). X is where Jennifer follows people for industry signal; LinkedIn is where she does professional reading. The Jennifer pre-publish checklist in `kk-voice` is the single source of truth for what passes. Do not infer voice rules from this file alone. If `kk-voice` is not loaded, stop and load it.

## Input

A single ScoredSignal — the Signal envelope plus the scorer's verdict:

```json
{
  "signal": { /* the Signal object: source, id, url, title, summary, timestamp, author, raw */ },
  "score": <integer 0-10>,
  "why_postworthy": "<one sentence — what makes this Jennifer-worthy>",
  "suggested_angle": "<one sentence — angle the scorer recommends>"
}
```

The orchestrator only calls this drafter for signals with `score >= 7`. Use `signal.title`, `signal.summary`, and `signal.raw.body_excerpt` as the substrate. The `suggested_angle` is a strong hint, not a mandate. Do NOT invent numbers, named tools, or scenarios the signal doesn't support.

## Structure constraints (X-specific)

**Thread length: 3-5 posts.**

- NOT shorter: the first post needs to earn the second on its own merits, then the receipts unfold in posts 2-N. A 2-post "thread" is a tweet with a follow-up; it doesn't justify the thread format.
- NOT longer: a 6+ post thread loses Jennifer's attention. If you need more, condense the receipts or split into multiple drafts.

**Per-post character target:** `<= 280` chars HARD limit per post. Aim for `<= 270` to allow natural pauses and copy that doesn't feel Tetris-packed.

**Post 1 — the hook.** The post that earns the rest. Must name a Jennifer-relevant stake (see kk-voice "What's On Her Mind at 8:15 AM Tuesday" for the menu). `<= 210` chars is ideal — X previews the first ~210 chars on mobile timelines and in retweet/quote contexts, and a hook that survives a quote-tweet earns more reach. Forbidden hook framings are listed below.

**Posts 2 to N-1 — the receipts.** One concrete receipt per post. Named tools, real numbers, specific scenarios pulled from the signal. NO bullets within a post — use em-dashes or semicolons for compound thoughts. One receipt per post is the rule; cramming two receipts into 280 chars dilutes both.

**Post N — the close.** ONE borrowable insight Jennifer can paraphrase in her next meeting and sound sharper. Forbidden closes:

- "Follow for more"
- "What do you think?" / "Drop your thoughts below"
- "RT if you agree"
- "Full thread on LinkedIn" or any cross-platform redirect
- Plain restatement of the hook (the close earns its own line)

**No numbering prefixes.** Do NOT insert "1/", "2/", "1/5", "🧵", etc. Postiz handles thread numbering when it publishes. If you find yourself typing "1/", stop — that's a sign the hook isn't strong enough to earn the next post on its own merit. Rewrite the hook instead.

## Forbidden hook framings (X-specific)

In addition to the cross-format banned phrases (see `_drafting-shared.md` / `tests/banned-phrases.txt`):

- "Thread:" or "🧵" as the opener — telegraphs intent, weakens the hook. The hook should make Jennifer want to read post 2; advertising "this is a thread" is a substitute for being interesting.
- "Hot take:" / "Unpopular opinion:" — already in `banned-phrases.txt`; restating here because hooks are where the temptation is strongest.
- Audience questions as the hook ("What's the worst X you've seen?", "Anyone else dealing with…?") — fine in posts 2 through N-1, never as post 1.
- Generic industry-state hooks ("AI is changing security…", "Vuln management is broken…") — same anti-pattern as LinkedIn.

Examples of hook shapes that work (illustrative, do not copy verbatim):

- "Your AI compliance scanner is lying to you about which framework you're failing. We pulled 65 source-verified rules across 5 frameworks. Three were already wrong upstream."
- "If you trust your AI compliance scanner to tell you which framework you're failing — it's wrong. Three of the 65 rules we rebuilt were already broken in the upstream taxonomy."

## Hashtag rules (X-specific)

- 0-3 hashtags total across the entire thread.
- Place ALL hashtags in the FINAL post only. Cluttering middle posts with hashtags is a known X anti-pattern; it also reads spammy.
- Prefer specific over broad: `#promptinjection` > `#ai`, `#vulnmanagement` > `#cybersecurity`, `#aisecurity` > `#tech`.
- It is fine to ship with ZERO hashtags if no specific tag fits naturally. A clean close beats a forced tag.
- Avoid: `#innovation`, `#thoughtleadership`, `#futureoftech`, `#disruption`, vendor-name hashtags.

## Transilience placement (X-specific)

Per the shared rule: if Transilience appears, it appears ONLY in the final post (post N). The preceding posts must read as a complete, valuable thread even if the Transilience mention were removed.

Self-check: mentally delete the final post. Does the rest of the thread still earn its keep on receipts alone? If no, the Transilience mention is load-bearing — you're pitching, not teaching. Rewrite.

## Compression discipline (the format-defining constraint)

Every word on X earns its 280-char allocation. Two rules:

1. **Compress word economy, NEVER compress specifics.** "We found 65 source-verified issues across 5 frameworks" is non-negotiable. "We found many issues across several frameworks" is failure. If you can't fit the specifics inside 280 chars, you have two options:
   - Split the receipt across 2 posts (still within the 3-5 thread length).
   - Drop that receipt and pick a different angle the thread can carry.
2. **Cut hedges, qualifiers, and connective fluff.** "We've been seeing that, in many cases, scanners tend to..." → "Scanners drift." Same meaning, 60 fewer chars.

If after compression the receipt still doesn't fit and can't be split, that signal is wrong for X — escalate to LinkedIn long-form or skip.

## Voice constraints (cross-check against kk-voice)

Highlights — the full voice spec is in `kk-voice`:

- Conversational professional. Contractions natural: "you're", "it's", "don't", "I'd".
- Medium-length sentences with occasional short punches. On X, the short punches earn more weight per char.
- **No India/ME-first framing:** regional color fine; regional subject is not. DPDPA / SAMA / NCA as subject = rewrite.
- Founder voice subordinated to operator voice. "Here's what we saw doing the work" beats "I built a company."

## Error handling

Per `_drafting-shared.md`, return the error envelope with `status: "error"` when input is unusable. Specific X cases:

- If `signal.title`, `signal.summary`, or `signal.raw.body_excerpt` is missing/empty:
  `{"status": "error", "error": "missing field: <name>", "platform": "x", "format": "thread"}`
- If the input is malformed JSON or not a ScoredSignal shape:
  `{"status": "error", "error": "malformed input", "platform": "x", "format": "thread"}`
- If the signal cannot be compressed into 3-5 posts without losing the specifics (after honest attempt):
  `{"status": "error", "error": "incompressible for x — recommend linkedin long-form", "platform": "x", "format": "thread"}`

## Output

Return ONLY a single JSON object — per the shared output-strictness rule, no prose, no markdown fence. First character must be `{`, last must be `}`.

Draft success shape:

```json
{
  "status": "ok",
  "platform": "x",
  "format": "thread",
  "content": [
    "<post 1 — the hook, names a Jennifer-relevant stake, <=280 chars (aim <=210)>",
    "<post 2 — first receipt, one concrete receipt only, <=280 chars>",
    "<post 3 — second receipt OR the borrowable lesson, <=280 chars>"
  ],
  "hashtags": ["#promptinjection"],
  "internal_notes": "<one line: which 2-3 Jennifer filter criteria this thread hits hardest, format #<n> <short-name>>"
}
```

The `content` field is an array of plain-text posts. No numbering prefixes, no markdown, no bullets, no embedded line breaks within a post (each post is a single string that fits in one X post). The orchestrator hands this array to Postiz as the thread sequence.

The `internal_notes` field is for KK reading the draft in interactive mode — name 2-3 of the 7 Jennifer-filter items this thread leans hardest on (e.g., `"#3 receipts and #5 makes-her-smarter; #1 stop-scrolling is the gamble"`). Never posted to Postiz.
