#!/usr/bin/env bash
# simulate_push.sh — Send a simulated push notification to the running iOS Simulator.
#
# Usage:
#   ./simulate_push.sh                          # uses default push_payload.json
#   ./simulate_push.sh "Custom Title" "Body"    # inline title + body

set -euo pipefail

BUNDLE_ID="com.appstudio.AppTemplate"
PAYLOAD_FILE="$(dirname "$0")/push_payload.json"

# Optional: build a one-shot payload from arguments
if [[ $# -ge 2 ]]; then
  TITLE="$1"
  BODY="$2"
  PAYLOAD_FILE="$(mktemp /tmp/push_payload_XXXX.json)"
  cat > "$PAYLOAD_FILE" <<JSON
{
  "Simulator Target Bundle": "${BUNDLE_ID}",
  "aps": {
    "alert": { "title": "${TITLE}", "body": "${BODY}" },
    "sound": "default"
  }
}
JSON
  trap "rm -f $PAYLOAD_FILE" EXIT
fi

# Get the booted simulator UDID
SIMULATOR=$(xcrun simctl list devices booted --json \
  | python3 -c "
import sys, json
devices = json.load(sys.stdin)['devices']
booted = [d for devs in devices.values() for d in devs if d['state'] == 'Booted']
print(booted[0]['udid'] if booted else 'booted')
")

echo "→ Sending push to simulator: ${SIMULATOR}"
echo "  Bundle: ${BUNDLE_ID}"
echo "  Payload: ${PAYLOAD_FILE}"
xcrun simctl push "${SIMULATOR}" "${BUNDLE_ID}" "${PAYLOAD_FILE}"
echo "✓ Push delivered"
