#!/bin/zsh
set -euo pipefail

root=${0:A:h:h}
output="$root/dist"
derived="$output/DerivedData"
app="$derived/Build/Products/Release/Papir.app"
archive="$output/Papir-macOS-arm64.zip"
version=${VERSION:-local}
dmg="$output/Papir-$version-macOS-arm64.dmg"
staging=$(mktemp -d "${TMPDIR:-/tmp}/papir-dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT

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
  codesign --force --options runtime --timestamp \
    --entitlements "$root/Papir/Papir.entitlements" \
    --sign "$DEVELOPER_ID_APPLICATION" "$app"
else
  codesign --force --options runtime \
    --entitlements "$root/Papir/Papir.entitlements" \
    --sign - "$app"
fi

ditto -c -k --keepParent "$app" "$archive"
ditto "$app" "$staging/Papir.app"
ln -s /Applications "$staging/Applications"
hdiutil create -quiet -volname Papir -srcfolder "$staging" -ov -format UDZO "$dmg"

if [[ -n ${DEVELOPER_ID_APPLICATION:-} ]]; then
  codesign --force --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$dmg"
else
  codesign --force --sign - "$dmg"
fi

if [[ -n ${NOTARY_PROFILE:-} ]]; then
  xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$dmg"
fi

if [[ -z ${DEVELOPER_ID_APPLICATION:-} ]]; then
  print "Created unsigned local packages: $archive and $dmg"
else
  print "Created signed packages: $archive and $dmg"
fi
