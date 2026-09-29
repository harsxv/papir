#!/bin/zsh
set -euo pipefail

root=${0:A:h:h}
output="$root/dist"
derived="$output/DerivedData"
app="$derived/Build/Products/Release/Papir.app"
archive="$output/Papir-macOS-arm64.zip"

mkdir -p "$output"

if [[ -n ${NOTARY_PROFILE:-} && -z ${DEVELOPER_ID_APPLICATION:-} ]]; then
  print -u2 "NOTARY_PROFILE requires DEVELOPER_ID_APPLICATION."
  exit 1
fi

xcodebuild build \
  -quiet \
  -project "$root/Papir.xcodeproj" \
  -scheme Papir \
  -configuration Release \
  -destination "platform=macOS,arch=arm64" \
  -derivedDataPath "$derived" \
  CODE_SIGNING_ALLOWED=NO

if [[ -n ${DEVELOPER_ID_APPLICATION:-} ]]; then
  codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$app"
fi

ditto -c -k --keepParent "$app" "$archive"

if [[ -n ${NOTARY_PROFILE:-} ]]; then
  xcrun notarytool submit "$archive" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$app"
  ditto -c -k --keepParent "$app" "$archive"
fi

if [[ -z ${DEVELOPER_ID_APPLICATION:-} ]]; then
  print "Created unsigned local package: $archive"
else
  print "Created signed package: $archive"
fi
