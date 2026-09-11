#!/usr/bin/env bash
# Niman dev helper: terse output, full logs in /tmp/niman/niman-<cmd>.log.
#   analyze | test | check | apk | linux
set -u

# Flutter fallback when not on PATH (AGENTS.md: Env).
if ! command -v flutter >/dev/null 2>&1   && [ -x /home/alessandro/develop/flutter/bin/flutter ]; then
  export PATH="$PATH:/home/alessandro/develop/flutter/bin"
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter not found - export PATH or install under /home/alessandro/develop/flutter" >&2
  exit 1
fi

cmd="${1:-}"
mkdir -p /tmp/niman
log="/tmp/niman/niman-${cmd}.log"

analyze() {
  flutter analyze --fatal-infos >"$log" 2>&1
  local status=$?
  grep -n '•' "$log" | head -30   # issue lines only; nothing when clean
  tail -n 2 "$log"
  return $status
}

test_all() {
  flutter test >"$log" 2>&1
  local status=$?
  tail -n 8 "$log"
  return $status
}

apk() {
  flutter build apk --release >"$log" 2>&1
  local status=$?
  tail -n 3 "$log"
  if [ $status -eq 0 ]; then
    echo "artifact: build/app/outputs/flutter-apk/app-release.apk"
  fi
  return $status
}

linux_build() {
  flutter build linux --release >"$log" 2>&1
  local status=$?
  tail -n 3 "$log"
  if [ $status -eq 0 ]; then
    echo "artifact: build/linux/x64/release/bundle/niman"
  fi
  return $status
}

usage() {
  cat <<'EOF'
usage: ./scripts/niman.sh <analyze|test|check|apk|linux>
  analyze  flutter analyze --fatal-infos (issue lines + summary only)
  test     flutter test (tail only)
  check    analyze + test; use before committing
  apk      flutter build apk --release
  linux    flutter build linux --release
Full logs: /tmp/niman/niman-<cmd>.log
EOF
}

case "$cmd" in
  analyze) analyze ;;
  test) test_all ;;
  check) analyze && test_all ;;
  apk) apk ;;
  linux) linux_build ;;
  *) usage; exit 1 ;;
esac
