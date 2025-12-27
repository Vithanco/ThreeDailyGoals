# AGENTS.md

This file provides guidance to AI coding assistants (Claude Code, Cursor, GitHub Copilot, etc.) when working with code in this repository.

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
1. **InformStep** - Welcome and introduction to the Compass Check
2. **EnergyEffortMatrixConsistencyStep** (silent) - Auto-fixes conflicting Energy-Effort Matrix tags
3. **CurrentPrioritiesStep** - Review current priorities
4. **MovePrioritiesToOpenStep** - Demote old priorities back to open
5. **EnergyEffortMatrixStep** - Categorize tasks by energy required and task size
6. **PendingResponsesStep** - Check tasks waiting for responses
7. **DueDateStep** - Review tasks with approaching due dates
8. **ReviewStep** - Review recently closed tasks
9. **MoveToGraveyardStep** - Archive stale tasks as "dead"
10. **PlanStep** - Select new priorities for today (integrates with Calendar via EventKit)

Steps can be enabled/disabled in preferences. Step execution is managed by `CompassCheckManager`.

### Testing Strategy

**CRITICAL: Test-Driven Development Approach**

This project follows a strict Test-Driven Development (TDD) methodology:

1. **Write Tests First**
   - When identifying a bug or implementing a new feature, **ALWAYS create a failing test first**
   - The test should demonstrate the problem or define the expected behavior
   - Only after the test is written and fails should you implement the fix

2. **Test-First Workflow:**
   ```
   1. Identify the issue or feature requirement
   2. Discuss and align on test cases with the user
   3. Write a failing test that proves the issue or defines the behavior
   4. Verify the test fails for the right reason
   5. Implement the minimal fix to make the test pass
   6. Verify the test passes
   7. Refactor if needed while keeping tests green
   ```

3. **Bug Fixing Protocol:**
   - **Never fix a bug without a failing test first**
   - The test serves as proof that:
     - The bug exists (test fails)
     - The fix works (test passes)
     - The bug won't regress in the future
   - Example workflow:
     ```swift
     // Step 1: Write a test that demonstrates the bug
     @Test func taskStateTransitionCreatesComment() {
         // This test will fail, proving the bug exists
         let task = TaskItem()
         task.setState(.closed)
         #expect(task.comments.count > 0)
     }

     // Step 2: Fix the bug
     // Step 3: Verify test now passes
     ```

4. **Feature Development Protocol:**
   - Before writing implementation code, align with the user on:
     - What tests will be written
     - What behavior they should verify
     - Edge cases to cover
   - Get approval on test strategy before implementing
   - Write tests first, then implementation

**Test Modes:**
- App detects test mode via `CommandLine.arguments` containing "enable-testing"
- Test mode uses in-memory ModelContainer with `createDefaultTestData()`
- Production uses persistent CloudKit-synced container

**Test Data Loading:**
- Uses `TestDataLoader` typealias: `@Sendable (TimeProvider) -> [TaskItem]`
- Default loader: `defaultTestDataLoader` creates ~25 sample tasks
- Custom loaders can be passed to `setupApp()` for specific test scenarios

**Test Frameworks:**
- Non-GUI tests use Swift Testing framework (`@Test`, `#expect()`)
- UI tests use XCTest for view initialization
- Mock `NSItemProvider` for simulating shared content
- Test utilities in `ShareExtensionTestUtilities.swift`

**Share Extension Testing:**
See `SHARE_EXTENSION_TESTING.md` for comprehensive test harness documentation.

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

## Development Workflow

### Testing Workflow
- **Always run tests before committing** - Use `xcodebuild test` or `swift test` (for tdgCore package)
- **Fix all test failures before creating PR** - No exceptions; the entire test suite must be green
- **Add tests for any code you change** - Even if not explicitly requested, always add or update tests
- **Use TDD approach** - Write failing test first, then implement fix (see Testing Strategy above)
- **Run specific tests during development:**
  ```bash
  # Run only failing tests to iterate quickly
  xcodebuild test -project "Three Daily Goals.xcodeproj" -scheme "Three Daily Goals" -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" -only-testing:Three_Daily_GoalsTests/TestClassName/testMethodName
  ```
- **Type-check Swift files** before committing:
  ```bash
  swiftc -typecheck "path/to/file.swift"
  ```

### Pre-Commit Checklist
1. All tests pass (`xcodebuild test` for main app, `swift test` for tdgCore)
2. No compiler warnings
3. Code follows SwiftUI best practices (see above)
4. SF Symbols are declared in `IconsRelated.swift`
5. Schema changes include migration logic if needed
6. TDD workflow followed (test written before implementation)

### PR Conventions
- **Title format:** `[Component] Description`
  - Examples: `[CompassCheck] Fix step navigation bug`, `[Storage] Add migration for SchemaV3_7`, `[Widget] Update priority display`
- **Always run full test suite before creating PR**
- **Include test evidence** - Mention which tests were added/updated
- **Reference AGENTS.md sections** - If following specific guidelines (e.g., TDD, SwiftUI best practices), mention them

### Navigation Tips
- Use Xcode's **Open Quickly** (Cmd+Shift+O) to jump to files, types, or methods instead of browsing
- Search for specific test classes: `xcodebuild test -only-testing:TestClassName` to focus on one area
- Check Swift package structure: `cd tdgCore && swift package describe` to see module dependencies
- Find SwiftData schema versions: Look in `tdgCore/Sources/tdgCoreMain/Storage/ModelVersions/`

### Debugging Workflow
- **Check git status** before making changes to understand current state
- **Run targeted tests** to validate fixes quickly
- **Use test mode** - Pass `enable-testing` argument to load in-memory test data
- **Check schema migrations** - Review `Migrations.swift` when storage issues occur
- **Verify CloudKit sync** - Check `CloudPreferences` for sync-related settings

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

## SwiftUI Best Practices

This project follows modern SwiftUI conventions and best practices. When writing or modifying SwiftUI code, adhere to these guidelines:

### Modern API Usage

1. **Styling Modifiers**
   - ✅ Use `.foregroundStyle()` instead of deprecated `.foregroundColor()`
   - ✅ Use `.clipShape(.rect(cornerRadius:))` instead of deprecated `.cornerRadius()`
   - Exception: `RoundedRectangle(cornerRadius:)` is still the correct pattern for shapes

2. **View Modifiers**
   - ✅ Use 2-parameter or no-parameter `.onChange(of:)` - the 1-parameter variant is unsafe and deprecated
   - ✅ Use the new `Tab` API instead of old `tabItem()` modifier for type-safe tab selection

3. **Navigation**
   - ✅ Use `NavigationStack` instead of deprecated `NavigationView`
   - ✅ Use modern `NavigationLink(value:)` with `.navigationDestination(for:)` instead of inline destination NavigationLinks
   - Better for type safety and allows for more flexible navigation patterns

4. **User Interaction**
   - ✅ Use `Button` instead of `.onTapGesture()` for interactive elements
   - Exceptions: Only use `.onTapGesture()` when you need tap location or tap count
   - Buttons work better with VoiceOver and eye tracking on visionOS

### State Management

1. **Observable Pattern**
   - ✅ Use `@Observable` macro instead of `ObservableObject` (unless specifically relying on Combine publishers)
   - Simpler code and better performance
   - Intelligent view invalidation

2. **View Decomposition**
   - ✅ Split views into separate structs instead of computed properties
   - Critical for performance with `@Observable` - computed properties don't benefit from intelligent view invalidation
   - Example:
     ```swift
     // ❌ Don't do this
     var headerView: some View {
         Text("Header")
     }

     // ✅ Do this instead
     struct HeaderView: View {
         var body: some View {
             Text("Header")
         }
     }
     ```

### Typography & Accessibility

1. **Dynamic Type**
   - ✅ Use Dynamic Type fonts (`.body`, `.headline`, `.caption`, etc.) instead of `.font(.system(size:))`
   - Better accessibility support for users with different font size preferences
   - Exception: Widget sizes are constrained, fixed fonts may be acceptable
   - For scaling: Use `.font(.body.scaled(by: 1.5))` on iOS 26+

2. **Button Labels**
   - ✅ Use inline API: `Button("Tap me", systemImage: "plus", action: action)` or `Label` for better VoiceOver
   - ❌ Avoid using just images without labels

### SF Symbols (System Images)

**CRITICAL RULE: All SF Symbols must be declared in IconsRelated.swift before use**

1. **Central Declaration**
   - ✅ **ALWAYS** define SF Symbol constants in `tdgCore/Sources/tdgCoreWidget/Helpers/IconsRelated.swift`
   - ❌ **NEVER** use hardcoded SF Symbol strings directly (e.g., `"star.fill"`, `"plus.circle"`)
   - All symbol constants are public and available throughout the app via `import tdgCoreWidget`

2. **Adding New SF Symbols**
   - Before using any `systemImage:` or `Image(systemName:)`, check if a constant exists in `IconsRelated.swift`
   - If the constant doesn't exist, add it to the appropriate category in `IconsRelated.swift` first
   - Use descriptive names with `img` prefix (e.g., `imgPlus`, `imgTrash`, `imgCamera`)
   - Organize constants by category with MARK comments (Task State, UI Control, Media, etc.)

3. **Usage Pattern**
   ```swift
   // ❌ Don't do this
   Image(systemName: "star.fill")
   Label("Priority", systemImage: "star.fill")

   // ✅ Do this
   Image(systemName: imgPriority)
   Label("Priority", systemImage: imgPriority)
   ```

4. **Benefits**
   - Single source of truth for all icons
   - Easy to update icons globally
   - Type-safe references (compiler catches typos)
   - Better code completion and discoverability
   - Consistent naming across the codebase

5. **Existing Categories in IconsRelated.swift**
   - Task State Icons (`imgOpen`, `imgClosed`, `imgPriority`, etc.)
   - Date and Time Icons (`imgCalendarBadgePlus`, `imgClockArrowCirclepath`, etc.)
   - Information and Navigation Icons (`imgInformation`, `imgCompassCheck`, etc.)
   - Action Icons (`imgTrash`, `imgPlus`, `imgPlusCircle`, etc.)
   - History Icons (`imgUndo`, `imgRedo`, `imgStateChange`)
   - Attachment and Media Icons (`imgCamera`, `imgPhoto`, `imgDoc`, etc.)
   - UI Control Icons (`imgAddItem`, `imgPreferences`, `imgSparkles`, etc.)
   - Import/Export Icons (`imgExport`, `imgImport`, `imgStats`)
   - Settings Icons (`imgListBulletClipboard`, `imgTagCircleFill`, etc.)
   - Energy-Effort Matrix Icons (`imgBrainHeadProfile`, `imgTortoiseFill`, `imgBoltFill`)

### SwiftData Considerations

1. **CloudKit Compatibility**
   - ❌ **DO NOT** use `@Attribute(.unique)` with CloudKit - it doesn't work
   - Our project syncs via CloudKit, so avoid unique constraints

### Concurrency & Threading

1. **Actor Isolation**
   - ✅ Use `Task { @MainActor in }` instead of `DispatchQueue.main.async`
   - Better Swift 6 concurrency support
   - All managers are already `@MainActor` for UI safety

### Number Formatting

1. **Modern Formatters**
   - ✅ Use `.formatted(.number.precision(.fractionLength(2)))` instead of C-style `String(format:)`
   - Type-safe and localization-friendly
   - Example:
     ```swift
     // ❌ Old way
     Text(String(format: "%.2f", value))

     // ✅ New way
     Text(value, format: .number.precision(.fractionLength(2)))
     ```

### Collections & Iteration

1. **Array Initialization**
   - ✅ Use `x.enumerated()` directly in `ForEach`
   - ❌ Don't wrap with `Array()`: `Array(x.enumerated())`
   - Example:
     ```swift
     // ❌ Don't do this
     ForEach(Array(items.enumerated()), id: \.offset) { index, item in }

     // ✅ Do this
     ForEach(items.enumerated(), id: \.offset) { index, item in }
     ```

### Layout & Geometry

1. **Avoid Over-Using GeometryReader**
   - ❌ GeometryReader is often overused and can cause performance issues
   - ✅ Consider alternatives: `.visualEffect()`, `.containerRelativeFrame()`, or fixed frame sizes
   - Only use GeometryReader when truly necessary

2. **Frame Sizes**
   - ❌ Avoid fixed frame sizes where they don't belong
   - ✅ Let SwiftUI's layout system work naturally when possible

### Performance

1. **Font Weight**
   - Be aware: `fontWeight(.bold)` and `.bold()` don't always produce the same result
   - Prefer `.bold()` for semantic boldness

2. **Build Times**
   - ❌ Don't place many types in a single file - it increases build times
   - ✅ Organize code into focused, single-purpose files

### Rendering

1. **Image Rendering**
   - ✅ Use `ImageRenderer` for SwiftUI views instead of `UIGraphicsImageRenderer`
   - Better integration with SwiftUI

### Code Organization

- Keep files focused on a single responsibility
- Use meaningful file names that reflect the content
- Group related functionality together in directories
- Follow the existing project structure (Presentation/, Domain/, Storage/, etc.)

### Custom Colors

When using custom color extensions (like `Color.open`, `Color.priority`, `Color.closed`):
- Wrap in `Color` type when used with `.foregroundStyle()` to avoid compilation errors
- Example: `.foregroundStyle(Color.open)` not `.foregroundStyle(.open)`
