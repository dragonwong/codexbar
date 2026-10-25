#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build.sh
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' dist/CodexBar.app/Contents/Info.plist)
ARCHIVE="CodexBar-$VERSION-universal.zip"
ditto -c -k --sequesterRsrc --keepParent dist/CodexBar.app "dist/$ARCHIVE"
(cd dist && shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")
echo "dist/$ARCHIVE"
