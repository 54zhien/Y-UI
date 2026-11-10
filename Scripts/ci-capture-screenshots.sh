#!/usr/bin/env bash
#
# 在 macOS CI runner 上启动 iPhone 模拟器，安装 Debug 构建并截图：
#   home-light / home-dark           常规字号、浅色与深色
#   home-a11y-xxxl                   辅助功能最大字号（核查底栏与网格不崩）
#   home-narrow-light                窄屏机型（若 runner 上有 SE / mini）
#
# 说明：只采集视觉证据，不驱动任何交互（管理模式、抖动、排序、战争模式切换
# 仍需要人工或 UI 测试验证），截图本身不等于视觉验收。

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

# runner 上没有现成的 SE / mini 时，按设备类型临时建一台窄屏机（375pt 宽，
# 用来触发 isNarrow 分支），用完不清理（runner 是临时的）。
if [ -z "$NARROW" ]; then
  NARROW_TYPE="$(xcrun simctl list devicetypes | sed -n 's/.*(\(com\.apple\.CoreSimulator\.SimDeviceType\.iPhone-SE[^)]*\)).*/\1/p' | tail -1)"
  NARROW_RUNTIME="$(xcrun simctl list runtimes | sed -n 's/.*(\(com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]*\)).*/\1/p' | tail -1)"
  if [ -n "$NARROW_TYPE" ] && [ -n "$NARROW_RUNTIME" ]; then
    NARROW="$(xcrun simctl create "dsh-narrow" "$NARROW_TYPE" "$NARROW_RUNTIME" 2>/dev/null || true)"
  fi
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

ls -l "$OUT_DIR"
