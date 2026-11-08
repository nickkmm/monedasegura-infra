#!/usr/bin/env bash
# The checks for monedasegura-app. Exit 0 only when the branch is fit to review.
#
# The gate runs this script with the job's worktree as the working directory.
# Same steps as .github/workflows/ci.yml.
set -euo pipefail

# The Flutter SDK is often only on the interactive shell's PATH.
if ! command -v flutter >/dev/null 2>&1 && [ -x "$HOME/development/flutter/bin/flutter" ]; then
  export PATH="$HOME/development/flutter/bin:$PATH"
fi

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
