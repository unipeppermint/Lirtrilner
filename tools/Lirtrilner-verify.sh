#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
report_dir="docs/release-v1/verification"
build_dir="${LIRTRILNER_BUILD_DIR:-/private/tmp/Lirtrilner-build}"
mkdir -p "$report_dir"
swift test --scratch-path /private/tmp/Lirtrilner-swift-build > "$report_dir/core-tests.log" 2>&1
xcodebuild -project Lirtrilner.xcodeproj -scheme Lirtrilner -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$build_dir" CODE_SIGNING_ALLOWED=NO build \
  > "$report_dir/simulator-build.log" 2>&1
xcodebuild -project Lirtrilner.xcodeproj -scheme Lirtrilner -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/Lirtrilner-release \
  -archivePath /private/tmp/Lirtrilner-1.0.xcarchive CODE_SIGNING_ALLOWED=NO archive \
  > "$report_dir/release-archive.log" 2>&1
xcodebuild -project Lirtrilner.xcodeproj -scheme Lirtrilner -configuration Release \
  -showBuildSettings > "$report_dir/release-settings.log" 2>&1
printf 'Core tests, simulator build and unsigned Release archive passed.\n'
