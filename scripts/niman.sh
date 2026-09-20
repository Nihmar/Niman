#!/usr/bin/env bash
# Niman dev helper: terse output, full logs in /tmp/niman/niman-<cmd>.log.
#   analyze | test | check | integration | apk [testing] | linux
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

integration() {
  # The end-to-end tests (issue #241): the two that run headless first,
  # then the WebDAV sync flow on the Linux desktop. The sync test needs
  # a display; it cannot run headless or in CI. Each file gets its own
  # invocation: files under integration_test/ share one device run, and
  # a second file in the same command never starts.
  flutter test integration_test/app_boot_test.dart >"$log" 2>&1
  local status=$?
  tail -n 4 "$log"
  if [ $status -ne 0 ]; then return $status; fi
  flutter test integration_test/template_backlink_freeze_test.dart \
    >>"$log" 2>&1
  status=$?
  tail -n 4 "$log"
  if [ $status -ne 0 ]; then return $status; fi
  flutter test integration_test/sync_e2e_test.dart -d linux >>"$log" 2>&1
  status=$?
  tail -n 8 "$log"
  return $status
}

apk() {
  # The official APK by default; "beta" builds the testing build.
  local flavor="${1:-official}"
  if [ "$flavor" = "beta" ]; then
    # The testing build (issue #106): the release pipeline plus the
    # flavor's separate application ID; APP_CHANNEL marks the Dart
    # side, which hides and skips update management.
    flutter build apk --release --flavor "$flavor" --dart-define="APP_CHANNEL=testing" >"$log" 2>&1
  else
    # The official APK (issue #106): AGP drops the no-flavor variant
    # once the channel dimension has a flavor, so the official build
    # is the explicit "official" flavor (no application ID suffix).
    flutter build apk --release --flavor official >"$log" 2>&1
  fi
  local status=$?
  tail -n 3 "$log"
  if [ $status -eq 0 ]; then
    echo "artifact: build/app/outputs/flutter-apk/app-$flavor-release.apk"
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
usage: ./scripts/niman.sh <analyze|test|check|integration|apk|linux>
  analyze  flutter analyze --fatal-infos (issue lines + summary only)
  test     flutter test (tail only)
  check    analyze + test; use before committing
  integration  the integration_test/ suite (issue #241);
             sync_e2e needs a Linux display
  apk [beta]      flutter build apk --release
                  (beta: the testing build, app ID dev.niman.niman.beta)
  linux    flutter build linux --release
Full logs: /tmp/niman/niman-<cmd>.log
EOF
}

case "$cmd" in
  analyze) analyze ;;
  test) test_all ;;
  check) analyze && test_all ;;
  integration) integration ;;
  apk) apk "${2:-}" ;;
  linux) linux_build ;;
  *) usage; exit 1 ;;
esac
