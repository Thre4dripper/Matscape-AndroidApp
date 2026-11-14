#!/bin/bash
# Keeps design/ in this repo and the Open Design project in step.
#
#   tool/design-sync.sh pull   Open Design → design/   (the design source)
#   tool/design-sync.sh push   design/ → Open Design   (HANDOFF.md, reference/)
#   tool/design-sync.sh        both: pull, then push
#
# Design source flows one way and the handoff the other, so neither side
# overwrites the other's work. Films, music and rendered images are left
# out: the project's own scripts make them again.
#
# The Open Design project is found from its id in design/.open-design/, in
# ~/Desktop/Open Design/. Set OPEN_DESIGN_DIR to use another folder.
set -euo pipefail
cd "$(dirname "$0")/.."

id=$(sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' design/.open-design/project.json 2>/dev/null | head -1)
dir="${OPEN_DESIGN_DIR:-$HOME/Desktop/Open Design/${id:-}}"
if [ ! -d "$dir" ]; then
  echo "Open Design project not found at: $dir" >&2
  echo "Set OPEN_DESIGN_DIR to its folder." >&2
  exit 1
fi

pull() {
  # What the repo adds (handoff, reference renders, its own notes) is
  # protected, so --delete only removes design files the designer removed.
  rsync -a --delete \
    --exclude '.DS_Store' --exclude '*.mp4' --exclude '*.wav' \
    --exclude 'store/app-store/' --exclude 'store/google-play/' \
    --exclude 'store/videos/' --exclude 'motion-source/*/assets/' \
    --exclude 'brand/icon/export/' \
    --filter 'protect HANDOFF.md' --filter 'protect README.md' \
    --filter 'protect reference/' --filter 'protect .gitignore' \
    --exclude 'HANDOFF.md' --exclude 'reference/' \
    "$dir/" design/
  echo "Pulled the design source into design/"
}

push() {
  cp design/HANDOFF.md "$dir/HANDOFF.md"
  if [ -d design/reference ]; then
    mkdir -p "$dir/reference"
    rsync -a --delete --exclude '.DS_Store' design/reference/ "$dir/reference/"
  fi
  echo "Pushed HANDOFF.md and reference/ to: $dir"
}

case "${1:-both}" in
  pull) pull ;;
  push) push ;;
  both) pull; push ;;
  *) echo "usage: $0 [pull|push]" >&2; exit 2 ;;
esac
