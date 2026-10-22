#!/usr/bin/env bash
# Runs one integration file in an iPhone simulator for CI (issue #1162),
# and starts it again when the Flutter tool loses the app at launch.
#
#   scripts/ios-sim-test.sh <test file> <simulator udid> <log>
#
# The tool launches the app and, at the same moment, starts the
# simulator's `log stream` it reads the VM service's address from. When
# the app prints "Dart VM Service is listening on" before that stream is
# attached, the line is gone and the tool waits for it with no timeout:
# the app runs, the test never starts, and the step sat until its
# 25-minute ceiling (runs 39673329670, 39680015813). That wait has its
# own limit here, and only that hang is retried: a test that ran and
# failed fails the step as it is.
set -uo pipefail

test_file="${1:?test file}"
udid="${2:?simulator udid}"
log="${3:?log}"

# How long the address may take once the app is launched. A good run
# finds it in well under a second; the Xcode build comes before the
# launch, so it does not count against this.
VM_SERVICE_WAIT="${VM_SERVICE_WAIT:-120}"
ATTEMPTS=3

for attempt in $(seq 1 "$ATTEMPTS"); do
  attempt_log="$log.$attempt"
  flutter test "$test_file" -d "$udid" --flavor beta -v >"$attempt_log" 2>&1 &
  pid=$!
  waiting_since=
  lost=
  while kill -0 "$pid" 2>/dev/null; do
    if grep -q 'VM Service uri is available' "$attempt_log"; then
      waiting_since=
    elif [ -z "$waiting_since" ] &&
      grep -q 'Waiting for VM Service port' "$attempt_log"; then
      waiting_since=$SECONDS
    fi
    if [ -n "$waiting_since" ] &&
      [ $((SECONDS - waiting_since)) -ge "$VM_SERVICE_WAIT" ]; then
      lost=1
      pkill -P "$pid" 2>/dev/null
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      break
    fi
    sleep 5
  done
  if [ -z "$lost" ]; then
    wait "$pid"
    status=$?
    cp "$attempt_log" "$log"
    exit "$status"
  fi
  echo "attempt $attempt: no VM service address after ${VM_SERVICE_WAIT}s, the tool lost the app at launch" |
    tee -a "$attempt_log"
  cp "$attempt_log" "$log"
  xcrun simctl terminate "$udid" dev.niman.niman.beta 2>/dev/null
done
echo "the tool lost the app at launch on all $ATTEMPTS attempts"
exit 1
