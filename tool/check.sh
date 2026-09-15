#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib tool test
flutter analyze --no-pub
dart run tool/attendance.dart validate
flutter test --no-pub
bash tool/smoke_assets.sh
flutter build web --release --no-pub --no-web-resources-cdn --base-href "${1:-/}"
