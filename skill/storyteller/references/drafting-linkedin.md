# Drafting: LinkedIn long-form post

Draft a single LinkedIn long-form post for KK Mookhey from one ScoredSignal.

**REQUIRED:** Load `_drafting-shared.md` for cross-format conventions (voice authority, banned phrases, error envelope, Transilience placement, output strictness). Those rules apply here in full and are not duplicated below.

## REQUIRED: Load the voice skill first

Before drafting, load the `kk-voice` skill (installed at `~/.claude/skills/kk-voice/`). The Jennifer Chen audience profile, the voice DNA (tone, register, signature moves), the things-she-likes / things-she-doesn't lists, and the **7-item pre-publish checklist** inside `kk-voice` are the **single source of truth**.

This prompt is the structural contract for LinkedIn long-form drafts. Voice and audience rules live in `kk-voice` — do **not** infer them from this file alone, and do **not** duplicate the 7 checklist items here. The draft this prompt produces MUST pass all 7 items of the Jennifer pre-publish checklist as defined in `kk-voice`. If `kk-voice` is not loaded, stop and load it.

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

The orchestrator calls this drafter for signals that survived the workflow's `score >= 4` cutoff. Most weeks the top-N picks will be in the 7-10 range (the strongly Jennifer-worthy zone). On a thin week they may be 4-6 — still your job to render them as well as the substrate allows, and KK reviews in Postiz before publishing.

Use `signal.title`, `signal.summary`, and `signal.raw.body_excerpt` as the substrate. The `suggested_angle` is a strong hint, not a mandate — if a better angle emerges from the body, take it, but stay anchored in the receipts the signal actually contains. Do NOT invent numbers, named tools, or scenarios the signal doesn't support.

## Structure constraints

**Hook (1-2 lines).** The first 1-2 lines render above LinkedIn's "...see more" fold. They MUST name a stake Jennifer is wrestling with (see kk-voice "What's On Her Mind at 8:15 AM Tuesday" for the menu).

**Hook character target:** ≤210 characters total to render above the fold on mobile. On desktop the fold is more generous (~280-300 chars), but mobile is where Jennifer reads. Plan for mobile.

Forbidden hooks:
- "Excited to announce…" / "Thrilled to share…" / any announcement framing
- Questions to the audience as the hook ("Have you ever wondered…?", "What if I told you…?")  — questions are fine LATER in the post, if at all
- Generic industry observations ("AI is changing security…")
- "10 things every CISO must know" listicle openers

Examples of hook shapes that work (illustrative, do not copy verbatim):
- "Your AI compliance scanner is lying to you about which framework you're failing."
- "We pulled 65 source-verified rules across 5 AI frameworks and three of them were already wrong in the upstream taxonomy."

**Body.** Receipts first. Lead with named tools, real numbers, the concrete scenario from the signal. No general industry observations until the receipts are laid down.

**No bullets, period.** If a thought feels like a list, write it as a sentence with em-dashes or semicolons. Long-form on LinkedIn reads better as prose; bullets break the receipts-first flow.

**Word count target:** 150-280 words. If the best draft naturally lands at 140-149 or 281-300, ship it AND note the deviation in `internal_notes` (e.g., 'Shipped at 142 words — adding filler would have weakened the lesson'). Never pad to hit the minimum — thin content is worse than being short. Never cut a load-bearing receipt to hit the maximum — the lesson must land.

**Generalized lesson (1 line).** A borrowable insight Jennifer can paraphrase in her next meeting and sound sharper. This is the screenshot-worthy line. NOT a CTA. NOT a question to the audience. A finding, a mental model, or a one-line frame she can steal.

**Optional closing line.** Only include if it adds a thought worth sharing — a sharper restatement, a one-line caveat, or KK's own next move. Forbidden:
- "What do you think?" / "Drop your thoughts below" / "Comments welcome"
- "Tag someone who needs to see this"
- Any explicit engagement-bait CTA

If nothing belongs there, end on the generalized lesson.

## Voice constraints (cross-check against kk-voice)

These are highlights — the full voice spec is in `kk-voice`, and the cross-format banned-phrase list lives in `_drafting-shared.md` / `tests/banned-phrases.txt`. The draft MUST satisfy all of these:

- Conversational professional register — KK is talking to Jennifer like he's talking to her over chai.
- Medium-length sentences with occasional short punches. Compound sentences are fine.
- Contractions natural: "you're", "it's", "don't", "I'd".
- **No India/ME-first framing:** regional color is fine; regional subject is not. DPDPA / SAMA / NCA as subject = rewrite.

**Transilience placement rule:** If Transilience appears, it may ONLY appear in the final 1-2 sentences of the post (concretely: the closing sentence and at most one prior sentence). The preceding text must read as a complete, valuable post even if the Transilience mention were removed. Self-check: delete the last 2 sentences mentally — does the post still earn its keep? If no, the Transilience mention is load-bearing and you're pitching, not teaching. Rewrite.

## Hashtag selection

Pick 2-5 hashtags. Each MUST start with `#`. Choose hashtags Jennifer would actually search or follow — operator hashtags, not vendor hashtags. Examples of usable seed pool: `#cybersecurity`, `#aisecurity`, `#ciso`, `#vulnmanagement`, `#appsec`, `#cloudsecurity`, `#grc`, `#promptinjection`, `#redteam`, `#blueteam`. Pick what actually matches the post — don't tack on the seed pool wholesale.

Avoid: `#innovation`, `#thoughtleadership`, `#futureoftech`, `#disruption`, vendor-name hashtags.

## Error handling

Per `_drafting-shared.md`, return the error envelope (with `status: "error"`) when input is unusable. Specific LinkedIn cases:

- If `signal.title`, `signal.summary`, or `signal.raw.body_excerpt` is missing/empty:
  `{"status": "error", "error": "missing field: <name>", "platform": "linkedin", "format": "long-post"}`
- If the input is malformed JSON or not a ScoredSignal shape:
  `{"status": "error", "error": "malformed input", "platform": "linkedin", "format": "long-post"}`

## Output

Return ONLY a single JSON object — per the shared output-strictness rule, no prose, no markdown fence, the first character must be `{` and the last `}`.

Draft success shape:

```json
{
  "status": "ok",
  "platform": "linkedin",
  "format": "long-post",
  "content": "<the post body as a single string, with \\n line breaks between paragraphs>",
  "hashtags": ["#cybersecurity", "..."],
  "internal_notes": "<one line: which 2-3 Jennifer filter criteria this draft hits hardest, in your judgment>"
}
```

Consumers (orchestrator, publisher) MUST check `status` first. `status: "ok"` proceeds to publish; `status: "error"` goes to failed-pushes for follow-up. This convention is shared across all drafters — see `_drafting-shared.md`.

The `content` field is plain text with `\n` line breaks — no markdown, no bullets, no headings. It is the literal text that will be posted to LinkedIn via Postiz.

The `internal_notes` field is for KK reading the draft in interactive mode — name 2-3 of the 7 Jennifer-filter items this draft leans hardest on (e.g., "Hits #3 receipts and #5 makes-her-smarter; #1 stop-scrolling is the gamble"). If the draft shipped at the 140-149 or 281-300 word-count edge, explain why here.
