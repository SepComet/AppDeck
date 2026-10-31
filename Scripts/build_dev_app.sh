#!/bin/bash
set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_path="${APPDECK_SDK_PATH:-$(xcrun --sdk macosx --show-sdk-path)}"
build_root="$workspace_root/build"
app_bundle="$build_root/AppDeck.app"
executable_path="$app_bundle/Contents/MacOS/AppDeck"

rm -rf "$app_bundle"
mkdir -p "$(dirname "$executable_path")" "$app_bundle/Contents/Resources"
source_files=()
while IFS= read -r source_file; do
    source_files+=("$source_file")
done < <(find "$workspace_root/AppDeck" -name '*.swift' -print | sort)

swiftc \
    -emit-executable \
    -module-name AppDeck \
    -target arm64-apple-macosx14.0 \
    -sdk "$sdk_path" \
    "${source_files[@]}" \
    -o "$executable_path"

cp "$workspace_root/AppDeck/Resources/Info.plist" "$app_bundle/Contents/Info.plist"
cp "$workspace_root/AppDeck/Resources/AppIcon.icns" "$app_bundle/Contents/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable AppDeck" "$app_bundle/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.wmx.AppDeck" "$app_bundle/Contents/Info.plist"
signing_identity="${APPDECK_CODESIGN_IDENTITY:-AppDeck Local Development}"
if security find-certificate -a -c "$signing_identity" "$HOME/Library/Keychains/login.keychain-db" >/dev/null 2>&1; then
    /usr/bin/codesign --force --deep --sign "$signing_identity" "$app_bundle" >/dev/null
else
    /usr/bin/codesign --force --deep --sign - "$app_bundle" >/dev/null
fi

echo "$app_bundle"
