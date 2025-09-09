# Enhanced Error Handling System

This document describes the enhanced error handling system implemented for TrainViewer, providing comprehensive error management, automatic recovery, and user-friendly error presentation.

## Quick Start

To use the enhanced error handling system in your code:

```swift
// 1. Add enhanced error handling to your SwiftUI views
struct MyView: View {
    var body: some View {
        // Your view content
        NavigationView {
            // ...
        }
        .enhancedErrorHandling() // Adds comprehensive error handling
    }
}

// 2. Handle errors in your services
do {
    let result = try await apiClient.fetchRoutes()
} catch {
    await ErrorIntegrationService.shared.handleGenericError(error, context: .routePlanning)
}

// 3. Present specific enhanced errors
let error = EnhancedAppError.widgetConfigurationFailed(reason: "Invalid configuration")
ErrorPresentationService.shared.presentEnhancedError(error, context: .widgetConfiguration)
```

## Testing

Run the integration tests to verify the system works:

```swift
// Run basic tests
ErrorHandlingIntegrationTest.runBasicTests()

// Run comprehensive tests
ErrorHandlingIntegrationTest.runComprehensiveTests()
```

## Overview

The enhanced error handling system consists of several components working together:

1. **EnhancedAppError** - Specific error types with recovery information
2. **ErrorRecoveryService** - Automatic error recovery with retry logic
3. **ErrorPresentationService** - User-friendly error display
4. **ErrorIntegrationService** - Integration throughout the app
5. **Diagnostic System** - Comprehensive error reporting

## Components

### 1. EnhancedAppError

Defines specific error types with built-in recovery information:

```swift
enum EnhancedAppError: LocalizedError {
    case widgetConfigurationFailed(reason: String)
    case performanceOptimizationFailed
    case historyTrackingFailed(Error)
    case hapticFeedbackUnavailable
    case batchRequestFailed([String])
    case memoryPressureCritical
    case notificationSchedulingFailed(Error)
    // ... more error types
}
```

Each error includes:
- **Severity level** (low, medium, high, critical)
- **Automatic retry capability**
- **Retry delay timing**
- **User-friendly descriptions**
- **Recovery suggestions**

### 2. ErrorRecoveryService

Handles automatic error recovery with intelligent retry logic:

```swift
let errorRecoveryService = ErrorRecoveryService.shared

// Handle an error with automatic recovery
let result = await errorRecoveryService.handleError(error)

switch result {
case .recovered:
    // Error was automatically fixed
case .retryScheduled(let delay):
    // Will retry after specified delay
case .userActionRequired(let message):
    // User needs to take action
case .criticalFailure:
    // Error couldn't be recovered
case .partialRecovery(let details):
    // Some aspects were recovered
}
```

### 3. ErrorPresentationService

Provides user-friendly error presentation:

```swift
let errorService = ErrorPresentationService.shared

// Present an enhanced error
errorService.presentEnhancedError(error, context: .widgetConfiguration)

// Present a generic error
errorService.presentError(error, context: .routePlanning)
```

### 4. ErrorIntegrationService

Integrates error handling throughout the app:

```swift
let integrationService = ErrorIntegrationService.shared

// Handle API errors
await integrationService.handleAPIError(apiError, context: .routePlanning)

// Handle network errors
await integrationService.handleNetworkError(urlError, context: .backgroundRefresh)

// Handle widget errors
await integrationService.handleWidgetError(error, widgetContext: "Configuration")

// Handle multiple errors
await integrationService.handleMultipleErrors(errors, context: .general)
```

## Usage Examples

### Basic Error Handling

```swift
// In your service or view model
do {
    let result = try await apiClient.fetchRoutes()
    // Handle success
} catch {
    await ErrorIntegrationService.shared.handleGenericError(error, context: .routePlanning)
}
```

### Widget Error Handling

```swift
// In widget configuration
do {
    try saveWidgetConfiguration(config)
} catch {
    await ErrorIntegrationService.shared.handleWidgetError(error, widgetContext: "Save Configuration")
}
```

### Memory Pressure Handling

```swift
// In app delegate or main view
NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { _ in
    Task {
        await ErrorIntegrationService.shared.handleMemoryPressure()
    }
}
```

### SwiftUI Integration

```swift
struct ContentView: View {
    var body: some View {
        NavigationView {
            // Your content
        }
        .enhancedErrorHandling() // Adds comprehensive error handling
    }
}
```

## Error Contexts

Different contexts provide appropriate error handling:

- **`.general`** - Default error handling
- **`.routePlanning`** - Route planning specific errors
- **`.locationSearch`** - Location search errors
- **`.widgetConfiguration`** - Widget setup errors
- **`.backgroundRefresh`** - Background update errors

## Error Severity Levels

### Low Severity
- Haptic feedback unavailable
- Performance optimization failures
- Non-critical feature failures

**Handling**: Usually handled silently with automatic recovery

### Medium Severity
- Network timeouts
- API rate limiting
- Location permission issues

**Handling**: Brief user notification with automatic retry

### High Severity
- Widget configuration failures
- Notification scheduling failures
- Invalid route configurations

**Handling**: User notification with clear recovery steps

### Critical Severity
- Memory pressure warnings
- Data corruption
- Critical service unavailability

**Handling**: Prominent user notification requiring immediate attention

## Automatic Recovery Features

### Exponential Backoff
```swift
// Automatic retry with increasing delays
// Attempt 1: 1 second
// Attempt 2: 2 seconds  
// Attempt 3: 4 seconds
// Max attempts: 3
```

### Intelligent Recovery
- **Performance errors**: Restart optimization services
- **Widget errors**: Reset and restore configuration
- **Batch failures**: Retry individual requests
- **Data corruption**: Attempt data rebuild
- **Memory pressure**: Automatic cleanup

### Recovery Limits
- Maximum 3 retry attempts per error type
- Exponential backoff with jitter
- Circuit breaker pattern for repeated failures

## Diagnostic Information

Generate comprehensive diagnostic reports:

```swift
let diagnosticInfo = ErrorRecoveryService.shared.generateDiagnosticInfo()

// Includes:
// - App version and build
// - iOS version and device info
// - Memory and disk usage
// - Network status
// - Recent error history
// - System settings (battery, low power mode, etc.)
```

## Error Reporting

Generate user-friendly error reports:

```swift
let report = ErrorIntegrationService.shared.generateErrorReport()

// Creates formatted report suitable for:
// - Support requests
// - Bug reports
// - User feedback
```

## Best Practices

### 1. Use Appropriate Contexts
```swift
// Good: Specific context
await handleAPIError(error, context: .routePlanning)

// Avoid: Generic context for specific operations
await handleAPIError(error, context: .general)
```

### 2. Handle Errors at the Right Level
```swift
// Service level: Convert and enhance errors
func fetchRoutes() async throws -> [Route] {
    do {
        return try await apiClient.get(url, as: [Route].self)
    } catch {
        await ErrorIntegrationService.shared.handleAPIError(error as! APIError, context: .routePlanning)
        throw error
    }
}

// View level: Present user-friendly errors
.task {
    do {
        routes = try await routeService.fetchRoutes()
    } catch {
        // Error already handled by service
    }
}
```

### 3. Provide Context-Specific Recovery
```swift
// Widget context provides widget-specific recovery options
await handleWidgetError(error, widgetContext: "Timeline Update")

// Location context provides location-specific recovery options  
await handleLocationError(error, context: .locationSearch)
```

### 4. Use Batch Handling for Multiple Errors
```swift
// Instead of handling each error individually
for error in errors {
    await handleGenericError(error)
}

// Use batch handling
await handleMultipleErrors(errors, context: .backgroundRefresh)
```

## Testing

The system includes comprehensive tests:

```swift
// Test automatic recovery
func testAutomaticErrorRecovery() async {
    let error = EnhancedAppError.performanceOptimizationFailed
    let result = await errorRecoveryService.handleError(error)
    // Assert recovery behavior
}

// Test retry limits
func testRetryLimitEnforcement() async {
    // Test that retry limits are enforced
}

// Test error conversion
func testAPIErrorConversion() async {
    let apiError = APIError.rateLimited(retryAfter: 30.0)
    // Test conversion to enhanced error
}
```

## Integration Checklist

- [ ] Add enhanced error handling to API services
- [ ] Integrate with widget configuration
- [ ] Add memory pressure monitoring
- [ ] Implement notification error handling
- [ ] Add SwiftUI error presentation modifiers
- [ ] Configure diagnostic information collection
- [ ] Add error reporting functionality
- [ ] Test error recovery scenarios
- [ ] Validate user experience with different error types
- [ ] Document error handling patterns for team

## Performance Considerations

- Error handling operations are async and non-blocking
- Diagnostic information generation is optimized for performance
- Error history is limited to prevent memory growth
- Automatic cleanup of old error records
- Efficient error categorization and conversion

## Privacy and Security

- Diagnostic information excludes sensitive user data
- Error messages are sanitized before logging
- User consent for error reporting
- Secure transmission of diagnostic data
- Automatic anonymization of location data in error reports