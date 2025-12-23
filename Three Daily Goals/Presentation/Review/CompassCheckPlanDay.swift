//
//  ReviewPlanDay.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 26/06/2024.
//

import EventKit
import SimpleCalendar
import SwiftUI
import tdgCoreMain
import tdgCoreWidget

/// State for a task being scheduled
struct TaskScheduleState: Identifiable {
    let task: TaskItem
    var startTime: Date
    var duration: TimeInterval
    var isScheduling: Bool = false

    var id: UUID { task.uuid }
}

public struct CompassCheckPlanDay: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(CloudPreferences.self) private var preferences
    @Environment(CompassCheckManager.self) private var compassCheckManager
    @Environment(TimeProviderWrapper.self) private var timeProviderWrapper
    @State private var eventMgr: EventManager?
    @State private var events: [any CalendarEventRepresentable] = []
    @State private var date: Date
    @State private var taskStates: [TaskScheduleState] = []
    @State private var selectedCalendarId: String?
    @State private var errorMessage: String?

    init(date: Date) {
        self._date = State(initialValue: date)
    }

    private func setupEventManager() {
        if eventMgr == nil {
            let newEventMgr = EventManager(timeProvider: timeProviderWrapper.timeProvider)
            eventMgr = newEventMgr

            // Set date range for the planning day
            let startOfDay = timeProviderWrapper.timeProvider.startOfDay(for: date)
            let endOfDay = timeProviderWrapper.timeProvider.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            newEventMgr.refresh(for: startOfDay..<endOfDay)

            // Update events after refresh
            events = newEventMgr.events

            // Initialize selectedCalendarId from preferences or first available calendar
            if let preferredId = preferences.targetCalendarId {
                selectedCalendarId = preferredId
            } else if let firstCalendar = newEventMgr.availableCalendars.first {
                selectedCalendarId = firstCalendar.calendarIdentifier
                preferences.targetCalendarId = firstCalendar.calendarIdentifier
            }
        }
    }

    private func autoPlaceTasks() {
        guard let calendarId = selectedCalendarId else { return }
        guard let eventMgr = eventMgr else { return }

        // Get priority tasks that aren't already scheduled OR have outdated events
        let unscheduledTasks = compassCheckManager.priorityTasks.filter {
            !eventMgr.isTaskScheduled($0) || eventMgr.isEventOutdated($0, targetDate: date)
        }

        guard !unscheduledTasks.isEmpty else { return }

        // Determine starting time
        let now = timeProviderWrapper.timeProvider.now
        let planningDay = timeProviderWrapper.timeProvider.startOfDay(for: date)
        let isToday = Calendar.current.isDate(planningDay, inSameDayAs: now)

        var startTime: Date
        if isToday {
            // If planning today, start at next half-hour
            let calendar = Calendar.current
            let currentMinute = calendar.component(.minute, from: now)

            let minutesToAdd = currentMinute <= 30 ? (30 - currentMinute) : (60 - currentMinute)
            startTime = calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
        } else {
            // If planning future day, start at 8 AM
            startTime = timeProviderWrapper.timeProvider.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
        }

        // Schedule each unscheduled task
        Task { @MainActor in
            for task in unscheduledTasks {
                let duration = defaultDuration(for: task)

                _ = await eventMgr.scheduleTask(
                    task,
                    startDate: startTime,
                    duration: duration,
                    calendarId: calendarId
                )

                // Move start time forward for next task
                startTime = startTime.addingTimeInterval(duration)
            }

            // Refresh events after all tasks are placed
            let startOfDay = timeProviderWrapper.timeProvider.startOfDay(for: date)
            let endOfDay = timeProviderWrapper.timeProvider.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            eventMgr.refresh(for: startOfDay..<endOfDay)
            try? await Task.sleep(nanoseconds: 100_000_000)
            events = eventMgr.events
        }
    }

    private func initializeTaskStates() {
        taskStates = compassCheckManager.priorityTasks.map { task in
            let defaultTime = timeProviderWrapper.timeProvider.date(bySettingHour: 9, minute: 0, second: 0, of: date)
                ?? date
            let defaultDuration = defaultDuration(for: task)
            return TaskScheduleState(
                task: task,
                startTime: defaultTime,
                duration: defaultDuration
            )
        }
    }

    private func defaultDuration(for task: TaskItem) -> TimeInterval {
        let tags = Set(task.tags)
        let isBigTask = tags.contains("big-task")
        return isBigTask ? 2 * 3600 : 30 * 60  // 2 hours or 30 minutes
    }

    private func scheduleTask(state: TaskScheduleState) async {
        guard let calendarId = selectedCalendarId else {
            errorMessage = "No calendar selected"
            return
        }

        guard let eventMgr = eventMgr else {
            errorMessage = "Calendar not initialized"
            return
        }

        // Update state to show scheduling in progress
        if let index = taskStates.firstIndex(where: { $0.id == state.id }) {
            taskStates[index].isScheduling = true
        }

        let success = await eventMgr.scheduleTask(
            state.task,
            startDate: state.startTime,
            duration: state.duration,
            calendarId: calendarId
        )

        // Update state after scheduling
        if let index = taskStates.firstIndex(where: { $0.id == state.id }) {
            taskStates[index].isScheduling = false
        }

        if success {
            // Update events to show the newly created/updated event
            events = eventMgr.events
        } else {
            errorMessage = "Failed to schedule task: \(state.task.title)"
        }
    }

    private func handleEventMoved(event: any CalendarEventRepresentable, newDate: Date) {
        guard let tdgEvent = event as? TDGEvent else { return }
        let eventId = tdgEvent.base.calendarItemIdentifier

        // Find the task associated with this event
        guard let task = compassCheckManager.priorityTasks.first(where: { $0.eventId == eventId }) else {
            return
        }

        // Calculate duration from original event
        let duration = tdgEvent.base.endDate.timeIntervalSince(tdgEvent.base.startDate)

        // Update the event time
        Task { @MainActor in
            guard let eventMgr = eventMgr else { return }

            // Update the event using EventService
            let success = eventMgr.eventService.updateEvent(
                eventId: eventId,
                startDate: newDate,
                duration: duration
            )

            if success {
                // Refresh events to show updated position
                let startOfDay = timeProviderWrapper.timeProvider.startOfDay(for: date)
                let endOfDay = timeProviderWrapper.timeProvider.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                eventMgr.refresh(for: startOfDay..<endOfDay)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                events = eventMgr.events
            } else {
                errorMessage = "Failed to move task: \(task.title)"
            }
        }
    }

    /// Migrate all scheduled priority tasks to a new calendar
    /// - Parameter newCalendarId: The target calendar identifier
    private func migrateEventsToNewCalendar(_ newCalendarId: String) {
        guard let eventMgr = eventMgr else { return }

        // Find all priority tasks that have calendar events
        let scheduledTasks = compassCheckManager.priorityTasks.filter { $0.eventId != nil }

        guard !scheduledTasks.isEmpty else { return }

        Task { @MainActor in
            var migratedCount = 0
            var failedCount = 0

            for task in scheduledTasks {
                guard let eventId = task.eventId else { continue }

                // Get the existing event details
                guard let existingEvent = eventMgr.eventService.getEvent(byId: eventId) else {
                    // Event no longer exists, clear the eventId
                    task.setCalendarEventId(nil)
                    continue
                }

                // Capture event details before deletion
                guard let startDate = existingEvent.startDate,
                      let endDate = existingEvent.endDate else {
                    // Event missing required dates, clear the eventId
                    task.setCalendarEventId(nil)
                    continue
                }
                let duration = endDate.timeIntervalSince(startDate)
                let notes = existingEvent.notes
                let url = existingEvent.url

                // Delete the old event
                let deleted = eventMgr.eventService.deleteEvent(eventId: eventId)
                guard deleted else {
                    failedCount += 1
                    continue
                }

                // Create new event in the new calendar
                if let newEventId = eventMgr.eventService.createEvent(
                    title: task.title,
                    startDate: startDate,
                    duration: duration,
                    calendarId: newCalendarId,
                    notes: notes,
                    url: url,
                    alarmOffsetMinutes: 0
                ) {
                    // Update the task with the new event ID
                    task.setCalendarEventId(newEventId)
                    migratedCount += 1
                } else {
                    failedCount += 1
                }
            }

            // Refresh events to show migrated events
            let startOfDay = timeProviderWrapper.timeProvider.startOfDay(for: date)
            let endOfDay = timeProviderWrapper.timeProvider.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

            // Force clear and refresh to ensure UI updates
            events = []
            try? await Task.sleep(nanoseconds: 200_000_000) // Increased delay for calendar system
            eventMgr.refresh(for: startOfDay..<endOfDay)
            try? await Task.sleep(nanoseconds: 200_000_000)
            events = eventMgr.events

            // Show result message
            if failedCount > 0 {
                errorMessage = "Migrated \(migratedCount) task(s), \(failedCount) failed"
            } else if migratedCount > 0 {
                errorMessage = nil  // Clear any previous errors on success
            }
        }
    }

    private func calendarDayText() -> String {
        let calendar = Calendar.current
        let today = timeProviderWrapper.timeProvider.startOfDay(for: timeProviderWrapper.timeProvider.now)
        let planningDay = timeProviderWrapper.timeProvider.startOfDay(for: date)

        if calendar.isDate(planningDay, inSameDayAs: today) {
            return "Today's Calendar"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
                  calendar.isDate(planningDay, inSameDayAs: tomorrow) {
            return "Tomorrow's Calendar"
        } else {
            // Use date format for other days
            return date.formatted(.dateTime.day().month().weekday(.wide)) + "'s Calendar"
        }
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Spacer()

                    VStack(spacing: 4) {
                        Text("Plan Your Day")
                            .font(.title2)
                            .foregroundStyle(Color.priority)

                        Text(isLargeDevice
                            ? "Drag tasks to calendar to schedule them"
                            : "Schedule your priority tasks to your calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(date, format: .dateTime.day().month().year())
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            .onChange(of: eventMgr?.state) { _, newState in
                // Update events when EventManager finishes loading
                if case .granted = newState, let mgr = eventMgr {
                    events = mgr.events
                }
            }

            // Calendar selection
            if let eventMgr = eventMgr, !eventMgr.availableCalendars.isEmpty {
                HStack {
                    Text("Target Calendar:")
                        .font(.subheadline)

                    Picker("Calendar", selection: $selectedCalendarId) {
                        ForEach(eventMgr.availableCalendars, id: \.calendarIdentifier) { calendar in
                            Text("\(calendar.title) (\(calendar.source.title))").tag(calendar.calendarIdentifier as String?)
                        }
                    }
                    .onChange(of: selectedCalendarId) { oldValue, newValue in
                        // Update preference
                        preferences.targetCalendarId = newValue

                        // Migrate existing events if calendar changed (not initial setup)
                        if let old = oldValue, let new = newValue, old != new {
                            migrateEventsToNewCalendar(new)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            // Unified calendar view with drag & drop for all devices
            if let eventMgr = eventMgr, case .granted = eventMgr.state {
                VStack(alignment: .leading, spacing: 8) {
                    Text(calendarDayText())
                        .font(.headline)
                        .padding(.horizontal)

                    SimpleCalendarView(
                        events: $events,
                        selectedDate: $date,
                        selectionAction: .inform({ _ in }),
                        dateSelectionStyle: .selectedDates([date]),
                        hourHeight: 25.0,
                        hourSpacing: 24.0,
                        startHourOfDay: 6,
                        draggablePredicate: { event in
                            // Only our task events are draggable (check for our deep link URL)
                            if let tdgEvent = event as? TDGEvent {
                                let isDraggable = tdgEvent.base.url?.absoluteString.starts(with: "three-daily-goals://task/") == true
                                print("🔍 Drag check for '\(tdgEvent.base.title)': URL=\(tdgEvent.base.url?.absoluteString ?? "nil"), draggable=\(isDraggable)")
                                return isDraggable
                            }
                            return false
                        },
                        onEventMoved: { event, newDate in
                            if let tdgEvent = event as? TDGEvent {
                                print("🎯 Event moved callback triggered: '\(tdgEvent.base.title)' to \(newDate)")
                            }
                            handleEventMoved(event: event, newDate: newDate)
                        },
                        dragGranularityMinutes: 15
                    )
                    .frame(minHeight: 500)
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            setupEventManager()

            // Wait for EventManager to finish loading events, then auto-place tasks
            Task {
                // Give EventManager time to complete async initialization
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if let mgr = eventMgr, case .granted = mgr.state {
                    events = mgr.events
                    // Auto-place unscheduled priority tasks
                    autoPlaceTasks()
                }
            }
        }
    }
}

// MARK: - Draggable Priority Task (macOS only)

#if os(macOS)
/// A draggable task card for macOS
struct DraggablePriorityTask: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 8) {
            // Energy-Effort Matrix indicator
            if let quadrant = EnergyEffortQuadrant.from(task: task) {
                Image(systemName: quadrant.icon)
                    .font(.caption)
                    .foregroundStyle(quadrant.color)
                    .frame(width: 20)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20)
            }

            // Task title
            Text(task.title)
                .font(.subheadline)
                .lineLimit(2)

            Spacer()
        }
        .padding(8)
        .background(Color.priority.opacity(0.1))
        .clipShape(.rect(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.priority.opacity(0.3), lineWidth: 1)
        )
        .draggable(task.id) {
            // Drag preview
            HStack {
                if let quadrant = EnergyEffortQuadrant.from(task: task) {
                    Image(systemName: quadrant.icon)
                        .foregroundStyle(quadrant.color)
                }
                Text(task.title)
            }
            .padding(8)
            .background(Color.priority.opacity(0.2))
            .clipShape(.rect(cornerRadius: 8))
        }
    }
}
#endif

// MARK: - Timeline Drop Zone (macOS only)

/// A vertical timeline with hourly slots that accepts dragged tasks
struct TimelineDropZone: View {
    let date: Date
    let onDrop: (String, Int) -> Void

    // Working hours (8 AM to 8 PM by default)
    private let startHour = 8
    private let endHour = 20

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { hour in
                    TimeSlotDropZone(
                        hour: hour,
                        onDrop: { taskId in
                            onDrop(taskId, hour)
                        }
                    )
                }
            }
        }
        .background(Color.neutral100)
        .clipShape(.rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.neutral300, lineWidth: 1)
        )
    }
}

/// A single hour time slot that accepts drops
struct TimeSlotDropZone: View {
    let hour: Int
    let onDrop: (String) -> Void

    @State private var isTargeted = false

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a" // e.g., "9 AM", "2 PM"
        let components = DateComponents(hour: hour)
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    var body: some View {
        HStack {
            Text(timeText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)

            Divider()

            Spacer()

            if isTargeted {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.priority)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(isTargeted ? Color.priority.opacity(0.1) : Color.clear)
        .dropDestination(for: String.self) { items, _ in
            for item in items {
                onDrop(item)
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isTargeted = targeted
            }
        }
    }
}

// MARK: - Task Schedule Row

/// Row for scheduling a single task
struct TaskScheduleRow: View {
    @Binding var state: TaskScheduleState
    let date: Date
    let onSchedule: () -> Void

    private var durationText: String {
        let hours = Int(state.duration) / 3600
        let minutes = (Int(state.duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Task title
            HStack(spacing: 8) {
                Text(state.task.title)
                    .font(.headline)
                Spacer()
            }

            // Time and duration pickers
            HStack(spacing: 12) {
                // Start time picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: $state.startTime,
                        in: Calendar.current.startOfDay(for: date)...Calendar.current.date(byAdding: .day, value: 1, to: date)!,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }

                // Duration picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Menu {
                        Button("15 minutes") { state.duration = 15 * 60 }
                        Button("30 minutes") { state.duration = 30 * 60 }
                        Button("1 hour") { state.duration = 1 * 3600 }
                        Button("1.5 hours") { state.duration = 1.5 * 3600 }
                        Button("2 hours") { state.duration = 2 * 3600 }
                        Button("3 hours") { state.duration = 3 * 3600 }
                        Button("4 hours") { state.duration = 4 * 3600 }
                    } label: {
                        HStack {
                            Text(durationText)
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 6))
                    }
                }

                Spacer()

                // Schedule button
                Button(action: onSchedule) {
                    if state.isScheduling {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Label("Schedule", systemImage: "calendar.badge.plus")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.isScheduling)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - iOS Timeline Scheduler

/// iOS-specific timeline scheduler with insertion line and task grid
struct IOSTimelineScheduler: View {
    let date: Date
    @Binding var events: [any CalendarEventRepresentable]
    let tasks: [TaskItem]
    let calendarDayText: String
    let onScheduleTask: (TaskItem, Int) -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var currentHour: Int = 9 // Default to 9 AM

    private let hourHeight: CGFloat = 60
    private let startHour = 6 // 6 AM
    private let endHour = 22 // 10 PM
    private let visibleHourRange = 8 // 4 hours above + 4 hours below

    private var hourRange: Range<Int> {
        startHour..<endHour
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(calendarDayText)
                .font(.headline)
                .padding()

            // Timeline with insertion line
            ZStack {
                // Scrollable timeline
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(hourRange, id: \.self) { hour in
                            TimelineHourSlot(
                                hour: hour,
                                events: eventsAt(hour: hour)
                            )
                            .frame(height: hourHeight)
                        }
                    }
                    .background(GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self,
                                      value: geometry.frame(in: .named("scroll")).origin.y)
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    updateCurrentHour(scrollOffset: offset)
                }

                // Fixed insertion line in the center
                VStack {
                    Spacer()
                    HStack {
                        Text(hourText(currentHour))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.priority)
                            .clipShape(.rect(cornerRadius: 4))

                        Rectangle()
                            .fill(Color.priority)
                            .frame(height: 2)

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(Color.priority)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .frame(height: hourHeight * CGFloat(visibleHourRange))

            // Priority tasks grid
            VStack(alignment: .leading, spacing: 8) {
                Text("Tap to schedule at \(hourText(currentHour))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if !tasks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(tasks) { task in
                                PriorityTaskCard(task: task) {
                                    onScheduleTask(task, currentHour)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("No priority tasks")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .padding()
                }
            }
            .padding(.vertical)
        }
    }

    private func eventsAt(hour: Int) -> [any CalendarEventRepresentable] {
        events.filter { event in
            let calendar = Calendar.current
            let eventHour = calendar.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }

    private func hourText(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let components = DateComponents(hour: hour)
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func updateCurrentHour(scrollOffset: CGFloat) {
        // Calculate which hour is at the center of the view
        let centerOffset = abs(scrollOffset) + (hourHeight * CGFloat(visibleHourRange / 2))
        let hourIndex = Int(centerOffset / hourHeight)
        currentHour = min(max(startHour + hourIndex, startHour), endHour - 1)
    }
}

/// A single hour slot in the timeline
struct TimelineHourSlot: View {
    let hour: Int
    let events: [any CalendarEventRepresentable]

    private var hourText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let components = DateComponents(hour: hour)
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Hour label
            Text(hourText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)

            Divider()

            // Events at this hour
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                    if let tdgEvent = event as? TDGEvent {
                        Text(tdgEvent.base.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(Color.neutral50.opacity(0.3))
    }
}

/// Priority task card for iOS
struct PriorityTaskCard: View {
    let task: TaskItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Energy-Effort indicator
                HStack {
                    if let quadrant = EnergyEffortQuadrant.from(task: task) {
                        Image(systemName: quadrant.icon)
                            .font(.title3)
                            .foregroundStyle(quadrant.color)
                    }
                    Spacer()
                }

                // Task title
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 100)
            .background(Color.priority.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.priority.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Preference key for tracking scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    let appComp = setupApp(isTesting: true)
    let timeProvider = appComp.timeProviderWrapper.timeProvider
    let date = timeProvider.now

    return CompassCheckPlanDay(date: date)
        .environment(appComp.dataManager)
        .environment(appComp.preferences)
        .environment(appComp.compassCheckManager)
        .environment(appComp.timeProviderWrapper)
}
