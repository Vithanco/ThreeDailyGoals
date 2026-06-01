#!/bin/bash

# Optimized test runner for Three Daily Goals
# Runs tests only once per platform to eliminate repetition.
#
# Uses the dedicated test schemes and concrete destinations that are known to
# work; the app scheme + `-only-testing` combination triggers a
# "not a member of the test plan" error, so we use the per-suite schemes.

set -o pipefail

PROJECT="Three Daily Goals.xcodeproj"
IOS_DEST="platform=iOS Simulator,name=iPhone 17,OS=latest"
MAC_DEST="platform=macOS,arch=arm64"

# Essential UI tests (one representative per concern) to keep the run fast.
ESSENTIAL_UITESTS=(
  -only-testing:"Three Daily GoalsUITests/Three_Daily_GoalsUITests/testButtons"
  -only-testing:"Three Daily GoalsUITests/Three_Daily_GoalsUITests/testInfo"
  -only-testing:"Three Daily GoalsUITests/AttachmentUITests/testAttachmentWorkflow"
)

echo "🚀 Running optimized tests for Three Daily Goals"
echo "================================================"

# --- macOS -------------------------------------------------------------------
echo "🖥  Testing on macOS..."
echo "  Running unit tests..."
xcodebuild test \
  -project "$PROJECT" \
  -scheme "Three Daily GoalsTests" \
  -destination "$MAC_DEST" \
  -skip-testing:"Three Daily GoalsUITests" \
  | grep -E "(passed|failed|Test Suite|error:|\*\* TEST)"

echo "  Running UI tests (essential only)..."
xcodebuild test \
  -project "$PROJECT" \
  -scheme "Three Daily GoalsUITests" \
  -destination "$MAC_DEST" \
  "${ESSENTIAL_UITESTS[@]}" \
  | grep -E "(passed|failed|Test Suite|error:|\*\* TEST)"

echo ""
echo "✅ macOS tests completed"
echo ""

# --- iOS Simulator -----------------------------------------------------------
echo "📱 Testing on iOS Simulator (iPhone 17) - essential only..."
xcodebuild test \
  -project "$PROJECT" \
  -scheme "Three Daily GoalsUITests" \
  -destination "$IOS_DEST" \
  "${ESSENTIAL_UITESTS[@]}" \
  | grep -E "(passed|failed|Test Suite|error:|\*\* TEST)"

echo ""
echo "✅ iOS tests completed"
echo ""
echo "🎉 All platform tests completed!"
