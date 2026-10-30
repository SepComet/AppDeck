#!/bin/bash
set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_path="${APPDECK_SDK_PATH:-$(xcrun --sdk macosx --show-sdk-path)}"

source_files=()
while IFS= read -r source_file; do
    source_files+=("$source_file")
done < <(find "$workspace_root/AppDeck" -name '*.swift' -print | sort)
swiftc \
    -typecheck \
    -module-name AppDeck \
    -target arm64-apple-macosx14.0 \
    -sdk "$sdk_path" \
    "${source_files[@]}"

echo "AppDeck Swift typecheck passed (arm64, macOS 14.0)."
