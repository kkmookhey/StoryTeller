# Pick Parser

Parses user pick input against the candidate menu rendered in workflow step 5. Source of indices and IDs: `~/.storyteller/last-ideas.json`.

## Accepted syntax

- Space- or comma-separated indices: `1 5 8`, `1, 5, 8`
- `pick <indices>`: `pick 1 5 8`
- Signal IDs (verbatim): `github:kkmookhey/ciso-copilot:pr#18`
- Keywords: `all`, `none`, `skip`

## Volume rules

- 1-3 picks: proceed immediately.
- 4-5 picks: warn ("that's a lot for one batch — proceed?") and proceed on confirmation.
- More than 5 picks: require explicit confirmation before drafting.

## Errors

Reject invalid indices or unknown signal IDs with a one-line error naming what was wrong, then re-prompt. Do NOT silently drop bad entries — the user picked them for a reason and needs to know they didn't land.

## Scheduled mode

Skip the prompt entirely. Auto-pick the top `config.scoring.top_n` entries from the candidate pool.
