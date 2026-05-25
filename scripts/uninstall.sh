#!/usr/bin/env bash
# Remove the storyteller skill symlink. Does NOT touch ~/.storyteller/
# (your config and state are preserved).
set -euo pipefail
SKILLS=(storyteller kk-voice kk-short-form)
for skill in "${SKILLS[@]}"; do
  dest="${HOME}/.claude/skills/${skill}"
  if [[ -L "${dest}" ]]; then
    rm "${dest}"
    echo "Removed symlink ${dest}"
  elif [[ -e "${dest}" ]]; then
    echo "Refusing to remove ${dest}: it is a directory, not a symlink." >&2
    echo "Remove it manually if you intended to." >&2
  else
    echo "Nothing to remove at ${dest}"
  fi
done
echo "Note: ~/.storyteller/ is preserved (config + state). Delete manually if you want a full reset."
