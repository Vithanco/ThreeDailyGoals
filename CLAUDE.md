# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Three Daily Goals is a productivity iOS/macOS application built with SwiftUI and SwiftData. It helps users manage tasks using a priority-based system with a unique "Compass Check" review workflow. The app supports CloudKit sync, widgets, share extensions, and multi-platform deployment (iOS, macOS).

## Build Commands

### Building the Main App
```bash
xcodebuild -project "Three Daily Goals.xcodeproj" -scheme "Three Daily Goals" -configuration Debug build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project "Three Daily Goals.xcodeproj" -scheme "Three Daily Goals" -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"

# Run specific test target
xcodebuild test -project "Three Daily Goals.xcodeproj" -scheme "Three Daily Goals" -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" -only-testing:Three_Daily_GoalsTests

# Run UI tests
xcodebuild test -project "Three Daily Goals.xcodeproj" -scheme "Three Daily Goals" -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" -only-testing:Three_Daily_GoalsUITests
```

### Testing the Swift Package (tdgCore)
```bash
cd tdgCore
swift test
swift build
```

## Architecture

### Multi-Module Structure

The project uses a **Swift Package** (`tdgCore`) to share code between multiple targets:

- **tdgCoreWidget** - Base utilities, helpers, and shared types (no dependencies)
- **tdgCoreMain** - Core domain models (TaskItem, Comment, Attachment), storage layer with SwiftData schemas and migrations, and main app presentation components
- **tdgCoreShare** - Share extension logic for handling shared content
- **tdgCoreTest** - Test utilities for testing share extensions

The main app target (`Three Daily Goals`) depends on `tdgCoreMain` and adds app-specific controllers, views, and the Compass Check workflow.

### Dependency Flow
```
tdgCoreWidget (base)
    ↓
tdgCoreMain (depends on tdgCoreWidget)
    ↓
tdgCoreShare (depends on tdgCoreMain)
    ↓
tdgCoreTest (depends on tdgCoreShare)
```

### App Initialization Flow

1. **Three_Daily_GoalsApp.swift** - SwiftUI App entry point
2. **setupApp()** in AppSetup.swift - Creates all app components:
   - `ModelContainer` - SwiftData storage container
   - `CloudPreferences` - User preferences stored in CloudKit
   - `TimeProviderWrapper` - Time abstraction for testing
   - `DataManager` - Data access and task operations
   - `UIStateManager` - UI state coordination
   - `CompassCheckManager` - Daily review workflow
   - `PushNotificationManager` - Notification scheduling

3. **MainView.swift** - Root view that switches between RegularMainView (iPad/Mac) and CompactMainView (iPhone)

All managers are injected into the SwiftUI environment and available via `@Environment`.

### Domain Models (SwiftData)

The app uses **SwiftData** for persistence with a versioned schema system. Current schema: `SchemaV3_6` (aliased as `SchemaLatest`).

**Core Models:**
- **TaskItem** - Main task entity with states (open, priority, closed, dead, pendingResponse)
  - Has computed properties: `title`, `details`, `url`, `state`, `tags`
  - Backend uses private underscore fields: `_title`, `_details`, `_url`, `_state`
  - Use setter methods like `setTitle()`, `setState()` instead of direct assignment to ensure `changed` date is updated
  - Tags stored as comma-separated string in `allTagsString`, accessed via computed `tags` property

- **Comment** - Activity log entries attached to tasks (state changes, user notes)
- **Attachment** - File attachments linked to tasks with storage management

**Important:** Schema migrations are defined in `Migrations.swift` using SwiftData's `SchemaMigrationPlan`. When modifying models:
1. Create a new schema version (e.g., SchemaV3_7)
2. Add migration stages in `TDGMigrationPlan`
3. Update `SchemaLatest` typealias

### Manager Pattern

The app uses `@Observable` manager classes instead of ViewModels:

- **DataManager** - All data operations (CRUD, queries, import/export, undo/redo)
- **UIStateManager** - UI state (selected task, dialogs, navigation)
- **CompassCheckManager** - Compass Check workflow state and step execution
- **CloudPreferences** - User preferences synced via CloudKit
- **CalendarManager** - EventKit integration for task scheduling

These managers are created once during `setupApp()` and shared across all views via SwiftUI environment.

### Compass Check System

The Compass Check is a customizable multi-step daily review workflow. Steps are defined as protocol implementations:

**CompassCheckStep Protocol:**
```swift
protocol CompassCheckStep {
    var id: String { get }
    var title: String { get }
    var icon: String { get }
    func performAction(manager: CompassCheckManager) async -> String
}
```

**Default Steps (in order):**
1. **DueDateStep** - Review tasks with approaching due dates
2. **PendingResponsesStep** - Check tasks waiting for responses
3. **ReviewStep** - Review recently closed tasks
4. **MoveToGraveyardStep** - Archive stale tasks as "dead"
5. **CurrentPrioritiesStep** - Review current priorities
6. **MovePrioritiesToOpenStep** - Demote priorities back to open
7. **PlanStep** - Select new priorities for today (integrates with Calendar via EventKit)
8. **InformStep** - Summary and completion

Steps can be enabled/disabled in preferences. Step execution is managed by `CompassCheckManager`.

### Testing Strategy

**Test Modes:**
- App detects test mode via `CommandLine.arguments` containing "enable-testing"
- Test mode uses in-memory ModelContainer with `createDefaultTestData()`
- Production uses persistent CloudKit-synced container

**Test Data Loading:**
- Uses `TestDataLoader` typealias: `@Sendable (TimeProvider) -> [TaskItem]`
- Default loader: `defaultTestDataLoader` creates ~25 sample tasks
- Custom loaders can be passed to `setupApp()` for specific test scenarios

**Share Extension Testing:**
See `SHARE_EXTENSION_TESTING.md` for comprehensive test harness documentation. Key points:
- Non-GUI tests use Swift Testing framework (`@Test`, `#expect()`)
- UI tests use XCTest for view initialization
- Mock `NSItemProvider` for simulating shared content
- Test utilities in `ShareExtensionTestUtilities.swift`

### Widget & Share Extension

**Widget:**
- Target: "Three Daily Goals Widget"
- Uses `tdgCoreWidget` for shared utilities
- Displays current priorities via App Groups shared data
- URL scheme: `three-daily-goals://task/{uuid}` to open specific tasks

**Share Extensions:**
- iOS target: `iosShare`
- macOS target: `macosShare`
- Both use `tdgCoreShare` module
- `ShareFlow.resolve()` handles different content types (URL, text, files, attachments)
- Creates tasks from shared content with proper title/details split

### State Management & TaskItemState

Tasks have 5 states defining their lifecycle:
- **open** - Active tasks in backlog
- **priority** - Today's focus (max 3 recommended, widget shows these)
- **pendingResponse** - Waiting on others
- **closed** - Completed tasks
- **dead** - Archived/cancelled tasks (graveyard)

State transitions create `Comment` entries for audit trail. Use methods like `closeTask()`, `makePriority()`, `graveyard()` instead of direct state assignment.

### CloudKit Integration

- Uses SwiftData's automatic CloudKit sync via `ModelConfiguration.CloudKitDatabase.automatic`
- `CloudPreferences` class manages user settings in CloudKit key-value store
- Preferences stored with `StorageKeys` (e.g., `StorageKeys.accentColorString`)
- Priority tasks synced for widgets via `storePriorityTaskInCloudKitRecord()`

### Time Abstraction

All date/time access goes through `TimeProvider` protocol:
- **RealTimeProvider** - Production (uses `Date()`)
- **MockTimeProvider** - Testing (fixed time)

This enables deterministic testing and UI preview generation. Never use `Date()` directly; use `timeProvider.now` instead.

## Development Notes

### Schema Versions
Current: SchemaV3_6. Historical versions preserved in `Storage/ModelVersions/` (SchemaV3_1 through SchemaV3_6). Migrations defined in `Migrations.swift`.

### Undo/Redo
ModelContext has `UndoManager` enabled. DataManager provides `undoButton` and `redoButton` for UI. All data-modifying operations automatically support undo/redo.

### Import/Export
- Export: `JSONWriteOnlyDoc` serializes all tasks to JSON
- Import: `importTasks()` in DataManager with conflict resolution UI
- Format: JSON array of tasks with full object graph (tasks, comments, attachments)

### External Dependencies
- **SimpleCalendar** (GitHub: Vithanco/SimpleCalendar) - Calendar view component for date selection in Compass Check planning step

### Platform Differences

**Three Platform Targets:**
- **macOS** - Uses `RegularMainView` with dedicated window for Compass Check review
- **iPadOS** - Uses `RegularMainView` with sheet for Compass Check review
- **iOS (iPhone)** - Uses `CompactMainView` with sheet for Compass Check review

**Platform-Specific UI:**
- Compass Check: macOS uses dedicated window (`WindowGroup(id: "CompassCheckWindow")`), iOS/iPadOS use full-screen cover/sheet
- Settings: macOS uses `Settings {}` scene, iOS/iPadOS use sheet from toolbar
- Toolbar placement: NavigationSplitView toolbar behavior differs between macOS and iPadOS - macOS properly displays `.standardToolbar()` items, iPadOS requires explicit toolbar items on content column

### Swift 6 Compatibility
- Project uses Swift 6.0 with strict concurrency checking
- All managers are `@MainActor` for UI safety
- Sendable conformance for data passed across actor boundaries
- tdgCore package targets iOS 26, macOS 26, watchOS 11

## Common Workflows

### Adding a New Task State
1. Update `TaskItemState` enum in `tdgCoreMain/Domain/TaskItemState.swift`
2. Add icon constant in `IconsRelated.swift`
3. Create state transition method on TaskItem (like `graveyard()`, `makePriority()`)
4. Update UI to show new state in StateView
5. Add to Compass Check steps if relevant

### Adding a New Compass Check Step
1. Create new step class conforming to `CompassCheckStep` in `Domain/CompassCheckSteps/`
2. Implement `id`, `title`, `icon`, and `performAction()`
3. Add to `CompassCheckManager.DEFAULT_STEPS` array
4. Create corresponding view in `Presentation/Review/` if step needs custom UI
5. Add preference toggle in `CompassCheckStepsPreferencesView`

### Modifying Storage Schema
1. Copy latest schema file (e.g., SchemaV3_6.swift) to SchemaV3_7.swift
2. Make model changes in new schema version
3. Add migration in `TDGMigrationPlan.stages` array
4. Implement migration logic if data transformation needed
5. Update `SchemaLatest` typealias to point to new version
6. Test migration with production data before release

### Running Share Extension Tests
```bash
# Run all share extension tests
xcodebuild test -project "Three Daily Goals.xcodeproj" -scheme "Three Daily Goals" -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" -only-testing:Three_Daily_GoalsTests/TestShareFlow

# Or use the provided script
./run_share_extension_tests.sh
```

## URL Schemes

- `three-daily-goals://task/{uuid}` - Open specific task
- `three-daily-goals://app` - Just open the app

Handle in `handleURL()` function in Three_Daily_GoalsApp.swift.
