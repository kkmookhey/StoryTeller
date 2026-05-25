# Drafting: LinkedIn long-form post

Draft a single LinkedIn long-form post for KK Mookhey from one ScoredSignal. Output strict JSON, no prose around it.

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

The orchestrator only calls this drafter for signals with `score >= 7`. You can trust the input has substance worth posting; your job is to render that substance as a Jennifer-grade post.

Use `signal.title`, `signal.summary`, and `signal.raw.body_excerpt` as the substrate. The `suggested_angle` is a strong hint, not a mandate — if a better angle emerges from the body, take it, but stay anchored in the receipts the signal actually contains. Do NOT invent numbers, named tools, or scenarios the signal doesn't support.

## Structure constraints

**Hook (1-2 lines).** The first 1-2 lines render above LinkedIn's "...see more" fold. They MUST name a stake Jennifer is wrestling with (see kk-voice "What's On Her Mind at 8:15 AM Tuesday" for the menu). Forbidden hooks:
- "Excited to announce…" / "Thrilled to share…" / any announcement framing
- Questions to the audience as the hook ("Have you ever wondered…?", "What if I told you…?")  — questions are fine LATER in the post, if at all
- Generic industry observations ("AI is changing security…")
- "10 things every CISO must know" listicle openers

Examples of hook shapes that work (illustrative, do not copy verbatim):
- "Your AI compliance scanner is lying to you about which framework you're failing."
- "We pulled 65 source-verified rules across 5 AI frameworks and three of them were already wrong in the upstream taxonomy."

**Body (150-280 words total, including the hook).** Receipts first. Lead with named tools, real numbers, the concrete scenario from the signal. No general industry observations until the receipts are laid down. The 150-280 range is firm — LinkedIn's algorithm rewards posts in this range; shorter feels thin, longer gets truncated.

**Generalized lesson (1 line).** A borrowable insight Jennifer can paraphrase in her next meeting and sound sharper. This is the screenshot-worthy line. NOT a CTA. NOT a question to the audience. A finding, a mental model, or a one-line frame she can steal.

**Optional closing line.** Only include if it adds a thought worth sharing — a sharper restatement, a one-line caveat, or KK's own next move. Forbidden:
- "What do you think?" / "Drop your thoughts below" / "Comments welcome"
- "Tag someone who needs to see this"
- Any explicit engagement-bait CTA

If nothing belongs there, end on the generalized lesson.

## Voice constraints (cross-check against kk-voice)

These are highlights — the full voice spec is in `kk-voice`. The draft MUST satisfy all of these:

- Conversational professional register — KK is talking to Jennifer like he's talking to her over chai.
- Medium-length sentences with occasional short punches. Compound sentences are fine.
- Contractions natural: "you're", "it's", "don't", "I'd".
- **No corporate jargon:** "leverage" (verb), "synergy", "alignment", "stakeholder buy-in", "deep dive", "circle back", "touch base".
- **No AI-slop language:** "It's important to note", "In today's rapidly evolving landscape", "delve into", "navigate the complexities of".
- **No founder-journey framing for Jennifer:** "how I scaled to $X ARR", "our Series A story", "the journey of building".
- **No India/ME-first framing:** regional color is fine; regional subject is not. DPDPA / SAMA / NCA as subject = rewrite.
- **If Transilience appears in the signal or draft:** problem must dominate the first 80% of the post; product (Transilience) only appears in the last 20%. If the signal is a Transilience PR, the draft is about the *problem the PR addresses*, not the PR itself.

## Hashtag selection

Pick 2-5 hashtags. Each MUST start with `#`. Choose hashtags Jennifer would actually search or follow — operator hashtags, not vendor hashtags. Examples of usable seed pool: `#cybersecurity`, `#aisecurity`, `#ciso`, `#vulnmanagement`, `#appsec`, `#cloudsecurity`, `#grc`, `#promptinjection`, `#redteam`, `#blueteam`. Pick what actually matches the post — don't tack on the seed pool wholesale.

Avoid: `#innovation`, `#thoughtleadership`, `#futureoftech`, `#disruption`, vendor-name hashtags.

## Error handling

Source-level failures must NEVER propagate as exceptions or prose. The orchestrator expects this prompt to always return a valid JSON object.

- If `signal.title`, `signal.summary`, or `signal.raw.body_excerpt` is missing/empty, return `{"error": "missing field: <name>", "platform": "linkedin", "format": "long-post"}` instead of a draft.
- If the input is malformed JSON or not a ScoredSignal shape, return `{"error": "malformed input", "platform": "linkedin", "format": "long-post"}`.
- Never throw. Never return prose. Never return `null`. Always return a JSON object.

## Output

Return ONLY a single JSON object — no prose around it, no markdown fence, no commentary. The first character of the output must be `{` and the last `}`.

```json
{
  "platform": "linkedin",
  "format": "long-post",
  "content": "<the post body as a single string, with \\n line breaks between paragraphs>",
  "hashtags": ["#cybersecurity", "..."],
  "internal_notes": "<one line: which 2-3 Jennifer filter criteria this draft hits hardest, in your judgment>"
}
```

The `content` field is plain text with `\n` line breaks — no markdown, no bullets unless the post genuinely calls for them, no headings. It is the literal text that will be posted to LinkedIn via Postiz.

The `internal_notes` field is for KK reading the draft in interactive mode — name 2-3 of the 7 Jennifer-filter items this draft leans hardest on (e.g., "Hits #3 receipts and #5 makes-her-smarter; #1 stop-scrolling is the gamble").
