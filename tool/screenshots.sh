#!/bin/bash
# Renders the app's screens into design/reference/, where the designer reads
# them. The list of screens is in tool/screenshots/render_test.dart.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test tool/screenshots/render_test.dart
echo "Rendered $(find design/reference -name '*.png' | wc -l | tr -d ' ') screens into design/reference/"
