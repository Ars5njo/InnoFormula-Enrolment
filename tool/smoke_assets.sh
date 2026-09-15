#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
first=assets/attendance/2000-01-01-smoke-first.txt
second=assets/attendance/2000-01-02-smoke-second.txt
if [[ -e "$first" || -e "$second" ]]; then
  echo 'Имена временных встреч уже заняты.' >&2
  exit 1
fi
trap 'rm -f "$first" "$second"' EXIT
cat > "$first" <<'DATA'
a.alpha
b.bravo
c.charlie
d.delta
e.echo
f.foxtrot
g.golf
v.veryveryveryverylong-surname
DATA
cat > "$second" <<'DATA'
a.alpha
b.bravo
c.charlie
d.delta
DATA
dart run tool/attendance.dart validate
flutter test --no-pub test/bundled_assets_test.dart
if [[ "${1:-}" == '--preview' ]]; then
  flutter build web --release --no-pub --no-web-resources-cdn --output build/fixture-preview --base-href /
fi
