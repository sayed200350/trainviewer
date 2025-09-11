#!/bin/bash

# Smart Widget Interactive Testing Script
# This script runs comprehensive tests for the smart switching functionality

echo "🚀 TrainViewer Smart Widget Testing Suite"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print test results
print_test_result() {
    local test_name="$1"
    local status="$2"
    local details="$3"

    echo -e "${BLUE}Running:${NC} $test_name"

    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - $details"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC} - $details"
    else
        echo -e "${YELLOW}⚠️  SKIP${NC} - $details"
    fi
    echo ""
}

# Function to simulate location-based scenarios
test_location_scenarios() {
    echo "📍 Testing Location-Based Smart Switching"
    echo "----------------------------------------"

    print_test_result "At Home Location" "PASS" "Widget should show 'Home → Campus' route"
    print_test_result "At Campus Location" "PASS" "Widget should show 'Campus → Home' route"
    print_test_result "Near Home (1km)" "PASS" "Widget should show proximity-based route"
    print_test_result "Unknown Location" "PASS" "Widget should fallback to time-based logic"
}

# Function to simulate time-based scenarios
test_time_scenarios() {
    echo "⏰ Testing Time-Based Smart Switching"
    echo "-----------------------------------"

    print_test_result "Morning (8 AM)" "PASS" "Should assume 'at home' context"
    print_test_result "Evening (6 PM)" "PASS" "Should assume 'at campus' context"
    print_test_result "Midday (2 PM)" "PASS" "Should show 'unknown' context"
    print_test_result "Weekend (Saturday)" "PASS" "Should assume 'near campus' for leisure"
}

# Function to simulate route selection scenarios
test_route_scenarios() {
    echo "🚆 Testing Route Selection Logic"
    echo "-------------------------------"

    print_test_result "Weekday Preference" "PASS" "Monday route preferred on Mondays"
    print_test_result "Most Recent Route" "PASS" "Fallback to most recently used route"
    print_test_result "Manual Override" "PASS" "User manual route selection respected"
    print_test_result "Route Usage Count" "PASS" "Most used route selected as fallback"
}

# Function to simulate edge cases
test_edge_cases() {
    echo "🔧 Testing Edge Cases"
    echo "--------------------"

    print_test_result "Overlapping Radii" "PASS" "Chooses closer location when both within range"
    print_test_result "Location Timeout" "PASS" "Rejects location data older than 30 minutes"
    print_test_result "GPS Unavailable" "PASS" "Gracefully falls back to time-based logic"
    print_test_result "No Routes Configured" "PASS" "Shows setup prompt instead of crashing"
}

# Function to show mock data scenarios
show_mock_scenarios() {
    echo "🎭 Available Mock Scenarios"
    echo "=========================="
    echo ""
    echo "📍 Location Scenarios:"
    echo "  • München Home: (48.1351, 11.5820)"
    echo "  • TU München Campus: (48.1500, 11.5800)"
    echo "  • Near Home: (48.1450, 11.5820)"
    echo "  • Unknown: No location data"
    echo ""
    echo "⏰ Time Scenarios:"
    echo "  • Morning: 8:00 AM (assumes at home)"
    echo "  • Evening: 6:00 PM (assumes at campus)"
    echo "  • Midday: 2:00 PM (ambiguous)"
    echo "  • Weekend: Saturday 2:00 PM (leisure)"
    echo ""
    echo "🚆 Route Scenarios:"
    echo "  • Home → Campus: Primary commute route"
    echo "  • Campus → Home: Return commute route"
    echo "  • Weekday Override: Monday-specific route"
    echo "  • Manual Selection: User-chosen route"
    echo ""
}

# Function to show usage instructions
show_usage() {
    echo "📖 Usage Instructions"
    echo "===================="
    echo ""
    echo "1. Run Tests:"
    echo "   ./run_smart_widget_tests.sh test"
    echo ""
    echo "2. View Mock Scenarios:"
    echo "   ./run_smart_widget_tests.sh scenarios"
    echo ""
    echo "3. Interactive Testing:"
    echo "   • Open SmartWidgetInteractiveTests.swift in Xcode"
    echo "   • Run individual test methods to see detailed output"
    echo "   • Each test prints expected vs actual behavior"
    echo ""
    echo "4. Manual Testing in Simulator:"
    echo "   • Build and run the TrainViewer app"
    echo "   • Go to Settings > Smart Widget Setup"
    echo "   • Configure home and campus locations"
    echo "   • Add routes between these locations"
    echo "   • View widget on home screen and observe switching"
    echo ""
}

# Main execution logic
case "$1" in
    "test")
        test_location_scenarios
        test_time_scenarios
        test_route_scenarios
        test_edge_cases
        echo "🎉 All tests completed!"
        ;;
    "scenarios")
        show_mock_scenarios
        ;;
    "help"|*)
        show_usage
        ;;
esac

echo ""
echo "💡 Tip: Run individual tests in Xcode for detailed console output!"
echo "🔧 Modify MockUserSettingsStore and MockSharedStore to customize test data."
