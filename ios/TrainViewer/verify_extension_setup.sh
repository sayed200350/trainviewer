#!/bin/bash

echo "🔧 Verifying TrainViewer AppIntents Extension Setup"
echo "=================================================="

# Check extension files
echo ""
echo "📁 Extension Files:"
files=(
    "AppIntentsExtension/TrainViewerAppIntentsExtension.swift"
    "AppIntentsExtension/SiriIntents.swift"
    "AppIntentsExtension/AppShortcutsProvider.swift"
    "AppIntentsExtension/Info.plist"
    "AppIntentsExtension/TrainViewerAppIntentsExtension.entitlements"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
    fi
done

# Check required shared files
echo ""
echo "🔗 Required Shared Files (must be added to extension target):"
shared_files=(
    "Shared/SharedStore.swift"
    "Shared/SharedModels.swift"
    "Shared/Constants.swift"
    "Shared/UserSettingsStore.swift"
    "Models/Place.swift"
    "Models/JourneyOption.swift"
    "Models/JourneyDecoding.swift"
    "Models/Route.swift"
    "Services/TransportAPIFactory.swift"
    "Services/TransportAPI.swift"
    "Services/JourneyServiceProtocol.swift"
    "Services/AutoTransportAPI.swift"
    "Services/DBTransportAPI.swift"
    "Services/APIClient.swift"
    "Services/EnhancedErrorHandling.swift"
)

for file in "${shared_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
    fi
done

# Check main app configuration
echo ""
echo "📱 Main App Configuration:"
if grep -q "NSSiriUsageDescription" "Support/TrainViewer-Info.plist" 2>/dev/null; then
    echo "✅ Siri usage description configured"
else
    echo "❌ Siri usage description missing"
fi

if grep -q "group.com.bahnblitz.app" "TrainViewer.entitlements" 2>/dev/null; then
    echo "✅ App Group entitlement configured"
else
    echo "❌ App Group entitlement missing"
fi

echo ""
echo "🎯 Next Steps in Xcode:"
echo "1. Select 'TrainViewerAppIntentsExtension' target"
echo "2. Go to Build Phases → Compile Sources"
echo "3. Click '+' and add ALL the files marked with ✅ above"
echo "4. Build the extension target"
echo "5. Test with: 'Hey Siri, debug Siri'"

echo ""
echo "🚨 Common Issues:"
echo "• If you get 'Cannot find SharedStore', add Shared/SharedStore.swift"
echo "• If you get 'Cannot find Place', add Models/Place.swift"
echo "• If you get 'Cannot find TransportAPIFactory', add Services/TransportAPIFactory.swift"
echo "• If extension won't build, clean build folder (Cmd+Shift+K)"

echo ""
echo "✨ Success Indicators:"
echo "• Extension builds without errors"
echo "• 'Hey Siri, debug Siri' responds with setup info"
echo "• Other Siri commands return train information"

