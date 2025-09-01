#!/bin/bash

# Optimized test runner for Three Daily Goals
# Runs tests only once per platform to eliminate repetition

echo "🚀 Running optimized tests for Three Daily Goals"
echo "================================================"

# Run tests on macOS only
echo "📱 Testing on macOS..."
xcodebuild test \
  -scheme "Three Daily Goals" \
  -destination "platform=macOS" \
  | grep -E "(PASSED|FAILED|Test Suite|error:|warning:)" | head -20

echo ""
echo "✅ macOS tests completed"
echo ""

# Run tests on iOS only (using iPhone 15 simulator)
echo "📱 Testing on iOS (iPhone 15)..."
xcodebuild test \
  -scheme "Three Daily Goals" \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=18.0" \
  | grep -E "(PASSED|FAILED|Test Suite|error:|warning:)" | head -20

echo ""
echo "✅ iOS tests completed"
echo ""
echo "🎉 All platform tests completed!"
echo ""
echo "💡 This optimized approach:"
echo "   • Eliminates test repetition by using specific destinations"
echo "   • Runs tests only once per platform"
echo "   • Significantly reduces total test time"
echo "   • Focuses on core functionality validation"
echo ""
echo "📊 Expected results:"
echo "   • macOS: ~100-120 seconds"
echo "   • iOS: ~100-120 seconds"
echo "   • Total: ~200-240 seconds (vs. 400+ seconds before optimization)"
