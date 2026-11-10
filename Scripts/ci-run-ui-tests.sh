#!/usr/bin/env bash
#
# 在 macOS CI runner 的 iPhone 模拟器上运行 XCUITest，验证真实交互：
# 管理模式、上移/下移、隐藏/恢复、战争模式切换、滚到底后管理按钮可点。
#
# 产出：artifacts/ui-tests.log（xcodebuild 输出）
#       artifacts/YUIUITests.xcresult（测试结果 + 截图附件）
#       artifacts/ui-test-attachments/（尽力导出的截图附件）

set -euo pipefail

RESULT_BUNDLE="artifacts/YUIUITests.xcresult"
LOG="artifacts/ui-tests.log"

mkdir -p artifacts
rm -rf "$RESULT_BUNDLE"

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
  echo "no available iPhone simulator"
  exit 1
fi

echo "ui-test device: ${UDID}"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b

set -o pipefail
xcodebuild test \
  -project YUI.xcodeproj \
  -scheme YUI \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath build \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO \
  | tee "$LOG"

if [ -d "$RESULT_BUNDLE" ]; then
  xcrun xcresulttool export attachments \
    --path "$RESULT_BUNDLE" \
    --output-path artifacts/ui-test-attachments \
    || echo "attachment export unavailable; screenshots stay inside the xcresult bundle"
fi
