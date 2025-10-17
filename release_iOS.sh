# iOS
echo "🚀 Starting iOS release build process..."
flutter clean
flutter build ipa --release
echo "✅ iOS App Bundle built successfully!"
echo "📦 Output located at: build/ios/ipa"
