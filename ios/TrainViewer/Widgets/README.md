# TrainViewer Widgets

This directory contains the widget implementation for TrainViewer, providing users with quick access to departure information directly from their home screen.

## Widget Types

### 1. Quick Departure Widget (`TrainViewerWidget`)
- **Type**: Static Configuration
- **Purpose**: Shows departure information for the most recently used route
- **Sizes**: Small, Medium
- **Configuration**: Automatic (uses most recent route)

### 2. Route Departure Widget (`TrainViewerRouteWidget`) 
- **Type**: App Intent Configuration
- **Purpose**: Shows departure information for a user-selected route
- **Sizes**: Small, Medium
- **Configuration**: User selects specific route and refresh interval

## Architecture

### Widget Bundle
- `TrainViewerWidgetBundle.swift`: Main entry point that registers both widget types
- Uses `@main` attribute to ensure proper widget discovery

### Configuration Management
- `WidgetConfigurationManager.swift`: Handles widget configuration persistence and validation
- `WidgetConfigurationService.swift`: Manages widget lifecycle and data synchronization
- Configurations stored in App Group shared container for cross-target access

### Error Handling
- Comprehensive error states for missing routes, configuration issues, and network problems
- Automatic configuration recovery when routes are deleted or become unavailable
- User-friendly error messages with actionable recovery suggestions

## Key Features

### Enhanced Configuration
- **Route Selection**: Users can select any available route for their widget
- **Refresh Intervals**: Configurable update frequency (1, 2, 5, 10, 15 minutes)
- **Compact Mode**: Optional minimal display for space-constrained layouts
- **Favorites Priority**: Favorite routes are highlighted in selection interface

### Robust Error Handling
- **Route Validation**: Ensures selected routes still exist
- **Configuration Recovery**: Automatically recovers from invalid configurations
- **Network Resilience**: Graceful handling of API failures with cached data
- **User Feedback**: Clear error messages with specific recovery instructions

### Performance Optimization
- **Intelligent Caching**: Respects user-configured refresh intervals
- **Memory Management**: Efficient handling of widget timeline updates
- **Battery Awareness**: Configurable refresh rates to balance freshness with battery life
- **Background Efficiency**: Minimal resource usage during background updates

## Widget States

### 1. Placeholder State
- Shown when no routes are configured in the main app
- Provides clear instructions for setup
- Includes app branding and call-to-action

### 2. Configured State
- Shows actual departure information
- Color-coded urgency indicators (red for "leave now", orange for urgent)
- Relative time updates and departure/arrival times
- Last update timestamp for data freshness awareness

### 3. Error State
- Displays when configuration is invalid or route is unavailable
- Shows specific error message and recovery instructions
- Maintains route name for context
- Provides tap-to-reconfigure functionality

## Configuration Persistence

### Storage Location
- Uses App Group container (`group.com.trainviewer`) for shared access
- Configurations stored as JSON in UserDefaults
- Automatic migration for configuration format changes

### Data Structure
```swift
struct WidgetConfiguration {
    let widgetId: String
    let routeId: UUID?
    let routeName: String
    let refreshInterval: TimeInterval
    let showFavoritesOnly: Bool
    let compactMode: Bool
    let createdAt: Date
    let updatedAt: Date
}
```

### Validation Rules
- Route must exist in current app data
- Refresh interval must be at least 60 seconds
- Configuration format must be valid JSON
- Widget ID must be unique per widget instance

## Integration with Main App

### Route Changes
- `WidgetConfigurationService.handleRouteChanges()`: Called when routes are modified
- `WidgetConfigurationService.handleRouteDeleted()`: Called when routes are deleted
- Automatic widget timeline refresh when underlying data changes

### App Startup
- `WidgetConfigurationService.initializeOnAppLaunch()`: Validates and migrates configurations
- Ensures widget configurations remain valid across app updates
- Recovers from corrupted or invalid configurations

## Testing

### Unit Tests
- `WidgetConfigurationTests.swift`: Comprehensive test suite for configuration management
- Tests persistence, validation, recovery, and error handling
- Performance tests for configuration operations
- Error message and recovery suggestion validation

### Test Coverage
- Configuration save/load operations
- Validation logic for various error conditions
- Recovery mechanisms for invalid configurations
- Performance under load with multiple configurations

## Troubleshooting

### Widget Not Appearing in Gallery
1. Verify `TrainViewerWidgetBundle.swift` has `@main` attribute
2. Check Info.plist has correct `NSExtensionPointIdentifier`
3. Ensure widget target is properly configured in Xcode project
4. Clean build and reinstall app

### Configuration Not Persisting
1. Verify App Group entitlements are correctly configured
2. Check UserDefaults suite name matches App Group identifier
3. Ensure proper JSON encoding/decoding of configuration data
4. Validate write permissions to shared container

### Widget Showing Errors
1. Check if routes exist in main app
2. Verify network connectivity for data updates
3. Review widget configuration for invalid settings
4. Use widget configuration recovery mechanism

### Performance Issues
1. Adjust refresh intervals to reduce update frequency
2. Enable compact mode to reduce rendering complexity
3. Check for memory leaks in widget timeline provider
4. Monitor background app refresh usage

## Future Enhancements

### Planned Features
- Large widget size support for multiple routes
- Live Activities integration for real-time updates
- Interactive widget elements (iOS 17+)
- Siri integration for voice-activated updates

### Performance Improvements
- Predictive caching based on usage patterns
- Adaptive refresh intervals based on departure proximity
- Background processing optimization
- Memory usage reduction techniques

## Dependencies

### System Frameworks
- `WidgetKit`: Core widget functionality
- `SwiftUI`: Widget UI implementation
- `AppIntents`: Configuration interface

### Internal Dependencies
- `SharedStore`: Route data access
- `CoreDataStack`: Data persistence
- `Constants`: Shared configuration values
- `UserSettingsStore`: User preference access