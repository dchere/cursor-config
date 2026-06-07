#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CURSOR_DIR="${HOME}/.cursor"
SKILLS_LINK="${CURSOR_DIR}/skills"
AGENTS_LINK="${CURSOR_DIR}/agents"

mkdir -p "${CURSOR_DIR}"

link_dir() {
  local target="$1"
  local source="$2"
  local name="$3"

  if [[ -L "${target}" ]]; then
    current="$(readlink "${target}")"
    if [[ "${current}" == "${source}" ]]; then
      echo "OK: ${name} already linked to ${source}"
      return
    fi
    echo "Replacing existing symlink: ${target} -> ${source}"
    rm "${target}"
  elif [[ -e "${target}" ]]; then
    backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing ${name} to ${backup}"
    mv "${target}" "${backup}"
  fi

  ln -s "${source}" "${target}"
  echo "Linked ${target} -> ${source}"
}

link_dir "${SKILLS_LINK}" "${ROOT}/skills" "skills"
link_dir "${AGENTS_LINK}" "${ROOT}/agents" "agents"

echo ""
echo "Verify:"
echo "  ls -la ${SKILLS_LINK}"
echo "  ls -la ${AGENTS_LINK}"
