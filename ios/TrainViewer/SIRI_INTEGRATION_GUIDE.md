# Siri Shortcuts Integration Guide

## 🎯 Overview
Your TrainViewer app now has complete Siri Shortcuts integration that works even when the app is closed or locked.

## 📋 What You Need to Do in Xcode

### Step 1: Add Shared Files to Extension Target
1. In Xcode, select your project in the navigator
2. Select the **TrainViewerAppIntentsExtension** target
3. Go to **Build Phases** tab
4. Under **Compile Sources**, add these files:
   - `Shared/SharedStore.swift`
   - `Shared/SharedModels.swift`
   - `Shared/Constants.swift`
   - `Models/Place.swift`
   - `Models/JourneyOption.swift`
   - `Models/JourneyDecoding.swift`
   - `Services/TransportAPIFactory.swift`
   - `Services/TransportAPI.swift`
   - `Services/JourneyServiceProtocol.swift`

### Step 2: Verify App Group Entitlements
Make sure both targets have the same App Group:
- **Main App Target**: `group.com.bahnblitz.app`
- **Extension Target**: `group.com.bahnblitz.app`

### Step 3: Test the Integration

#### Build and Test Extension
```bash
# Clean and build the extension
xcodebuild clean build -project TrainViewer.xcodeproj -target TrainViewerAppIntentsExtension
```

#### Test Siri Commands
After building, try these Siri commands:

1. **"Hey Siri, debug Siri"**
   - Should respond with debug information about your setup

2. **"Hey Siri, when's my train"**
   - Should check your widget route and give departure time

3. **"Hey Siri, when is my train home"**
   - Should find next train to your home location

4. **"Hey Siri, when is my train to campus"**
   - Should find next train to your campus location

5. **"Hey Siri, next train"**
   - Should find next train from any of your saved routes

## 🔧 Siri Setup Checklist

### Required Setup Steps:
- [ ] Extension target created in Xcode
- [ ] Shared files added to extension target
- [ ] App Group entitlements configured
- [ ] NSSiriUsageDescription added to main app Info.plist
- [ ] Extension Info.plist configured with correct intents
- [ ] App built and installed on device

### User Setup Steps:
- [ ] Open Settings > Siri & Search
- [ ] Find TrainViewer app
- [ ] Enable "Use with Ask Siri"
- [ ] Grant microphone permission if prompted

## 🎤 Available Siri Commands

| Command | Description | Example Response |
|---------|-------------|------------------|
| "Debug Siri" | Test extension setup | "Debug info: Location available, 3 routes saved..." |
| "When's my train" | Check widget route | "Your train departs in 15 minutes at 14:30" |
| "When is my train home" | Next train home | "Your train home departs in 8 minutes" |
| "When is my train to campus" | Next train to campus | "Your train to campus departs in 22 minutes" |
| "Next train" | Any saved route | "Your next train to Berlin departs in 12 minutes" |

## 🚨 Troubleshooting

### Common Issues:

#### 1. Siri Says "I don't understand"
- Make sure extension is included in build
- Check that shared files are added to extension target
- Verify App Group entitlements match

#### 2. "Cannot access shared data"
- Check App Group identifier in both targets
- Make sure entitlements files are properly configured
- Test with "Hey Siri, debug Siri" to see what's accessible

#### 3. Extension Won't Build
- Add missing imports to extension target
- Check for missing framework dependencies
- Clean build folder and rebuild

#### 4. Siri Commands Not Appearing
- Go to Settings > Siri & Search
- Find TrainViewer and enable Siri
- Try restarting your device

## 🔍 Debug Commands

Use these commands to troubleshoot:

1. **"Hey Siri, debug Siri"** - Shows extension status
2. Check device logs in Xcode for extension errors
3. Test extension directly in Xcode using the extension scheme

## 📱 Device Testing

For best results:
1. Build and install on physical device (not simulator)
2. Make sure Siri is enabled and trained to your voice
3. Test with device locked to ensure background execution works
4. Try different network conditions

## 🎉 Success Indicators

Your Siri integration is working when:
- ✅ "Hey Siri, debug Siri" responds with setup information
- ✅ Train times are returned even with app closed
- ✅ Commands work when device is locked
- ✅ Location and route data is accessible to extension
- ✅ No crashes or errors in device logs

## 📞 Support

If you encounter issues:
1. Run "Hey Siri, debug Siri" and note the response
2. Check Xcode console for extension errors
3. Verify all shared files are added to extension target
4. Test with different Siri commands to isolate the issue

