#!/usr/bin/env bash
#
# 在 macOS CI runner 上启动 iPhone 模拟器，安装 Debug 构建，分别以浅色和深色
# 外观截图到 artifacts/。
#
# 说明：只采集视觉证据，不驱动任何交互（管理模式、抖动、排序、战争模式切换
# 仍需要人工或 UI 测试验证）。

set -euo pipefail

BUNDLE_ID="com.dsh.yui.demo"
APP_PATH="build/Build/Products/Debug-iphonesimulator/YUI.app"
OUT_DIR="artifacts"

mkdir -p "$OUT_DIR"

if [ ! -d "$APP_PATH" ]; then
  echo "找不到构建产物：$APP_PATH"
  exit 1
fi

UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys

data = json.load(sys.stdin)["devices"]
candidates = [
    device
    for runtime, devices in data.items()
    for device in devices
    if device.get("isAvailable") and "iPhone" in device.get("name", "")
]
print(candidates[0]["udid"] if candidates else "")
')"

if [ -z "$UDID" ]; then
  echo "没有可用的 iPhone 模拟器"
  exit 1
fi

echo "使用模拟器：$UDID"
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP_PATH"

for appearance in light dark; do
  echo "== 外观：$appearance =="
  xcrun simctl ui "$UDID" appearance "$appearance"
  xcrun simctl launch "$UDID" "$BUNDLE_ID" > /dev/null
  sleep 8
  xcrun simctl io "$UDID" screenshot "$OUT_DIR/home-$appearance.png"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" || true
done

ls -l "$OUT_DIR"
