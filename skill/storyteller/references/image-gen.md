# Image Generation — Nano Banana Pro via gen_image.sh

Generate ONE shared image per picked signal, reused for LinkedIn long-post and X thread.
Instagram (held) gets the same image at shoot time; Reels uses the image as the opening static frame.

**Prereq:** `GEMINI_API_KEY` set in env OR `Gemini Key.txt` present at the Fitzroy repo root. The helper handles both (override with `GEMINI_KEY_FILE` env var if your key file lives elsewhere).

**Brand style:** the Quiet Paper block is baked into `scripts/gen_image.sh`. Don't duplicate it in callers — edit the script if KK changes the aesthetic.

## When to call

Step 7.5 of the SKILL.md workflow — after text drafts validate (`status: "ok"`), before the review loop. One image per picked signal, not per format.

## File naming

```
~/.storyteller/images/<safe_signal_id>.png
```

Where `<safe_signal_id>` follows the same rule as `pending-video/`:
- Replace `:` with `_`
- Replace `/` with `_`
- Replace `#` with `_`
- Replace `.` with `_`

Examples:
- `slack:C0EXAMPLE01:1779289833.557529` → `slack_C0EXAMPLE01_1779289833_557529.png`
- `github:kkmookhey/ciso-copilot:pr#25` → `github_kkmookhey_ciso-copilot_pr_25.png`

If the file already exists for this signal_id, skip the API call (idempotent re-runs cost nothing).

## Prompt construction

The orchestrator builds the image prompt from the picked signal, NOT from the post body. The body is too long and too prose-y; the image needs a single visual concept.

Use this template:

```
A single visual metaphor for: <signal.title>.
Angle: <signal.suggested_angle>
Mood: <derive from voice — confident, operator-first, never panicked or sensationalised>
No text on the image (or at most 3-5 words of large editorial type).
```

Rules:
- **No long quotes baked into the image.** Even Nano Banana Pro struggles past ~6 words. The image is a visual companion, not a poster.
- **No logos, no brand marks.** Generated images that include "Transilience" or similar will be wrong — leave that to design tools.
- **One concept, not three.** If the signal has multiple receipts, pick the most visual one.
- **Worked example** (for the velocity-memo signal):
  > "A single visual metaphor for: SaaS are dying, velocity is the only moat.
  > Angle: A founder telling their team that shipping pace beats architectural perfection.
  > Mood: Resolute. A figure or object mid-motion — leaning forward, mid-step, mid-write.
  > No text on the image."

## Invocation

```bash
bash ~/.claude/skills/storyteller/scripts/gen_image.sh \
  "<the constructed prompt>" \
  "$HOME/.storyteller/images/<safe_signal_id>.png"
```

Stdout on success: the absolute path of the written PNG.
Non-zero exit + stderr message on failure.

## Error handling

If `gen_image.sh` exits non-zero:
1. Log the stderr to `~/.storyteller/failed-pushes/<safe_signal_id>-image.log`.
2. Continue the workflow text-only — every format that supports an optional image (LinkedIn, X) publishes WITHOUT `-m`. Instagram + Reels stay held regardless.
3. Surface the failure in the final Slack notification (orchestrator appends `:warning: image gen failed for {signal_id}` to the template).

NEVER block publishing on image failure — text posts are still worth shipping. The image is an enhancement, not a gate.

## Model override

The helper defaults to `gemini-3-pro-image-preview` (Nano Banana Pro). For cost control on dry-runs:

```bash
STORYTELLER_IMAGE_MODEL=gemini-2.5-flash-image bash scripts/gen_image.sh ...
```

## Cost note

Nano Banana Pro lands around USD 0.04–0.06 per 1080×1080 image. With one image per picked signal and `top_n: 3`, scheduled runs cost ~USD 0.15/run. Interactive runs depend on how many picks KK makes — usually 1–3.
