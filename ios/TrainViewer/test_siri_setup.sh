#!/bin/bash

echo "🚀 TrainViewer Siri Integration Test"
echo "===================================="

# Check if extension files exist
echo ""
echo "📁 Checking extension files..."
if [ -f "AppIntentsExtension/TrainViewerAppIntentsExtension.swift" ]; then
    echo "✅ Extension main file exists"
else
    echo "❌ Extension main file missing"
fi

if [ -f "AppIntentsExtension/QuickActionsIntents.swift" ]; then
    echo "✅ Intents file exists"
else
    echo "❌ Intents file missing"
fi

if [ -f "AppIntentsExtension/Info.plist" ]; then
    echo "✅ Extension Info.plist exists"
else
    echo "❌ Extension Info.plist missing"
fi

# Check main app configuration
echo ""
echo "📱 Checking main app configuration..."
if grep -q "NSSiriUsageDescription" "Support/TrainViewer-Info.plist"; then
    echo "✅ Siri usage description configured"
else
    echo "❌ Siri usage description missing"
fi

if grep -q "group.com.bahnblitz.app" "TrainViewer.entitlements"; then
    echo "✅ App Group entitlement configured"
else
    echo "❌ App Group entitlement missing"
fi

# Check extension entitlements
echo ""
echo "🔧 Checking extension entitlements..."
if [ -f "AppIntentsExtension/TrainViewerAppIntentsExtension.entitlements" ]; then
    if grep -q "group.com.bahnblitz.app" "AppIntentsExtension/TrainViewerAppIntentsExtension.entitlements"; then
        echo "✅ Extension App Group entitlement configured"
    else
        echo "❌ Extension App Group entitlement missing"
    fi
else
    echo "❌ Extension entitlements file missing"
fi

echo ""
echo "📋 Next Steps:"
echo "1. In Xcode, add the shared files to your extension target"
echo "2. Build and run the app on a physical device"
echo "3. Test with: 'Hey Siri, debug Siri'"
echo "4. Check the SIRI_INTEGRATION_GUIDE.md for detailed instructions"

echo ""
echo "🎯 Test Commands:"
echo "• 'Hey Siri, debug Siri' - Test extension setup"
echo "• 'Hey Siri, when's my train' - Test widget route"
echo "• 'Hey Siri, when is my train home' - Test home route"
echo "• 'Hey Siri, when is my train to campus' - Test campus route"

echo ""
echo "✨ Good luck! Your Siri integration should be working now."

