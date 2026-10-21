#!/usr/bin/env bash
# Niman dev helper: terse output, full logs in /tmp/niman/niman-<cmd>.log.
#   analyze | test | check | integration | apk [beta] | linux [beta] | macos [beta]
set -u

# Flutter fallback when not on PATH (AGENTS.md: Env).
if ! command -v flutter >/dev/null 2>&1   && [ -x "$HOME/develop/flutter/bin/flutter" ]; then
  export PATH="$PATH:$HOME/develop/flutter/bin"
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter not found - export PATH or install under $HOME/develop/flutter" >&2
  exit 1
fi

cmd="${1:-}"
mkdir -p /tmp/niman
log="/tmp/niman/niman-${cmd}.log"
# The commit a build is made from, named in its exported debug log
# (APP_COMMIT, issue #1135).
commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
# A tree with uncommitted changes is not the commit it was cut from: the build
# says so (-dirty), or an exported log names a commit the code never was.
# Untracked files count, except the agents' own folder (.claude/).
if [ "$commit" != unknown ] &&
  git status --porcelain 2>/dev/null | grep -qv '^?? \.claude/'; then
  commit="$commit-dirty"
fi

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
  # then the WebDAV sync flow on the Linux desktop. The sync test needs a
  # display; locally the session has one, and CI runs it under xvfb with
  # `-d linux` (#363). Each file gets its own invocation: files under
  # integration_test/ share one device run, and a second file in the same
  # command never starts.
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
  # Only the flavors declared in android/app/build.gradle.kts exist: refuse
  # anything else before building, or the run reports a path
  # (app-<typo>-release.apk) for an artifact that never was produced
  # (issue #393).
  case "$flavor" in
    official | beta | frames) ;;
    *)
      echo "error: unknown apk flavor '$flavor' (expected official, beta or frames)" >&2
      usage >&2
      return 2
      ;;
  esac
  if [ "$flavor" = "frames" ]; then
    # The device run of #1145: the testing build in profile mode with the
    # frame instrumentation on, so an exported log splits each action's
    # frames into build and raster and carries its memory (#1144).
    flutter build apk --profile --flavor beta --dart-define="APP_CHANNEL=testing" \
      --dart-define=NIMAN_FRAMES=true --target-platform android-arm64 \
      --dart-define="APP_COMMIT=$commit" >"$log" 2>&1
    local status=$?
    tail -n 3 "$log"
    if [ $status -eq 0 ]; then
      echo "artifact: build/app/outputs/flutter-apk/app-beta-profile.apk"
    fi
    return $status
  fi
  if [ "$flavor" = "beta" ]; then
    # The testing build (issue #106): the release pipeline plus the
    # flavor's separate application ID; APP_CHANNEL marks the Dart
    # side, which hides and skips update management.
    flutter build apk --release --flavor "$flavor" --dart-define="APP_CHANNEL=testing" \
      --target-platform android-arm64 --dart-define="APP_COMMIT=$commit" >"$log" 2>&1
  else
    # The official APK (issue #106): AGP drops the no-flavor variant
    # once the channel dimension has a flavor, so the official build
    # is the explicit "official" flavor (no application ID suffix).
    flutter build apk --release --flavor official \
      --target-platform android-arm64 --dart-define="APP_COMMIT=$commit" >"$log" 2>&1
  fi
  local status=$?
  tail -n 3 "$log"
  if [ $status -eq 0 ]; then
    echo "artifact: build/app/outputs/flutter-apk/app-$flavor-release.apk"
  fi
  return $status
}

linux_build() {
  # beta: the testing build, with a support folder of its own (niman-testing)
  # so it never shares a database with the installed release.
  local channel=()
  if [ "${1:-}" = "beta" ]; then channel=(--dart-define=APP_CHANNEL=testing); fi
  flutter build linux --release "${channel[@]}" \
    --dart-define="APP_COMMIT=$commit" >"$log" 2>&1
  local status=$?
  tail -n 3 "$log"
  if [ $status -eq 0 ]; then
    echo "artifact: build/linux/x64/release/bundle/niman"
  fi
  return $status
}

macos_build() {
  # The official app by default; "beta" builds the testing build. Both are
  # Xcode schemes (macos/Runner.xcodeproj): beta has a bundle id of its own,
  # dev.niman.niman.beta, and with it its own Application Support folder.
  local flavor="${1:-official}"
  local name="Niman"
  # The OCR engine is bundled in the Mac app (an Xcode build phase copies
  # it in): built once, then reused.
  local ocr=build/ocr-engine/niman-ocr-macos-universal.dylib
  if [ ! -f "$ocr" ]; then
    echo "building the OCR engine (once)..."
    ./scripts/ocr-engine.sh macos-universal build/ocr-engine >"$log" 2>&1 ||
      { tail -n 20 "$log"; return 1; }
  fi
  case "$flavor" in
    official) flutter build macos --release --flavor official >"$log" 2>&1 ;;
    beta)
      name="Niman (Testing)"
      flutter build macos --release --flavor beta \
        --dart-define=APP_CHANNEL=testing >"$log" 2>&1
      ;;
    *)
      echo "error: unknown macos flavor '$flavor' (expected official or beta)" >&2
      usage >&2
      return 2
      ;;
  esac
  local status=$?
  tail -n 3 "$log"
  if [ $status -ne 0 ]; then return $status; fi
  local app="build/macos/Build/Products/Release-$flavor/$name.app"
  echo "artifact: $app"
  # The disk image the release attaches and the updater opens
  # (lib/src/update/release_asset.dart): the app beside a link to
  # Applications, to drag it onto.
  local version suffix=""
  version="$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)"
  [ "$flavor" = beta ] && suffix=-testing
  local dmg="build/macos/niman-$version-macos$suffix.dmg"
  macos_dmg "$app" "$name" "$dmg" || { tail -n 5 "$log"; return 1; }
  echo "artifact: $dmg"
}
macos_dmg() { # <app> <volume name> <dmg>
  local stage
  stage="$(mktemp -d)"
  cp -R "$1" "$stage/" && ln -s /Applications "$stage/Applications" || return 1
  rm -f "$3"
  # diskutil's own command where the system has it; hdiutil's create, which
  # it deprecates, on an older macOS.
  if diskutil image create from --help >/dev/null 2>&1; then
    diskutil image create from --format UDZO --volumeName "$2" \
      "$stage" "$3" >>"$log" 2>&1
  else
    hdiutil create -volname "$2" -srcfolder "$stage" -format UDZO "$3" \
      >>"$log" 2>&1
  fi
  local status=$?
  rm -rf "$stage"
  return $status
}
usage() {
  cat <<'EOF'
usage: ./scripts/niman.sh <analyze|test|check|integration|apk|linux|macos>
  analyze  flutter analyze --fatal-infos (issue lines + summary only)
  test     flutter test (tail only)
  check    analyze + test; use before committing
  integration  the integration_test/ suite (issue #241);
             sync_e2e needs a Linux display
  apk [beta|frames]  flutter build apk --release
                  (beta: the testing build, app ID dev.niman.niman.beta;
                   frames: that build in profile mode with NIMAN_FRAMES)
  linux [beta]    flutter build linux --release
                  (beta: the testing build, its own data folder niman-testing)
  macos [beta]    flutter build macos --release, and its disk image
                  (beta: the testing build, bundle id dev.niman.niman.beta)
Full logs: /tmp/niman/niman-<cmd>.log
EOF
}

case "$cmd" in
  analyze) analyze ;;
  test) test_all ;;
  check) analyze && test_all ;;
  integration) integration ;;
  apk) apk "${2:-}" ;;
  linux) linux_build "${2:-}" ;;
  macos) macos_build "${2:-}" ;;
  *) usage; exit 1 ;;
esac
