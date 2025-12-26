# Contributing to Three Daily Goals

Thanks for your interest in contributing! This is a personal project, so contributions are managed on a best-effort basis with no guaranteed response times.

## Before Contributing

1. **Read [AGENTS.md](./AGENTS.md)** - Comprehensive guide to architecture, testing conventions, and development workflow
2. **Check existing issues** - Someone might already be working on it
3. **Open an issue first** for significant changes - let's discuss the approach before you invest time

## Development Philosophy

### Test-Driven Development (TDD)

This project follows **strict test-driven development**:

1. **Write a failing test first** that demonstrates the bug or defines the expected behavior
2. Verify the test fails for the right reason
3. Implement the minimal fix to make the test pass
4. Verify the test passes
5. Refactor if needed while keeping tests green

**Never submit a PR without tests.** See [AGENTS.md - Testing Strategy](./AGENTS.md#testing-strategy) for detailed TDD workflow.

### SwiftUI Best Practices

All code must follow modern SwiftUI conventions documented in [AGENTS.md - SwiftUI Best Practices](./AGENTS.md#swiftui-best-practices):

- Use `.foregroundStyle()` instead of deprecated `.foregroundColor()`
- Use `@Observable` instead of `ObservableObject`
- All SF Symbols must be declared in `IconsRelated.swift` before use
- Use Dynamic Type fonts for accessibility
- Avoid `GeometryReader` unless truly necessary

## Pre-Commit Checklist

Before submitting a PR, ensure:

- [ ] All tests pass (`xcodebuild test` for main app, `swift test` for tdgCore package)
- [ ] No compiler warnings
- [ ] Code follows SwiftUI best practices (see AGENTS.md)
- [ ] New SF Symbols are declared in `tdgCore/Sources/tdgCoreWidget/Helpers/IconsRelated.swift`
- [ ] Schema changes include migration logic if needed (see AGENTS.md - Modifying Storage Schema)
- [ ] Added tests for all changed code
- [ ] PR title follows format: `[Component] Description`

## Pull Request Conventions

### PR Title Format

`[Component] Description`

**Examples:**
- `[CompassCheck] Fix step navigation bug`
- `[Storage] Add migration for SchemaV3_7`
- `[Widget] Update priority display`
- `[Tests] Add coverage for task state transitions`

### PR Description Should Include

- **What changed and why**
- **Which tests were added/updated**
- **Reference to related issues** (if any)
- **Screenshots/videos** (for UI changes)
- **Migration notes** (for schema changes)

## What Gets Accepted

### More Likely to Be Accepted ✅

- **Bug fixes with tests** - Especially if test demonstrates the bug first
- **Performance improvements** - With benchmarks showing improvement
- **Accessibility enhancements** - VoiceOver, Dynamic Type, etc.
- **Documentation improvements** - Code comments, AGENTS.md updates, README clarifications
- **Test coverage additions** - Tests for currently untested code
- **Small, focused changes** - Easier to review and merge

### Less Likely to Be Accepted ❌

- **Major architectural changes** - Discuss in an issue first
- **New features that deviate from core philosophy** - The app is intentionally simple
- **Changes without tests** - Non-negotiable
- **Code that doesn't follow existing patterns** - Consistency matters
- **Large PRs touching many files** - Break into smaller, logical commits
- **Features that add complexity** - This app values simplicity over features

## Running Tests

### Main App Tests

```bash
# Run all tests
xcodebuild test \
  -project "Three Daily Goals.xcodeproj" \
  -scheme "Three Daily Goals" \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"

# Run specific test class
xcodebuild test \
  -project "Three Daily Goals.xcodeproj" \
  -scheme "Three Daily Goals" \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
  -only-testing:Three_Daily_GoalsTests/TestClassName

# Run specific test method
xcodebuild test \
  -project "Three Daily Goals.xcodeproj" \
  -scheme "Three Daily Goals" \
  -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
  -only-testing:Three_Daily_GoalsTests/TestClassName/testMethodName
```

### Swift Package Tests (tdgCore)

```bash
cd tdgCore
swift test
swift build
```

### Share Extension Tests

```bash
./run_share_extension_tests.sh
```

See [SHARE_EXTENSION_TESTING.md](./SHARE_EXTENSION_TESTING.md) for comprehensive share extension testing guide.

## Common Contribution Workflows

### Adding a New Compass Check Step

See [AGENTS.md - Adding a New Compass Check Step](./AGENTS.md#adding-a-new-compass-check-step)

1. Create new step class conforming to `CompassCheckStep` protocol
2. Add to `CompassCheckManager.DEFAULT_STEPS` array
3. Create corresponding view if needed
4. Add preference toggle
5. **Write tests first** for step execution and state management

### Modifying Storage Schema

See [AGENTS.md - Modifying Storage Schema](./AGENTS.md#modifying-storage-schema)

1. Copy latest schema file (e.g., `SchemaV3_6.swift`) to new version
2. Make model changes in new schema version
3. Add migration in `TDGMigrationPlan.stages` array
4. **Write migration tests** to verify data transformation
5. Update `SchemaLatest` typealias
6. Test migration with production data

### Fixing a Bug

1. **Write a failing test** that demonstrates the bug
2. Verify the test fails
3. Fix the bug with minimal changes
4. Verify the test passes
5. Check for edge cases and add tests for them
6. Submit PR with test evidence

## Development Environment

### Required Tools

- Xcode 15.0+
- macOS 14.0+ (for building)
- iOS Simulator or device with iOS 18.0+
- Swift 6.0

### Recommended Tools

- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - Code formatting (config in `.swift-format`)
- SF Symbols app - For browsing system icons

## Code Style

This project uses `.swift-format` for code formatting. Key conventions:

- **Indentation:** 2 spaces (not tabs)
- **Line length:** 100 characters
- **Manager pattern:** Use `@Observable` classes, not ViewModels
- **Time abstraction:** Use `TimeProvider` protocol, never `Date()` directly
- **SF Symbols:** Declare all symbols in `IconsRelated.swift` before use

See [AGENTS.md - SwiftUI Best Practices](./AGENTS.md#swiftui-best-practices) for comprehensive style guide.

## Code of Conduct

**Be respectful.** This is a small project focused on helping people with task overwhelm. Let's keep interactions:

- **Kind** - Assume good intentions
- **Constructive** - Focus on improving the project
- **Patient** - Remember this is maintained on a best-effort basis
- **Inclusive** - Welcome contributors of all skill levels

Unacceptable behavior:
- Harassment or discriminatory language
- Trolling or inflammatory comments
- Demanding immediate responses or features
- Violations of privacy

## Questions?

- **Architecture questions:** Read [AGENTS.md](./AGENTS.md) first
- **Feature ideas:** Open an issue with the "enhancement" label
- **General questions:** Open an issue with the "question" label
- **Bugs:** Open an issue with the "bug" label and include reproduction steps

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).

---

**Thank you for considering contributing to Three Daily Goals!** Every contribution, whether it's a bug fix, documentation improvement, or feature enhancement, helps make this project better for everyone trying to escape task overwhelm.
