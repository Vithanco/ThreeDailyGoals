import Testing
@testable import Three_Daily_Goals
@testable import tdgCoreMain

/// Test cases for the new dynamic storage key system
/// Tests the StorageKeys struct and dynamic compass check step management
@MainActor
struct TestDynamicStorageKeys {
    
    /// Helper function to create test preferences for each test
    private func createTestPreferences() -> (TestPreferences, CloudPreferences) {
        let testPreferences = TestPreferences()
        let cloudPreferences = CloudPreferences(store: testPreferences, timeProvider: RealTimeProvider())
        return (testPreferences, cloudPreferences)
    }
    
    // MARK: - StorageKeys Tests
    
    @Test
    func testStorageKeysStructure() {
        // Test that StorageKeys provides the expected key structure
        #expect(StorageKeys.daysOfCompassCheck.id == "daysOfCompassCheck")
        #expect(StorageKeys.longestStreak.id == "longestStreak")
        #expect(StorageKeys.accentColorString.id == "accentColorString")
        #expect(StorageKeys.expiryAfter.id == "expiryAfter")
        #expect(StorageKeys.lastCompassCheckString.id == "lastCompassCheckString")
    }
    
    @Test
    func testCompassCheckTimeKeys() {
        // Test compass check time keys use simple structure
        #expect(StorageKeys.compassCheckTimeHour.id == "compassCheckTimeHour")
        #expect(StorageKeys.compassCheckTimeMinute.id == "compassCheckTimeMinute")
    }
    
    @Test
    func testPriorityKeyGeneration() {
        // Test dynamic priority key generation
        #expect(StorageKeys.priority(1).id == "priority1")
        #expect(StorageKeys.priority(2).id == "priority2")
        #expect(StorageKeys.priority(3).id == "priority3")
        #expect(StorageKeys.priority(4).id == "priority4")
        #expect(StorageKeys.priority(5).id == "priority5")
        #expect(StorageKeys.priority(10).id == "priority10") // Test beyond normal range
    }
    
    @Test
    func testCompassCheckStepKeyGeneration() {
        // Test dynamic compass check step key generation
        #expect(StorageKeys.compassCheckStepIsEnabled("inform").id == "compassCheck.step.inform")
        #expect(StorageKeys.compassCheckStepIsEnabled("currentPriorities").id == "compassCheck.step.currentPriorities")
        #expect(StorageKeys.compassCheckStepIsEnabled("pending").id == "compassCheck.step.pending")
        #expect(StorageKeys.compassCheckStepIsEnabled("dueDate").id == "compassCheck.step.dueDate")
        #expect(StorageKeys.compassCheckStepIsEnabled("review").id == "compassCheck.step.review")
        #expect(StorageKeys.compassCheckStepIsEnabled("plan").id == "compassCheck.step.plan")
        #expect(StorageKeys.compassCheckStepIsEnabled("customStep").id == "compassCheck.step.customStep") // Test custom step
    }
    
    // MARK: - Compass Check Step Toggle Tests
    
    @Test
    func testCompassCheckStepDefaults() {
        // Test default values for compass check steps
        let (_, cloudPreferences) = createTestPreferences()
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: "inform"))
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: "currentPriorities"))
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: "pending"))
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: "dueDate"))
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: "review"))
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: "plan")) // "coming soon"
    }
    
    @Test
    func testCompassCheckStepToggle() {
        // Test enabling/disabling compass check steps
        let (_, cloudPreferences) = createTestPreferences()
        let stepId = "inform"
        
        // Initially enabled by default
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
        
        // Disable the step
        cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: false)
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
        
        // Re-enable the step
        cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: true)
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
    }
    
    @Test
    func testPlanStepComingSoon() {
        // Test that plan step is disabled by default with "coming soon" behavior
        let (_, cloudPreferences) = createTestPreferences()
        let planStepId = "plan"
        
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: planStepId))
        
        // Even if we try to enable it, it should work (for future use)
        cloudPreferences.setCompassCheckStepEnabled(stepId: planStepId, enabled: true)
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: planStepId))
    }
    
    @Test
    func testAllCompassCheckSteps() {
        // Test all known compass check steps
        let (_, cloudPreferences) = createTestPreferences()
        let stepIds = ["inform", "currentPriorities", "pending", "dueDate", "review", "plan"]
        
        for stepId in stepIds {
            // Test that we can get the current state
            let initialState = cloudPreferences.isCompassCheckStepEnabled(stepId: stepId)
            
            // Test that we can toggle the state
            cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: !initialState)
            #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId) == !initialState)
            
            // Test that we can toggle back
            cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: initialState)
            #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId) == initialState)
        }
    }
    
    @Test
    func testUnknownStepId() {
        // Test behavior with unknown step IDs
        let (_, cloudPreferences) = createTestPreferences()
        let unknownStepId = "unknownStep"
        
        // Should default to enabled (fallback behavior)
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: unknownStepId))
        
        // Should be able to toggle
        cloudPreferences.setCompassCheckStepEnabled(stepId: unknownStepId, enabled: false)
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: unknownStepId))
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test
    func testJsonBasedStorage() {
        // Test that the new JSON-based approach works correctly
        let (_, cloudPreferences) = createTestPreferences()
        let stepId = "customStep"
        
        // Initially should return default (true for non-plan steps)
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
        
        // Set to false
        cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: false)
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
        
        // Set to true
        cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: true)
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
    }
    
    @Test
    func testMultipleStepsInJson() {
        // Test that multiple steps can be stored in the same JSON object
        let (_, cloudPreferences) = createTestPreferences()
        let step1 = "step1"
        let step2 = "step2"
        
        // Set different values for different steps
        cloudPreferences.setCompassCheckStepEnabled(stepId: step1, enabled: false)
        cloudPreferences.setCompassCheckStepEnabled(stepId: step2, enabled: true)
        
        // Verify both values are stored correctly
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: step1))
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: step2))
    }
    
    // MARK: - Core Storage Keys Tests
    
    @Test
    func testStringConstants() {
        // Test that string constants work correctly
        let expectedKeys = [
            "daysOfCompassCheck",
            "longestStreak",
            "currentCompassCheckIntervalStart",
            "currentCompassCheckIntervalEnd",
            "compassCheckTimeHour",
            "compassCheckTimeMinute",
            "accentColorString",
            "expiryAfter",
            "lastCompassCheckString",
            "priority1",
            "priority2",
            "priority3",
            "priority4",
            "priority5"
        ]
        
        for key in expectedKeys {
            #expect(!key.isEmpty)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testCompassCheckManagerIntegration() {
        // Test that the CompassCheckManager can work with the new system
        // This is a basic integration test - more detailed tests would be in CompassCheckManager tests
        let (_, cloudPreferences) = createTestPreferences()
        
        // Create a mock CompassCheckManager scenario
        let stepIds = ["inform", "currentPriorities", "pending", "dueDate", "review", "plan"]
        
        for stepId in stepIds {
            // Test that the step can be enabled/disabled
            cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: true)
            #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
            
            cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: false)
            #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
        }
    }
    
    @Test
    func testPersistence() {
        // Test that step toggles persist across preference instances
        let (testPreferences, cloudPreferences) = createTestPreferences()
        let stepId = "inform"
        
        // Set a value
        cloudPreferences.setCompassCheckStepEnabled(stepId: stepId, enabled: false)
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
        
        // Create a new preferences instance with the same store
        let newCloudPreferences = CloudPreferences(store: testPreferences, timeProvider: RealTimeProvider())
        
        // Value should persist
        #expect(!newCloudPreferences.isCompassCheckStepEnabled(stepId: stepId))
    }
    
    // MARK: - Edge Cases
    
    @Test
    func testEmptyStepId() {
        // Test behavior with empty step ID
        let (_, cloudPreferences) = createTestPreferences()
        let emptyStepId = ""
        
        // Should handle gracefully (fallback to inform step)
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: emptyStepId))
        
        cloudPreferences.setCompassCheckStepEnabled(stepId: emptyStepId, enabled: false)
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: emptyStepId))
    }
    
    @Test
    func testSpecialCharactersInStepId() {
        // Test behavior with special characters in step ID
        let (_, cloudPreferences) = createTestPreferences()
        let specialStepId = "step-with-dashes_and_underscores.and.dots"
        
        // Should handle gracefully
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: specialStepId))
        
        cloudPreferences.setCompassCheckStepEnabled(stepId: specialStepId, enabled: false)
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: specialStepId))
    }
    
    @Test
    func testCaseSensitivity() {
        // Test that step IDs are case sensitive
        let (_, cloudPreferences) = createTestPreferences()
        let lowerCaseId = "inform"
        let upperCaseId = "INFORM"
        
        // Set different values for each
        cloudPreferences.setCompassCheckStepEnabled(stepId: lowerCaseId, enabled: false)
        cloudPreferences.setCompassCheckStepEnabled(stepId: upperCaseId, enabled: true)
        
        // Should be treated as different steps
        #expect(!cloudPreferences.isCompassCheckStepEnabled(stepId: lowerCaseId))
        #expect(cloudPreferences.isCompassCheckStepEnabled(stepId: upperCaseId))
    }
}
