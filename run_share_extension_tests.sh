#!/bin/bash

# Share Extension Test Runner
# This script runs the share extension tests specifically

set -e

echo "🧪 Running Share Extension Tests"
echo "================================"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Change to project directory
cd "$PROJECT_DIR"

echo "📁 Project directory: $PROJECT_DIR"

# Check if we're in the right directory
if [ ! -f "Three Daily Goals.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Not in the correct project directory"
    echo "   Expected to find: Three Daily Goals.xcodeproj/project.pbxproj"
    exit 1
fi

echo "🔍 Finding share extension test files..."

# Find all share extension test files
SHARE_TEST_FILES=(
    "Three Daily GoalsTests/TestShareFlow.swift"
    "Three Daily GoalsTests/ShareExtensionTestUtilities.swift"
    "Three Daily GoalsUITests/TestShareExtensionView.swift"
    "Three Daily GoalsUITests/TestShareExtensionIntegration.swift"
    "Three Daily GoalsUITests/TestShareExtensionHarness.swift"
)

# Check if test files exist
MISSING_FILES=()
for file in "${SHARE_TEST_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ Missing test files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
    exit 1
fi

echo "✅ All share extension test files found"

# Run the tests
echo ""
echo "🚀 Running share extension tests..."

# Run non-GUI tests
echo "🧪 Running non-GUI tests (ShareFlow logic)..."
xcodebuild test \
    -project "Three Daily Goals.xcodeproj" \
    -scheme "Three Daily Goals" \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
    -only-testing:Three_Daily_GoalsTests/TestShareFlow \
    -quiet

NON_GUI_RESULT=$?

# Run UI tests
echo "🧪 Running UI tests (ShareExtensionView and integration)..."
xcodebuild test \
    -project "Three Daily Goals.xcodeproj" \
    -scheme "Three Daily Goals" \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
    -only-testing:Three_Daily_GoalsUITests/TestShareExtensionView \
    -only-testing:Three_Daily_GoalsUITests/TestShareExtensionIntegration \
    -only-testing:Three_Daily_GoalsUITests/TestShareExtensionHarness \
    -quiet

UI_RESULT=$?

# Combine results
if [ $NON_GUI_RESULT -eq 0 ] && [ $UI_RESULT -eq 0 ]; then
    TEST_RESULT=0
else
    TEST_RESULT=1
fi

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ All share extension tests passed!"
    echo ""
    echo "📊 Test Summary:"
    echo "   - ShareFlow tests (non-GUI): ✅"
    echo "   - ShareExtensionView tests (UI): ✅"
    echo "   - Integration tests (UI): ✅"
    echo "   - Test harness (UI): ✅"
    echo ""
    echo "🎉 Share extension test harness is working correctly!"
else
    echo "❌ Some share extension tests failed"
    if [ $NON_GUI_RESULT -ne 0 ]; then
        echo "   - Non-GUI tests failed"
    fi
    if [ $UI_RESULT -ne 0 ]; then
        echo "   - UI tests failed"
    fi
    echo "   Check the output above for details"
    exit 1
fi

echo ""
echo "💡 Tips for using the share extension test harness:"
echo "   - Use ShareExtensionTestUtilities for creating mock data"
echo "   - Test different ShareTestScenario cases"
echo "   - Use the assertion helpers for consistent testing"
echo "   - Run individual test files for focused testing"
echo ""
echo "📝 Example usage:"
echo "   let provider = ShareExtensionTestUtilities.createTestScenario(.shortText)"
echo "   let result = try await processShareWorkflow(provider: provider)"
echo "   ShareExtensionTestUtilities.assertTaskCreated(result, expectedTitle: \"Short task\")"
echo ""
echo "🔧 Fixed Issues:"
echo "   - Updated to use Swift 6 and new Swift Testing framework"
echo "   - Fixed reserved keyword 'extension' parameter naming"
echo "   - Replaced Issue.record() with #expect(Bool(false)) for proper Swift Testing"
echo "   - Fixed MockNSItemProvider concurrency issues with @MainActor and @unchecked Sendable"
echo "   - Corrected NSItemProvider method signatures and completion handlers"
echo "   - Fixed UTType.markdown issue by using UTType(filenameExtension:) instead"
echo "   - Moved UI-dependent tests to UI test target and converted to XCTest"
echo "   - Fixed actor isolation issues in UI test MockNSItemProvider"
echo "   - Used DispatchQueue instead of Task for better XCTest compatibility"
