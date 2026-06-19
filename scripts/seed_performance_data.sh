#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="${BUNDLE_ID:-com.valentino.WeekHabit}"
DEVICE="${DEVICE:-booted}"

if [[ -n "${APP_PATH:-}" ]]; then
  xcrun simctl install "$DEVICE" "$APP_PATH"
fi

xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl spawn "$DEVICE" defaults write "$BUNDLE_ID" hasCompletedAppOnboarding -bool YES
xcrun simctl spawn "$DEVICE" defaults write "$BUNDLE_ID" debugSeedPerformanceDataOnLaunch -bool YES
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"

echo "Requested WeekHabit performance seed on $DEVICE for $BUNDLE_ID."
