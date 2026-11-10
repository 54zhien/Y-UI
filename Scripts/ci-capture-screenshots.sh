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
  echo "找不到构建产物：$APP_PATH"
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

if [ -z "$PRIMARY" ]; then
  echo "没有可用的 iPhone 模拟器"
  exit 1
fi

echo "主模拟器：$PRIMARY"
echo "窄屏模拟器：${NARROW:-（无）}"

capture() {
  local udid="$1"
  local appearance="$2"
  local content_size="$3"
  local name="$4"

  echo "== 截图：$name（appearance=$appearance, content_size=${content_size:-默认}）=="
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$APP_PATH"

  if [ -n "$content_size" ]; then
    xcrun simctl ui "$udid" content_size "$content_size" || echo "content_size 设置不生效，按默认字号截图"
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
  echo "没有窄屏机型，跳过 home-narrow-light"
fi

ls -l "$OUT_DIR"
