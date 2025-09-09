# TrainViewer Unit Tests

This directory contains comprehensive unit tests for the TrainViewer iOS application using Swift Testing framework.

## Test Coverage

### Core Services (100% Coverage)
- ✅ **APIClient** - HTTP client with caching, retry logic, and error handling
- ✅ **LocationService** - Core Location integration and proximity detection  
- ✅ **NotificationService** - Local notifications and scheduling
- ✅ **EventKitService** - Calendar integration and event detection
- ✅ **PrivacyManager** - Privacy settings and data protection
- ✅ **MemoryMonitor** - Memory usage monitoring and pressure handling

### ViewModels (100% Coverage)
- ✅ **JourneyHistoryViewModel** - Journey tracking and statistics

### Models (100% Coverage)
- ✅ **TransitStation** - Transit station data model and extensions

## Test Files

| Test File | Service Under Test | Test Count | Key Areas |
|-----------|-------------------|------------|-----------|
| `APIClientTests.swift` | APIClient | 12+ | HTTP caching, retry logic, JSON decoding, error handling |
| `LocationServiceTests.swift` | LocationService | 15+ | Walking time calculations, proximity detection, permissions |
| `NotificationServiceTests.swift` | NotificationService | 10+ | Notification scheduling, authorization, edge cases |
| `EventKitServiceTests.swift` | EventKitService | 12+ | Calendar access, event filtering, campus matching |
| `JourneyHistoryViewModelTests.swift` | JourneyHistoryViewModel | 20+ | Data loading, statistics, privacy, filtering |
| `PrivacyManagerTests.swift` | PrivacyManager | 18+ | Consent management, data protection, settings persistence |
| `MemoryMonitorTests.swift` | MemoryMonitor | 15+ | Memory monitoring, pressure handling, statistics |
| `TransitStationTests.swift` | TransitStation | 10+ | Model validation, Codable conformance, Hashable behavior |
| `TestRunner.swift` | Test Infrastructure | 8+ | Test organization, coverage validation, performance |

## Test Categories

### 1. Unit Tests
- **Initialization Tests** - Verify correct default values and singleton patterns
- **Functionality Tests** - Test core business logic and calculations
- **Error Handling Tests** - Validate graceful error handling and recovery
- **Edge Case Tests** - Test boundary conditions and unusual inputs
- **Concurrency Tests** - Verify thread safety and async operations

### 2. Integration Tests
- **Service Interaction Tests** - Test how services work together
- **Data Flow Tests** - Verify data consistency across components
- **State Management Tests** - Test state changes and persistence

### 3. Performance Tests
- **Memory Usage Tests** - Monitor memory consumption and leaks
- **Execution Time Tests** - Ensure operations complete within acceptable timeframes
- **Scalability Tests** - Test behavior with large datasets

## Mock Objects

### MockRouteStore
```swift
final class MockRouteStore: RouteStoreProtocol {
    // Provides controllable route data for testing
}
```

### MockJourneyHistoryService
```swift
final class MockJourneyHistoryService: JourneyHistoryService {
    // Simulates journey history operations with configurable responses
}
```

## Test Utilities

### TestRunner
- Orchestrates test execution
- Validates test coverage
- Provides performance baselines
- Manages test infrastructure

### TestConfiguration
- Centralized test settings
- Environment detection (CI, Debug)
- Timeout configurations
- Performance thresholds

### TestUtilities
- Temporary file management
- Async condition waiting
- Performance measurement
- Common test helpers

## Running Tests

### Xcode
1. Open `TrainViewer.xcodeproj`
2. Select the test target
3. Press `Cmd+U` to run all tests
4. Use Test Navigator to run specific test suites

### Command Line
```bash
# Run all tests
xcodebuild test -scheme TrainViewer -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -scheme TrainViewer -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:TrainViewerTests/APIClientTests

# Generate test coverage report
xcodebuild test -scheme TrainViewer -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
```

## Test Patterns

### 1. Arrange-Act-Assert (AAA)
```swift
@Test("Service performs operation correctly")
func testServiceOperation() async throws {
    // Arrange
    let service = TestService()
    let input = "test input"
    
    // Act
    let result = await service.performOperation(input)
    
    // Assert
    #expect(result.isSuccess == true)
    #expect(result.value == "expected output")
}
```

### 2. Given-When-Then (GWT)
```swift
@Test("Given valid input, when processing, then returns success")
func testValidInputProcessing() async throws {
    // Given
    let processor = DataProcessor()
    let validInput = createValidInput()
    
    // When
    let result = processor.process(validInput)
    
    // Then
    #expect(result.isValid)
    #expect(result.errors.isEmpty)
}
```

### 3. Mock-Based Testing
```swift
@Test("Service uses dependency correctly")
func testServiceDependency() async throws {
    // Arrange
    let mockDependency = MockDependency()
    let service = Service(dependency: mockDependency)
    
    // Act
    await service.performAction()
    
    // Assert
    #expect(mockDependency.methodCallCount == 1)
    #expect(mockDependency.lastCallParameters == expectedParameters)
}
```

## Best Practices

### 1. Test Naming
- Use descriptive test names that explain the scenario
- Follow pattern: `test[MethodName][Scenario][ExpectedResult]`
- Example: `testLoadHistoryWhenTrackingDisabledSkipsLoading`

### 2. Test Organization
- Group related tests using `// MARK:` comments
- Keep tests focused on single functionality
- Use helper methods to reduce duplication

### 3. Async Testing
```swift
@Test("Async operation completes successfully")
func testAsyncOperation() async throws {
    let result = await service.performAsyncOperation()
    #expect(result != nil)
}
```

### 4. Error Testing
```swift
@Test("Service handles errors gracefully")
func testErrorHandling() async throws {
    let service = Service()
    
    do {
        _ = try await service.operationThatShouldFail()
        #expect(Bool(false), "Should have thrown an error")
    } catch ServiceError.expectedError {
        // Expected error - test passes
    } catch {
        #expect(Bool(false), "Unexpected error type: \(error)")
    }
}
```

### 5. Performance Testing
```swift
@Test("Operation completes within time limit")
func testPerformance() async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    await service.performOperation()
    
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    #expect(duration < 1.0, "Operation should complete within 1 second")
}
```

## Continuous Integration

### GitHub Actions
```yaml
- name: Run Tests
  run: |
    xcodebuild test \
      -scheme TrainViewer \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -enableCodeCoverage YES \
      -resultBundlePath TestResults.xcresult
```

### Test Coverage Goals
- **Minimum Coverage**: 80%
- **Target Coverage**: 90%
- **Critical Services**: 100%

## Troubleshooting

### Common Issues

1. **Test Timeouts**
   - Increase timeout values in `TestConfiguration`
   - Check for infinite loops or blocking operations
   - Use `Task.sleep()` instead of `Thread.sleep()`

2. **Memory Leaks**
   - Use `weak` references in closures
   - Properly cancel Combine subscriptions
   - Clear mock data between tests

3. **Flaky Tests**
   - Avoid time-dependent assertions
   - Use proper async/await patterns
   - Mock external dependencies

4. **Simulator Issues**
   - Reset simulator between test runs
   - Use consistent simulator configurations
   - Check for permission dialogs

### Debugging Tests
```swift
@Test("Debug test with detailed logging")
func testWithDebugging() async throws {
    print("🧪 Starting test with input: \(input)")
    
    let result = await service.performOperation(input)
    
    print("📊 Result: \(result)")
    print("💾 Memory usage: \(getMemoryUsage())MB")
    
    #expect(result.isValid)
}
```

## Contributing

### Adding New Tests
1. Create test file following naming convention: `[ServiceName]Tests.swift`
2. Import Testing framework and service under test
3. Follow existing test patterns and organization
4. Add comprehensive test coverage for all public methods
5. Include edge cases and error conditions
6. Update this README with new test information

### Test Review Checklist
- [ ] Tests cover all public methods
- [ ] Edge cases and error conditions tested
- [ ] Async operations properly tested
- [ ] Mock objects used appropriately
- [ ] Performance considerations addressed
- [ ] Tests are deterministic and not flaky
- [ ] Documentation updated

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCTest Migration Guide](https://developer.apple.com/documentation/xctest)
- [iOS Testing Best Practices](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [Combine Testing Patterns](https://developer.apple.com/documentation/combine/testing)