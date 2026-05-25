#!/usr/bin/env bash
# Install the storyteller skill into ~/.claude/skills/ via symlink and
# bootstrap user data dir at ~/.storyteller/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_TO_INSTALL=(storyteller kk-voice kk-short-form)
USER_DATA="${HOME}/.storyteller"

mkdir -p "${HOME}/.claude/skills"

for skill in "${SKILLS_TO_INSTALL[@]}"; do
  src="${REPO_ROOT}/skill/${skill}"
  dest="${HOME}/.claude/skills/${skill}"
  if [[ ! -d "${src}" ]]; then
    echo "Skill source missing: ${src}" >&2
    exit 1
  fi
  if [[ -e "${dest}" || -L "${dest}" ]]; then
    echo "Removing existing ${dest}"
    rm -rf "${dest}"
  fi
  ln -s "${src}" "${dest}"
  echo "Linked ${dest} -> ${src}"
done

mkdir -p "${USER_DATA}/pending-video" "${USER_DATA}/failed-pushes"
if [[ ! -f "${USER_DATA}/config.yaml" ]]; then
  cp "${SKILL_SRC}/sample-config.yaml" "${USER_DATA}/config.yaml"
  echo "Created ${USER_DATA}/config.yaml from sample. Edit it to add your repos."
fi
touch "${USER_DATA}/state.jsonl"

cat <<'EOF'

StoryTeller installed.

NEXT STEPS:
  1. Edit ~/.storyteller/config.yaml — add at least one repo under sources.github.repos
  2. Ensure POSTIZ_API_KEY is available to your shell. If not yet persistent,
     add this to your ~/.zshrc (replace the path if your key file is elsewhere):

       export POSTIZ_API_KEY="$(tr -d '[:space:]' < '$HOME/Projects/StoryTeller/Postiz Key.txt')"

     Then either: source ~/.zshrc  OR  open a new terminal so Claude Code inherits it.
  3. In Claude Code, type /storyteller to invoke (interactive mode).

EOF
