#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# -ne 2 ]]; then
  printf 'Usage: bash tools/Lirtrilner-render-audit.sh SIMULATOR_UUID OUTPUT_NAME\n'
  exit 1
fi
device_id="$1"
output_name="$2"
app_path="${LIRTRILNER_BUILD_DIR:-/private/tmp/Lirtrilner-build}/Build/Products/Debug-iphonesimulator/Lirtrilner.app"
xcrun simctl install "$device_id" "$app_path"
container_path="$(xcrun simctl get_app_container "$device_id" com.ztmpa.Lirtrilner data)"
if [[ -f "$container_path/Documents/RenderAudit/report.txt" ]]; then
  mv "$container_path/Documents/RenderAudit/report.txt" "$container_path/Documents/RenderAudit/report.previous.txt"
fi
xcrun simctl launch --terminate-running-process "$device_id" com.ztmpa.Lirtrilner -LirtrilnerRenderAudit
# This waits for the development audit's file output, not for simulated UI input.
for attempt in $(seq 1 60); do
  if [[ -f "$container_path/Documents/RenderAudit/report.txt" ]]; then
    mkdir -p "docs/release-v1/verification/$output_name"
    cp -R "$container_path/Documents/RenderAudit/." "docs/release-v1/verification/$output_name/"
    printf 'Saved render audit to %s\n' "docs/release-v1/verification/$output_name"
    exit 0
  fi
  sleep 1
done
printf 'Render audit did not finish within 60 seconds.\n' >&2
exit 1
