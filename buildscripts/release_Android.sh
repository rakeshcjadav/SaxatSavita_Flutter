#!/bin/bash

# Navigate to project root
cd "$(dirname "$0")/.."

# Build the release app bundle
echo "Building release app bundle..."
flutter clean
flutter build appbundle --release

# Extract version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | cut -d ' ' -f 2)
VERSION_NAME=$(echo $VERSION | cut -d '+' -f 1)
VERSION_CODE=$(echo $VERSION | cut -d '+' -f 2)

# Create releases directory if it doesn't exist
mkdir -p releases

# Copy the app bundle with version info
SOURCE_FILE="build/app/outputs/bundle/release/app-release.aab"
DEST_FILE="releases/saxatsavita-v${VERSION_NAME}-${VERSION_CODE}.aab"

if [ -f "$SOURCE_FILE" ]; then
    cp "$SOURCE_FILE" "$DEST_FILE"
    echo "✅ App bundle copied to: $DEST_FILE"
    echo "📦 Version: $VERSION_NAME (Build: $VERSION_CODE)"
    ls -la "$DEST_FILE"
else
    echo "❌ Error: App bundle not found at $SOURCE_FILE"
    exit 1
fi