#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/dist/CodexBar.app"
mkdir -p "$APP/Contents/MacOS" .build/module-cache
for ARCH in arm64 x86_64; do
  swiftc -O -target "$ARCH-apple-macosx13.0" -module-cache-path "$PWD/.build/module-cache" Sources/main.swift Sources/Localization.swift -o ".build/CodexBar-$ARCH" -framework AppKit
  swiftc -O -parse-as-library -target "$ARCH-apple-macosx13.0" -module-cache-path "$PWD/.build/module-cache" Sources/UsageReader.swift Sources/Localization.swift -o ".build/UsageReader-$ARCH"
done
lipo -create .build/CodexBar-arm64 .build/CodexBar-x86_64 -output "$APP/Contents/MacOS/CodexBar"
lipo -create .build/UsageReader-arm64 .build/UsageReader-x86_64 -output "$APP/Contents/MacOS/UsageReader"
mkdir -p "$APP/Contents/Resources"
cp -R Resources/en.lproj Resources/zh-Hans.lproj "$APP/Contents/Resources/"
# Remove the legacy Python helper from builds produced by earlier versions.
if [ -f "$APP/Contents/Resources/usage.py" ]; then
  unlink "$APP/Contents/Resources/usage.py"
fi
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>CodexBar</string>
<key>CFBundleIdentifier</key><string>io.github.dragonwong.codexbar</string>
<key>CFBundleName</key><string>CodexBar</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundleShortVersionString</key><string>0.1.1</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string></array>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP/Contents/MacOS/UsageReader"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"
echo "$APP"
