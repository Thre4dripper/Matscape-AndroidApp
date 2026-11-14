#!/bin/bash
# Renders the app's screens into design/reference/ (see
# tool/screenshots/render_test.dart for the list), then sends them and
# HANDOFF.md to the Open Design project.
#
#   tool/screenshots.sh            render and send
#   tool/screenshots.sh --no-push  render only
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test tool/screenshots/render_test.dart
echo "Rendered $(find design/reference -name '*.png' | wc -l | tr -d ' ') screens into design/reference/"
if [ "${1:-}" != "--no-push" ]; then tool/design-sync.sh push; fi
