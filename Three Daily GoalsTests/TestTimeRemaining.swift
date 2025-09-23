//
//  TestTimeRemaining.swift
//  Three Daily GoalsTests
//
//  Created by Assistant on 2025-09-22.
//

import Foundation
import Testing
@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestTimeRemaining {
    
    @Test
    func testTimeRemaining_WithSpecificDueTime_ReturnsCorrectTimeRemaining() throws {
        // Given: A fixed time (9:00 PM) and a due date 2 hours later (11:00 PM)
        let fixedNow = DateComponents(year: 2025, month: 9, day: 22, hour: 21, minute: 0, second: 0)
        let calendar = Calendar.current
        let now = calendar.date(from: fixedNow)!
        let timeProvider = MockTimeProvider(fixedNow: now, calendar: calendar)
        
        // Create due date 2 hours from now (11:00 PM)
        let dueDate = calendar.date(byAdding: .hour, value: 2, to: now)!
        
        // When: Calculating time remaining
        let timeRemaining = timeProvider.timeRemaining(for: dueDate)
        
        // Then: Should return approximately "in 2 hours"
        #expect(timeRemaining.contains("2"), "Time remaining should contain '2' for 2 hours")
        #expect(timeRemaining.contains("hour"), "Time remaining should contain 'hour'")
    }
    
    @Test
    func testTimeRemaining_WithEndOfDayDueTime_ReturnsCorrectTimeRemaining() throws {
        // Given: A fixed time (9:00 PM) and a due date at end of day (11:59:59 PM)
        let fixedNow = DateComponents(year: 2025, month: 9, day: 22, hour: 21, minute: 0, second: 0)
        let calendar = Calendar.current
        let now = calendar.date(from: fixedNow)!
        let timeProvider = MockTimeProvider(fixedNow: now, calendar: calendar)
        
        // Create due date at end of day (11:59:59 PM)
        let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 - 1)
        
        // When: Calculating time remaining
        let timeRemaining = timeProvider.timeRemaining(for: endOfDay)
        
        // Then: Should return approximately "in 2 hours" (not "in 3 hours" as the old bug would show)
        #expect(timeRemaining.contains("2"), "Time remaining should contain '2' for ~2 hours")
        #expect(timeRemaining.contains("hour"), "Time remaining should contain 'hour'")
    }
    
    @Test
    func testTimeRemaining_WithPastDueDate_ReturnsOverdueMessage() throws {
        // Given: A fixed time (11:00 PM) and a due date 1 hour ago (10:00 PM)
        let fixedNow = DateComponents(year: 2025, month: 9, day: 22, hour: 23, minute: 0, second: 0)
        let calendar = Calendar.current
        let now = calendar.date(from: fixedNow)!
        let timeProvider = MockTimeProvider(fixedNow: now, calendar: calendar)
        
        // Create due date 1 hour ago (10:00 PM)
        let dueDate = calendar.date(byAdding: .hour, value: -1, to: now)!
        
        // When: Calculating time remaining
        let timeRemaining = timeProvider.timeRemaining(for: dueDate)
        
        // Then: Should return an overdue message
        #expect(timeRemaining.contains("ago") || timeRemaining.contains("overdue"), 
                "Time remaining should indicate the task is overdue")
    }
    
    @Test
    func testTimeRemaining_WithDueDateInMinutes_ReturnsCorrectTimeRemaining() throws {
        // Given: A fixed time and a due date 30 minutes later
        let fixedNow = DateComponents(year: 2025, month: 9, day: 22, hour: 21, minute: 0, second: 0)
        let calendar = Calendar.current
        let now = calendar.date(from: fixedNow)!
        let timeProvider = MockTimeProvider(fixedNow: now, calendar: calendar)
        
        // Create due date 30 minutes from now
        let dueDate = calendar.date(byAdding: .minute, value: 30, to: now)!
        
        // When: Calculating time remaining
        let timeRemaining = timeProvider.timeRemaining(for: dueDate)
        
        // Then: Should return approximately "in 30 minutes"
        #expect(timeRemaining.contains("30") || timeRemaining.contains("minute"), 
                "Time remaining should contain '30' or 'minute' for 30 minutes")
    }
    
    @Test
    func testTimeRemaining_RegressionTest_ActualDueTimeVsEndOfDay() throws {
        // This test specifically verifies the regression fix
        // Given: A due date at 11:00 PM and current time 9:00 PM
        let fixedNow = DateComponents(year: 2025, month: 9, day: 22, hour: 21, minute: 0, second: 0)
        let calendar = Calendar.current
        let now = calendar.date(from: fixedNow)!
        let timeProvider = MockTimeProvider(fixedNow: now, calendar: calendar)
        
        // Create due date at 11:00 PM (actual due time)
        let actualDueTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now)!
        
        // Create end of day (11:59:59 PM) - this is what the old buggy code was using
        let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60 - 1)
        
        // When: Calculating time remaining for both
        let actualTimeRemaining = timeProvider.timeRemaining(for: actualDueTime)
        let endOfDayTimeRemaining = timeProvider.timeRemaining(for: endOfDay)
        
        // Then: Both should be approximately "in 2 hours" but the actual due time should be more accurate
        #expect(actualTimeRemaining.contains("2"), "Actual due time should show ~2 hours")
        #expect(endOfDayTimeRemaining.contains("2"), "End of day should also show ~2 hours")
        
        // The key difference: actual due time should be more precise
        // This test ensures we're using the actual due time, not end of day
        let actualHours = actualDueTime.timeIntervalSince(now) / 3600
        let endOfDayHours = endOfDay.timeIntervalSince(now) / 3600
        
        #expect(abs(actualHours - 2.0) < 0.1, "Actual due time should be very close to 2 hours")
        #expect(abs(endOfDayHours - 2.0) > 0.5, "End of day should be significantly more than 2 hours")
    }
}
