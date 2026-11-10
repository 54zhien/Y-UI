set -euo pipefail

APP_NAME="YUI"
ARCHIVE="build/YUI.xcarchive"
IPA_DIR="build/ipa"
IPA="artifacts/YUI-unsigned.ipa"

mkdir -p artifacts
rm -rf "$ARCHIVE" "$IPA_DIR"

xcodebuild archive \
  -project YUI.xcodeproj \
  -scheme YUI \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  | tee artifacts/ipa-build.log

APP_DIR="$ARCHIVE/Products/Applications/${APP_NAME}.app"

if [ ! -d "$APP_DIR" ]; then
  echo "archive did not produce ${APP_NAME}.app"
  exit 1
fi

mkdir -p "$IPA_DIR/Payload"
cp -R "$APP_DIR" "$IPA_DIR/Payload/"
(cd "$IPA_DIR" && zip -qry "../../$IPA" Payload)

unzip -l "$IPA" | tee artifacts/ipa-contents.txt

BUNDLE="$IPA_DIR/Payload/${APP_NAME}.app"

if [ ! -f "$BUNDLE/$APP_NAME" ]; then
  echo "missing executable in Payload"
  exit 1
fi

file "$BUNDLE/$APP_NAME" | tee artifacts/ipa-executable.txt

plutil -p "$BUNDLE/Info.plist" | tee artifacts/ipa-info.txt

ls -la "$BUNDLE" | tee artifacts/ipa-bundle.txt

ICON_FILES="$(ls "$BUNDLE" | grep -Ei '^(AppIcon|Assets\.car)' || true)"
echo "icon artifacts: ${ICON_FILES}"

if [ -z "$ICON_FILES" ]; then
  echo "no compiled icon artifacts in app bundle"
  exit 1
fi

if [ -f "$BUNDLE/Assets.car" ]; then
  xcrun assetutil --info "$BUNDLE/Assets.car" > artifacts/ipa-assets.json
  grep -Ei 'AppIcon|icon' artifacts/ipa-assets.json | head -40 | tee artifacts/ipa-assets-grep.txt || true
fi

du -h "$IPA" | tee artifacts/ipa-size.txt
