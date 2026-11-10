set -euo pipefail

OUT="artifacts/icon"
APP="build/Build/Products/Debug-iphonesimulator/YUI.app"

mkdir -p "$OUT"

if [ ! -d "$APP" ]; then
  echo "simulator app bundle not found"
  exit 1
fi

for f in "$APP"/AppIcon*.png; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  xcrun pngcrush -revert-iphone-optimizations -q "$f" "$OUT/$base" 2>/dev/null || cp "$f" "$OUT/$base"
done

ls -la "$OUT" | tee "$OUT/icon-files.txt"

UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys

data = json.load(sys.stdin)["devices"]
phones = [
    device
    for devices in data.values()
    for device in devices
    if device.get("isAvailable") and "iPhone" in device.get("name", "")
]
print(phones[0]["udid"] if phones else "")
')"

if [ -z "$UDID" ]; then
  echo "no available iPhone simulator for icon capture"
  exit 1
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl uninstall "$UDID" com.dsh.yui.demo 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"

capture_home() {
  local name="$1"
  local appearance="$2"
  xcrun simctl ui "$UDID" appearance "$appearance" || true
  xcrun simctl spawn "$UDID" launchctl stop com.apple.springboard || true
  sleep 5
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png"
}

xcrun simctl ui "$UDID" appearance light || true
capture_home "home-icon-light" light
capture_home "home-icon-dark" dark

set +e
xcrun simctl ui "$UDID" icon_style tinted > "$OUT/tinted-attempt.txt" 2>&1
echo "exit=$?" >> "$OUT/tinted-attempt.txt"
set -e
cat "$OUT/tinted-attempt.txt" || true

xcrun simctl ui "$UDID" appearance light || true
