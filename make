#!/bin/zsh

# Pull the version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f1)

# Check if the version was found
if [[ -z $VERSION ]]; then
  echo "❌ Version not found in pubspec.yaml!"
  exit 1
fi

echo "✅ Found version: $VERSION"

# Build the IPA
echo "📱 Building iOS (IPA)..."
flutter build ipa --release || { echo "❌ Failed to build IPA"; exit 1; }

# Build the APK
echo "📱 Building Android (APK)..."
flutter build apk --release || { echo "❌ Failed to build APK"; exit 1; }

# Build the macOS app
echo "🖥️ Building macOS..."
flutter build macos --release || { echo "❌ Failed to build macOS"; exit 1; }

# Define output directories
BUILD_DIR="build/distribution"
mkdir -p "$BUILD_DIR"

# Move and rename the IPA
IPA_PATH="build/ios/ipa/nt_helper.ipa"
if [[ -f $IPA_PATH ]]; then
  mv "$IPA_PATH" "$BUILD_DIR/nt_helper-$VERSION.ipa"
  echo "📦 IPA saved as nt_helper-$VERSION.ipa"
else
  echo "❌ IPA file not found!"
fi

# Move and rename the APK
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [[ -f $APK_PATH ]]; then
  mv "$APK_PATH" "$BUILD_DIR/nt_helper-$VERSION.apk"
  echo "📦 APK saved as nt_helper-$VERSION.apk"
else
  echo "❌ APK file not found!"
fi

# Move and rename the macOS app
MACOS_PATH="build/macos/Build/Products/Release/nt_helper.app"
if [[ -d $MACOS_PATH ]]; then
  ZIP_PATH="$BUILD_DIR/nt_helper-$VERSION-macos.zip"
  echo "📦 Zipping macOS app..."
  zip -r "$ZIP_PATH" "$MACOS_PATH" || { echo "❌ Failed to zip macOS app"; exit 1; }
  echo "📦 macOS app saved as nt_helper-$VERSION-macos.zip"
else
  echo "❌ macOS app not found!"
fi

echo "✅ Build process complete! Files are in the $BUILD_DIR directory."

echo "📱 Signing Android (APK)..."
java -jar ~/Downloads/uber-apk-signer-1.3.0.jar -a "$BUILD_DIR/nt_helper-$VERSION.apk" --allowResign
echo "✅ Android signing process complete!"


