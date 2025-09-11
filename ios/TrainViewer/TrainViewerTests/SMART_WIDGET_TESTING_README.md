# Smart Widget Testing Guide

## Overview

This testing suite provides comprehensive tools for testing the TrainViewer widget's smart switching functionality based on location and time. The tests simulate real-world scenarios without requiring actual GPS movement or waiting for different times of day.

## 🧪 Testing Components

### 1. Interactive Test File
**File**: `SmartWidgetInteractiveTests.swift`

Contains detailed test methods that simulate various scenarios and provide console output showing expected vs actual behavior.

### 2. Test Runner Script
**File**: `run_smart_widget_tests.sh`

Command-line script to run test suites and view results.

### 3. Test Configuration
**File**: `TestScenarios.json`

JSON configuration file containing all test scenarios, locations, and expected behaviors.

## 🚀 Quick Start

### Method 1: Xcode Testing
1. Open `SmartWidgetInteractiveTests.swift` in Xcode
2. Run individual test methods using `Cmd+U`
3. View detailed console output for each scenario

### Method 2: Command Line Testing
```bash
cd ios/TrainViewer/TrainViewerTests
./run_smart_widget_tests.sh test
```

### Method 3: View Available Scenarios
```bash
./run_smart_widget_tests.sh scenarios
```

## 📍 Location-Based Test Scenarios

### Primary Locations
| Location | Coordinates | Expected Context | Confidence |
|----------|-------------|------------------|------------|
| **Home** | (48.1351, 11.5820) | `.atHome` | High |
| **Campus** | (48.1500, 11.5800) | `.atCampus` | High |
| **Near Home** | (48.1450, 11.5820) | `.nearHome` | Medium |
| **Near Campus** | (48.1400, 11.5800) | `.nearCampus` | Medium |
| **Unknown** | No GPS data | `.unknown` | Low |

### Detection Radii
- **Home Detection**: 300m radius around home location
- **Campus Detection**: 500m radius around campus location
- **Proximity Detection**: 1km radius for "near" contexts

## ⏰ Time-Based Test Scenarios

| Time | Expected Context | Reasoning |
|------|------------------|-----------|
| **8:00 AM** | `.atHome` | Morning commute - user planning to go to campus |
| **2:00 PM** | `.unknown` | Midday - ambiguous context |
| **6:00 PM** | `.atCampus` | Evening commute - user planning to go home |
| **Saturday 2:00 PM** | `.nearCampus` | Weekend leisure time |
| **2:00 AM** | `.unknown` | Late night - ambiguous context |

## 🚆 Route Selection Logic

### Smart Route Selection Priority

1. **Weekday Preference**: Monday-specific route on Mondays
2. **Manual Override**: User-selected preferred route
3. **Most Recent**: Route used most recently
4. **Most Used**: Route with highest usage count
5. **First Available**: Fallback to first configured route

### Route Scenarios
- **Home → Campus**: Morning commute route
- **Campus → Home**: Evening commute route
- **Weekday Override**: Special routes for specific days

## 🔧 Edge Cases Tested

### Location Edge Cases
- **Overlapping Radii**: User within both home and campus detection areas
- **Location Timeout**: GPS data older than 30 minutes
- **GPS Unavailable**: No location permissions or signal
- **Rapid Movement**: Quick transitions between locations

### Configuration Edge Cases
- **No Routes**: Widget shows setup prompt
- **Single Route**: Uses available route regardless of context
- **Missing Locations**: Fallback to time-based logic

## 📊 Test Output Examples

### Successful Location Test
```
🧪 Testing Smart Switching: At Home Location
📍 Location: München Home (48.1351, 11.5820)
🎯 Expected: .atHome (within home detection radius)
📊 Actual: atHome
🎚️ Confidence: high
🚆 Smart Route Selected: Home - München → Campus - TU München
✅ Route: Home - München → Campus - TU München
🏠 Origin matches home: true
🏫 Destination matches campus: true
```

### Time-Based Fallback Test
```
🧪 Testing Smart Switching: Unknown Location (No GPS)
📍 Location: No location data available
🎯 Expected: .unknown (fallback to time-based logic)
📊 Actual: unknown
🎚️ Confidence: low
🚆 Smart Route Selected: Most recently used route
```

## 🛠️ Customizing Test Scenarios

### Modifying Locations
Edit `TestScenarios.json` to change test coordinates:

```json
"locations": {
  "home": {
    "name": "Your City Home",
    "latitude": 48.1351,
    "longitude": 11.5820
  }
}
```

### Adjusting Detection Radii
```json
"configuration": {
  "detectionRadii": {
    "homeRadius": 500,    // Increase for larger home area
    "campusRadius": 800,  // Increase for larger campus area
    "proximityRadius": 1500 // Increase for larger proximity detection
  }
}
```

### Adding New Test Scenarios
1. Add new location/time scenario to `TestScenarios.json`
2. Create corresponding test method in `SmartWidgetInteractiveTests.swift`
3. Update the test runner script if needed

## 🔍 Manual Testing in Simulator

### Setup Steps
1. **Build and Run App**
   ```bash
   cd ios/TrainViewer
   xcodebuild -scheme TrainViewer -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Configure Smart Widget**
   - Open app and go to Settings
   - Navigate to "Smart Widget Setup"
   - Set home location (e.g., "München Hauptbahnhof")
   - Set campus location (e.g., "TU München")
   - Add routes between locations

3. **Add Widget to Home Screen**
   - Long press on home screen
   - Tap "+" to add widget
   - Search for "TrainViewer"
   - Select the smart widget

### Testing Location Changes
Since the simulator doesn't have real GPS, you can:
1. Use the mock location data from tests
2. Test time-based switching by changing device time
3. Verify widget updates when routes are added/modified

## 📈 Performance Testing

### Location Update Frequency
- **Expected**: Widget updates every 5-10 minutes
- **Test**: Monitor widget refresh frequency in console logs

### Context Switching Delay
- **Expected**: < 30 seconds after location change
- **Test**: Time from location update to widget refresh

### Route Calculation Time
- **Expected**: < 100ms for route selection
- **Test**: Measure time in `findSmartRoute()` method

## 🐛 Debugging Tips

### Common Issues
1. **Widget not updating**: Check if smart switching is enabled in settings
2. **Wrong route selected**: Verify location coordinates and detection radii
3. **Time-based fallback not working**: Ensure time-based fallback is enabled

### Debug Logging
Add these to see detailed information:
```swift
print("📍 Current Location: \(currentLocation)")
print("🎯 Determined Context: \(context)")
print("🚆 Selected Route: \(smartRoute?.name ?? "None")")
```

### Xcode Debug Workflow
1. Set breakpoint in `determineLocationContext()`
2. Run widget in debug mode
3. Step through location determination logic
4. Inspect variables at each step

## 📋 Checklist Before Real-World Testing

- [ ] All unit tests pass
- [ ] Location permissions handled correctly
- [ ] Widget updates within expected timeframes
- [ ] Time-based fallback works when GPS unavailable
- [ ] Edge cases handled gracefully
- [ ] Performance requirements met
- [ ] User settings persist correctly

## 🎯 Next Steps

1. **Run all tests** using the provided test suite
2. **Customize scenarios** for your specific use case
3. **Add new test cases** for additional edge cases
4. **Test in simulator** with manual configuration
5. **Deploy to device** for real-world GPS testing

---

## 💡 Pro Tips

- **Start with basics**: Test simple location scenarios before complex edge cases
- **Use real coordinates**: Replace mock coordinates with actual locations you use
- **Test during commute**: Verify switching works during actual travel
- **Monitor battery impact**: GPS usage should be optimized for battery life
- **Test offline scenarios**: Ensure app works when network is unavailable

Happy testing! 🚀
