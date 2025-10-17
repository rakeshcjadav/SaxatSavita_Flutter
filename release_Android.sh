# Android
echo "🚀 Starting Android release build process..."
flutter clean
flutter build appbundle --release
echo "✅ Android App Bundle built successfully!"
echo "📦 Output located at: build/app/outputs/bundle/release/app-release.aab"
