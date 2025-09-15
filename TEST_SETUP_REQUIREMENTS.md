# Test Setup Requirements for Compass Check Step Enablement

## Overview
Due to the new compass check step toggle system, the "plan" step is disabled by default. Tests that expect the "plan" step to be active need explicit setup to enable it.

## Tests That Need `createTestPreferencesWithPlanEnabled()` Setup

### TestCompassCheckSteps.swift
- ✅ `testStepManagerFlow()` - Expects full flow including "plan" step
- ✅ `testStepManagerFlowWithEmptyData()` - Expects full flow including "plan" step  
- ✅ `testStepManagerButtonText()` - Tests button text, needs "plan" step for "Next" vs "Finish"
- ✅ `testCompleteCompassCheckFlow()` - Expects full flow including "plan" step
- ✅ `testMacOSFlow()` - Expects full flow including "plan" step
- ✅ `testReviewStep()` - Tests Review step button text, needs "plan" step for "Next"

### TestCompassCheckFlexibility.swift
- ✅ `testStepOrderingFlexibility()` - Expects full flow including "plan" step

### TestReview.swift
- ✅ `testNoStreak()` - Expects full flow including "plan" step
- ✅ `testIncreaseStreak()` - Expects full flow including "plan" step
- ✅ `testReview()` - Expects full flow including "plan" step
- ✅ `testCompassCheckPauseAndResume()` - Expects full flow including "plan" step

## Tests That DON'T Need Step Enablement Setup

### Individual Step Tests (TestCompassCheckSteps.swift)
- `testInformStep()` - Tests individual step, no flow dependencies
- `testCurrentPrioritiesStep()` - Tests individual step, no flow dependencies
- `testPendingResponsesStep()` - Tests individual step, no flow dependencies
- `testDueDateStep()` - Tests individual step, no flow dependencies
- `testPlanStep()` - Tests individual step, no flow dependencies

### Step Enablement System Tests
- `testStepEnablementSystem()` - Tests the enablement system itself

### Other Tests
- Tests that don't use compass check manager
- Tests that don't expect the "plan" step
- Tests that only test individual components

## Setup Pattern

For tests that need the "plan" step enabled:

```swift
// Before (will fail):
let appComponents = setupApp(isTesting: true, loader: createTestDataLoader())

// After (will pass):
let appComponents = setupApp(isTesting: true, loader: createTestDataLoader(), preferences: createTestPreferencesWithPlanEnabled())
```

## Helper Function

Each test file should have this helper function:

```swift
/// Helper function to create test preferences with plan step enabled
private func createTestPreferencesWithPlanEnabled() -> CloudPreferences {
    let testPreferences = CloudPreferences(store: TestPreferences(), timeProvider: RealTimeProvider())
    testPreferences.setCompassCheckStepEnabled(stepId: "plan", enabled: true)
    return testPreferences
}
```

## Why This Is Needed

1. **Default Behavior**: "plan" step is disabled by default (for "coming soon" feature)
2. **Button Text Logic**: Review step shows "Finish" if "plan" is disabled, "Next" if enabled
3. **Step Flow Logic**: Flow ends early if "plan" step is disabled
4. **Test Expectations**: Many tests were written before the toggle system and expect full flow

## Verification

Tests that expect the "plan" step should:
- Use `createTestPreferencesWithPlanEnabled()` in setup
- Expect `currentStep.id == "plan"` at some point
- Expect Review step to show "Next" (not "Finish")
- Complete the full step flow

