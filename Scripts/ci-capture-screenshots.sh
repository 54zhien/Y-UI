set -euo pipefail

BUNDLE_ID="com.dsh.yui.demo"
APP_PATH="build/Build/Products/Debug-iphonesimulator/YUI.app"
OUT_DIR="artifacts"

mkdir -p "$OUT_DIR"

if [ ! -d "$APP_PATH" ]; then
  echo "built app not found: ${APP_PATH}"
  exit 1
fi

DEVICES="$(xcrun simctl list devices available -j | python3 -c '
import json, sys

data = json.load(sys.stdin)["devices"]
phones = [
    device
    for devices in data.values()
    for device in devices
    if device.get("isAvailable") and "iPhone" in device.get("name", "")
]
narrow = [
    device
    for device in phones
    if "SE" in device.get("name", "") or "mini" in device.get("name", "")
]
print(phones[0]["udid"] if phones else "", narrow[0]["udid"] if narrow else "")
')"

PRIMARY="$(echo "$DEVICES" | awk '{print $1}')"
NARROW="$(echo "$DEVICES" | awk '{print $2}')"

if [ -z "$NARROW" ]; then
  NARROW_RUNTIME="$(xcrun simctl list runtimes | sed -n 's/.*com\.apple\.CoreSimulator\.SimRuntime\.\(iOS-[0-9-]*\).*/com.apple.CoreSimulator.SimRuntime.\1/p' | tail -1)"
  echo "narrow runtime: ${NARROW_RUNTIME:-none}"
  for narrow_type in \
    com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation \
    com.apple.CoreSimulator.SimDeviceType.iPhone-13-mini; do
    if [ -z "$NARROW_RUNTIME" ]; then break; fi
    if ! xcrun simctl list devicetypes | grep -Fq "$narrow_type"; then continue; fi
    created="$(xcrun simctl create dsh-narrow "$narrow_type" "$NARROW_RUNTIME" 2>&1 || true)"
    if printf '%s' "$created" | grep -Eq '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-'; then
      NARROW="$created"
      echo "created narrow simulator ${NARROW} from ${narrow_type}"
      break
    else
      echo "create failed for ${narrow_type}: ${created}"
    fi
  done
fi
if [ -z "$PRIMARY" ]; then
  echo "no available iPhone simulator"
  exit 1
fi

echo "primary simulator: ${PRIMARY}"
echo "narrow simulator: ${NARROW:-none}"

capture() {
  local udid="$1"
  local appearance="$2"
  local content_size="$3"
  local name="$4"

  echo "== capture ${name}: appearance=${appearance} content_size=${content_size:-default} =="
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$APP_PATH"

  if [ -n "$content_size" ]; then
    xcrun simctl ui "$udid" content_size "$content_size" || echo "content_size not applied; using default text size"
  fi

  xcrun simctl ui "$udid" appearance "$appearance"
  xcrun simctl launch "$udid" "$BUNDLE_ID" > /dev/null
  sleep 8
  xcrun simctl io "$udid" screenshot "$OUT_DIR/$name.png"
  xcrun simctl terminate "$udid" "$BUNDLE_ID" || true
}

capture "$PRIMARY" light "" "home-light"
capture "$PRIMARY" dark "" "home-dark"
capture "$PRIMARY" light "accessibility-extra-extra-extra-large" "home-a11y-xxxl"

if [ -n "$NARROW" ]; then
  capture "$NARROW" light "" "home-narrow-light"
else
  echo "no narrow iPhone available; skipping home-narrow-light"
fi

if [ -n "$PRIMARY" ]; then
  xcrun simctl ui "$PRIMARY" appearance light || true
  xcrun simctl ui "$PRIMARY" content_size large || true
fi

ls -l "$OUT_DIR"
