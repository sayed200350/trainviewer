#!/bin/bash

echo "🔍 Verifying App Icon Configuration"
echo "==================================="

echo ""
echo "📱 Info.plist Configuration:"
echo "✅ CFBundleIdentifier: $(grep -A1 "CFBundleIdentifier" "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/App/Info.plist" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')"
echo "✅ CFBundleIconName: $(grep -A1 "CFBundleIconName" "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/App/Info.plist" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')"

echo ""
echo "🎨 Asset Catalog Structure:"
echo "✅ Assets.xcassets/Contents.json exists: $(test -f "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/Assets.xcassets/Contents.json" && echo "YES" || echo "NO")"
echo "✅ AppIcon.appiconset exists: $(test -d "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/Assets.xcassets/AppIcon.appiconset" && echo "YES" || echo "NO")"

echo ""
echo "🖼️  Icon Files Present:"
icon_files=$(ls "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/Assets.xcassets/AppIcon.appiconset"/*.png 2>/dev/null | wc -l)
echo "✅ PNG files found: $icon_files"

echo ""
echo "📋 Contents.json Configuration:"
if [ -f "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo "✅ Contents.json exists"
    icon_count=$(grep -c '"filename"' "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/Assets.xcassets/AppIcon.appiconset/Contents.json")
    echo "✅ Icon entries configured: $icon_count"
else
    echo "❌ Contents.json missing"
fi

echo ""
echo "🎯 Validation Status:"
if [ "$icon_files" -gt 0 ] && [ -f "/Users/sayedmohamed/Desktop/trainviewer/ios/TrainViewer/App/Info.plist" ]; then
    echo "✅ App icon configuration appears correct"
    echo "🚀 Ready for build and submission!"
else
    echo "❌ App icon configuration may have issues"
    echo "🔧 Please check the icon files and Info.plist"
fi

echo ""
echo "📝 Next Steps:"
echo "1. Clean build folder in Xcode: Product → Clean Build Folder"
echo "2. Build the app: Product → Build"
echo "3. Test on device to verify icons display correctly"
echo "4. Submit to App Store when ready!"
