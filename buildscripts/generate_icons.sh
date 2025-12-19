#!/bin/bash

# Navigate to project root
cd "$(dirname "$0")/.."

# App Icon Generation Script for Sakshaat Savita
# This script helps process and generate app icons from your spiritual guru image

echo "🙏 Sakshaat Savita App Icon Generator"
echo "=================================""

# Check if the source image exists (support PNG, JPG, WEBP)
if [ ! -f "assets/icon/source_image.png" ] && [ ! -f "assets/icon/source_image.jpg" ] && [ ! -f "assets/icon/source_image.webp" ]; then
    echo "❌ Source image not found!"
    echo "📁 Please save your spiritual guru image as:"
    echo "   - assets/icon/source_image.png (preferred)"
    echo "   - assets/icon/source_image.jpg (alternative)"
    echo "   - assets/icon/source_image.webp (modern format)"
    echo ""
    echo "💡 Image requirements:"
    echo "   - Minimum size: 1024x1024 pixels"
    echo "   - Square format (1:1 aspect ratio)"
    echo "   - PNG format preferred for transparency"
    echo "   - WebP format supported for modern efficiency"
    echo "   - High quality for best results"
    exit 1
fi

# Determine source file (check PNG, JPG, WebP)
SOURCE_FILE=""
if [ -f "assets/icon/source_image.png" ]; then
    SOURCE_FILE="assets/icon/source_image.png"
elif [ -f "assets/icon/source_image.jpg" ]; then
    SOURCE_FILE="assets/icon/source_image.jpg"
elif [ -f "assets/icon/source_image.webp" ]; then
    SOURCE_FILE="assets/icon/source_image.webp"
fi

echo "✅ Found source image: $SOURCE_FILE"

# Check available image processing tools
if command -v convert &> /dev/null; then
    echo "✅ ImageMagick detected - using advanced processing"
    
    # Create main app icon (1024x1024)
    echo "📱 Generating main app icon..."
    convert "$SOURCE_FILE" -resize 1024x1024 -quality 95 "assets/icon/app_icon.png"
    
    # Create foreground icon for adaptive icon (Android)
    echo "🤖 Generating Android adaptive icon foreground..."
    # Add some padding for adaptive icon (safe area)
    convert "$SOURCE_FILE" -resize 864x864 -gravity center -background transparent -extent 1024x1024 "assets/icon/app_icon_foreground.png"
    
    echo "✅ Icons generated successfully with ImageMagick!"
    
elif command -v sips &> /dev/null; then
    echo "✅ macOS sips detected - using native image processing"
    
    # Create main app icon (1024x1024)
    echo "� Generating main app icon..."
    sips -z 1024 1024 "$SOURCE_FILE" --out "assets/icon/app_icon.png" > /dev/null 2>&1
    
    # Create foreground icon for adaptive icon (Android)
    echo "🤖 Generating Android adaptive icon foreground..."
    # For adaptive icon, resize to 864x864 and then pad to 1024x1024
    sips -z 864 864 "$SOURCE_FILE" --out "assets/icon/temp_foreground.png" > /dev/null 2>&1
    # Use sips to pad the image (center it in a 1024x1024 canvas)
    sips -p 1024 1024 "assets/icon/temp_foreground.png" --out "assets/icon/app_icon_foreground.png" > /dev/null 2>&1
    # Clean up temp file
    rm -f "assets/icon/temp_foreground.png"
    
    echo "✅ Icons generated successfully with macOS sips!"
    
else
    echo "⚠️  No image processing tools found"
    
    # Handle WebP files
    if [[ "$SOURCE_FILE" == *.webp ]]; then
        echo "❌ WebP format detected but no conversion tools available"
        echo "📥 Please install ImageMagick: brew install imagemagick"
        echo "🔄 Or convert your WebP image to PNG format manually"
        exit 1
    else
        echo "💡 Install ImageMagick for better processing: brew install imagemagick"
        
        # Simple copy (you may need to manually resize)
        cp "$SOURCE_FILE" "assets/icon/app_icon.png"
        cp "$SOURCE_FILE" "assets/icon/app_icon_foreground.png"
        
        echo "📝 Note: You may need to manually resize images to 1024x1024"
    fi
fi

echo ""
echo "🎯 Next steps:"
echo "1. Run: flutter pub get"
echo "2. Run: dart run flutter_launcher_icons"
echo "3. Test your app to see the new icons!"
echo ""
echo "📱 Icon files created:"
echo "   - assets/icon/app_icon.png (main icon)"
echo "   - assets/icon/app_icon_foreground.png (Android adaptive)"

# Create a simple preview HTML file
cat > assets/icon/preview.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Sakshaat Savita App Icons Preview</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            padding: 20px; 
            background: linear-gradient(135deg, #fff8e1, #ffecb3); 
            min-height: 100vh;
            margin: 0;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: rgba(255, 255, 255, 0.95); 
            padding: 30px; 
            border-radius: 20px; 
            box-shadow: 0 10px 30px rgba(255, 87, 34, 0.1), 0 1px 8px rgba(0, 0, 0, 0.05);
            backdrop-filter: blur(10px);
        }
        .icon-preview { display: inline-block; margin: 20px; text-align: center; }
        .icon-preview img { 
            width: 120px; 
            height: 120px; 
            border-radius: 20px; 
            box-shadow: 0 8px 25px rgba(255, 87, 34, 0.3), 0 3px 10px rgba(0, 0, 0, 0.1); 
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .icon-preview img:hover { 
            transform: translateY(-3px); 
            box-shadow: 0 12px 35px rgba(255, 87, 34, 0.4), 0 5px 15px rgba(0, 0, 0, 0.15); 
        }
        .icon-preview h3 { margin: 10px 0 5px 0; color: #FF5722; }
        .adaptive-preview { 
            background: linear-gradient(135deg, #FF5722, #FF8A50, #FFAB40); 
            padding: 15px; 
            border-radius: 50%; 
            box-shadow: 0 6px 20px rgba(255, 87, 34, 0.25), inset 0 2px 4px rgba(255, 255, 255, 0.2);
            transition: transform 0.3s ease;
        }
        .adaptive-preview:hover { 
            transform: scale(1.05); 
        }
        .adaptive-preview img { 
            box-shadow: none !important; 
            border-radius: 15px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🙏 Sakshaat Savita App Icons</h1>
        <p>Preview of your generated app icons:</p>
        
        <div class="icon-preview">
            <img src="app_icon.png" alt="Main App Icon">
            <h3>Main Icon</h3>
            <p>iOS & Android standard</p>
        </div>
        
        <div class="icon-preview">
            <div class="adaptive-preview">
                <img src="app_icon_foreground.png" alt="Adaptive Foreground">
            </div>
            <h3>Android Adaptive</h3>
            <p>Foreground + Background</p>
        </div>
        
        <h2>✨ Features</h2>
        <ul>
            <li>High quality 1024x1024 resolution</li>
            <li>Optimized for iOS and Android</li>
            <li>Android Adaptive Icon support</li>
            <li>Spiritual theme with golden background</li>
        </ul>
    </div>
</body>
</html>
EOF

echo "🌐 Created preview file: assets/icon/preview.html"
echo "   Open this file in a browser to preview your icons"