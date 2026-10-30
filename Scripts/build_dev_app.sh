#!/bin/bash
set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_path="${APPDECK_SDK_PATH:-$(xcrun --sdk macosx --show-sdk-path)}"
build_root="$workspace_root/build"
app_bundle="$build_root/AppDeck.app"
executable_path="$app_bundle/Contents/MacOS/AppDeck"

rm -rf "$app_bundle"
mkdir -p "$(dirname "$executable_path")"
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
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable AppDeck" "$app_bundle/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.wmx.AppDeck" "$app_bundle/Contents/Info.plist"
/usr/bin/codesign --force --deep --sign - "$app_bundle" >/dev/null

echo "$app_bundle"
