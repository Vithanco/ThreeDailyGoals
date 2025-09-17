# Share Extension Test Harness

This document describes the comprehensive test harness created for testing the Three Daily Goals share extensions. The test harness allows you to test share extension functionality without requiring the full extension environment.

## Overview

The share extension test harness consists of several components organized by test type:

### Non-GUI Tests (Three_Daily_GoalsTests)
1. **TestShareFlow.swift** - Tests the payload resolution logic (Swift Testing)
2. **ShareExtensionTestUtilities.swift** - Utility functions and mock objects (Swift Testing)

### UI Tests (Three_Daily_GoalsUITests)
3. **TestShareExtensionView.swift** - Tests the view initialization and task creation (XCTest)
4. **TestShareExtensionIntegration.swift** - Tests the complete workflow integration (XCTest)
5. **TestShareExtensionHarness.swift** - Demonstrates how to use the test utilities (XCTest)

### Test Runner
6. **run_share_extension_tests.sh** - Script to run all share extension tests

## Test Organization

The tests are organized into two categories based on their requirements:

### Non-GUI Tests (Three_Daily_GoalsTests)
- **Purpose**: Test pure logic without UI dependencies
- **Framework**: Swift Testing (Swift 6)
- **Files**: `TestShareFlow.swift`, `ShareExtensionTestUtilities.swift`
- **Why**: These tests don't need UI context and can run faster

### UI Tests (Three_Daily_GoalsUITests)
- **Purpose**: Test UI components and complete workflows
- **Framework**: XCTest (traditional Apple testing)
- **Files**: `TestShareExtensionView.swift`, `TestShareExtensionIntegration.swift`, `TestShareExtensionHarness.swift`
- **Why**: These tests require UI context and SwiftUI view initialization

## Swift 6 & Swift Testing Compatibility

This test harness is fully compatible with Swift 6 and uses the appropriate testing framework for each test type:

### Non-GUI Tests (Swift Testing)
- Uses `@Suite` and `@Test` annotations
- Uses `#expect()` for assertions instead of `XCTAssert`
- Uses `#expect(Bool(false))` for error conditions instead of `Issue.record()`
- Follows Swift 6 naming conventions (avoiding reserved keywords like `extension`)
- Uses proper concurrency patterns with `@MainActor` and `@unchecked Sendable`
- Implements correct `NSItemProvider` method signatures with proper completion handlers

### UI Tests (XCTest)
- Uses `XCTestCase` class-based tests
- Uses `XCTAssert` family of assertions
- Compatible with Xcode's UI test infrastructure
- Supports async/await patterns
- Uses traditional `DispatchQueue` for async operations (no actor isolation issues)
- Proper `NSItemProvider` method signatures with optional completion handlers

## Architecture

### Share Extension Components

The share extension has three main components:

1. **ShareViewController** - The main view controller that handles the extension lifecycle
2. **ShareExtensionView** - The SwiftUI view that presents the share interface
3. **ShareFlow** - The logic that resolves different types of shared content

### Test Strategy

The test harness uses a **unit testing approach** rather than UI testing because:

- Share extensions run in a separate process and are difficult to test with UI tests
- Unit tests are faster and more reliable
- We can test the core logic without the extension environment
- Mock objects allow us to simulate various share scenarios

## Test Files

### 1. TestShareFlow.swift

Tests the `ShareFlow.resolve()` method which determines what type of content was shared:

```swift
@Test
func testResolveURLPayload() async throws {
    let mockProvider = MockNSItemProvider()
    mockProvider.mockURL = URL(string: "https://example.com")!
    mockProvider.registeredTypeIdentifiers = [UTType.url.identifier]
    
    let payload = try await ShareFlow.resolve(from: mockProvider)
    
    #expect(payload != nil)
    if case .url(let urlString) = payload {
        #expect(urlString == "https://example.com")
    }
}
```

**What it tests:**
- URL resolution
- Text resolution
- File attachment resolution
- HTML content detection
- Priority ordering (URL > attachment > text)
- Error handling

### 2. TestShareExtensionView.swift

Tests the `ShareExtensionView` initialization and task creation:

```swift
@Test
func testInitWithShortText() throws {
    let shareView = ShareExtensionView(text: "Short task")
    
    #expect(shareView.item.title == "Short task")
    #expect(shareView.item.details.isEmpty)
}
```

**What it tests:**
- View initialization with different content types
- Task creation and saving
- File attachment handling
- Edge cases (empty text, special characters)

### 3. TestShareExtensionIntegration.swift

Tests the complete share extension workflow:

```swift
@Test
func testCompleteTextShareWorkflow() async throws {
    let mockProvider = ShareExtensionTestUtilities.createTestScenario(.shortText)
    let result = try await processShareWorkflow(provider: mockProvider)
    
    #expect(result != nil)
    #expect(result?.title == "Short task")
}
```

**What it tests:**
- End-to-end workflow
- Multiple share operations
- Error scenarios
- ShareViewController integration

### 4. ShareExtensionTestUtilities.swift

Provides utility functions and mock objects:

```swift
// Create a mock provider
let provider = ShareExtensionTestUtilities.createMockProvider(
    text: "Test content",
    typeIdentifiers: [UTType.plainText.identifier]
)

// Create test scenarios
let provider = ShareExtensionTestUtilities.createTestScenario(.shortText)

// Assert task creation
ShareExtensionTestUtilities.assertTaskCreated(
    task,
    expectedTitle: "Expected Title",
    expectedAttachmentCount: 1
)
```

## Usage Examples

### Basic Text Share Test

```swift
@Test
func testBasicTextShare() async throws {
    // Create mock provider
    let provider = ShareExtensionTestUtilities.createTestScenario(.shortText)
    
    // Process the share workflow
    let task = try await processShareWorkflow(provider: provider)
    
    // Assert results
    ShareExtensionTestUtilities.assertTaskCreated(
        task!,
        expectedTitle: "Short task",
        expectedAttachmentCount: 0
    )
}
```

### File Attachment Test

```swift
@Test
func testFileAttachment() async throws {
    // Create mock provider with file
    let provider = ShareExtensionTestUtilities.createTestScenario(.fileAttachment(.plainText))
    
    // Process the share workflow
    let task = try await processShareWorkflow(provider: provider)
    
    // Assert results
    #expect(task?.title == "Review File")
    #expect(task?.attachments?.count == 1)
    
    if let attachment = task?.attachments?.first {
        ShareExtensionTestUtilities.assertAttachmentCreated(
            attachment,
            expectedFilename: "test.txt",
            expectedUTI: UTType.plainText.identifier
        )
    }
}
```

### Error Handling Test

```swift
@Test
func testErrorHandling() async throws {
    // Create provider that will throw an error
    let provider = ShareExtensionTestUtilities.createTestScenario(
        .error(NSError(domain: "TestError", code: -1))
    )
    
    // Process the share workflow
    let task = try await processShareWorkflow(provider: provider)
    
    // Assert error handling
    #expect(task == nil, "Should return nil for error scenarios")
}
```

## Test Scenarios

The test harness supports various scenarios:

### ShareTestScenario Enum

- `.shortText` - Text under 30 characters
- `.longText` - Text over 30 characters (becomes details)
- `.url` - URL sharing
- `.htmlText` - HTML content (converted to attachment)
- `.fileAttachment(TestFileType)` - File attachments
- `.dataAttachment(Data, String, UTType)` - Custom data
- `.error(Error)` - Error scenarios
- `.unsupportedType` - Unsupported content types

### TestFileType Enum

- `.plainText` - Plain text files
- `.html` - HTML files
- `.json` - JSON files
- `.markdown` - Markdown files
- `.csv` - CSV files

## Running Tests

### Using the Test Script

```bash
./run_share_extension_tests.sh
```

This script will:
1. Verify all test files exist
2. Run all share extension tests
3. Provide a summary of results
4. Show usage tips

### Using Xcode

1. Open the project in Xcode
2. Select the test target
3. Run tests for specific files:
   - `TestShareFlow`
   - `TestShareExtensionView`
   - `TestShareExtensionIntegration`
   - `TestShareExtensionHarness`

### Using Command Line

```bash
xcodebuild test \
    -project "Three Daily Goals.xcodeproj" \
    -scheme "Three Daily Goals" \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=latest" \
    -only-testing:Three_Daily_GoalsTests/TestShareFlow
```

## Mock Objects

### MockNSItemProvider

A mock implementation of `NSItemProvider` that allows you to simulate different types of shared content:

```swift
let provider = MockNSItemProvider()
provider.mockURL = URL(string: "https://example.com")
provider.mockText = "Test text"
provider.mockFileURL = tempFileURL
provider.mockError = someError
provider.registeredTypeIdentifiers = [UTType.url.identifier]
```

### Key Methods

- `loadItem(forTypeIdentifier:options:completionHandler:)` - Simulates item loading
- `loadDataRepresentation(forTypeIdentifier:completionHandler:)` - Simulates data loading
- `loadFileRepresentation(forTypeIdentifier:completionHandler:)` - Simulates file loading
- `hasItemConformingToTypeIdentifier(_:)` - Checks type support

## Best Practices

### 1. Use Test Utilities

Always use the provided test utilities instead of creating mocks manually:

```swift
// Good
let provider = ShareExtensionTestUtilities.createTestScenario(.shortText)

// Avoid
let provider = MockNSItemProvider()
provider.mockText = "Short task"
provider.registeredTypeIdentifiers = [UTType.plainText.identifier]
```

### 2. Clean Up Resources

Always clean up temporary files:

```swift
let tempURL = ShareExtensionTestUtilities.createTempFile(content: "test", extension: "txt")
defer {
    ShareExtensionTestUtilities.cleanupTempFile(tempURL)
}
```

### 3. Use Assertion Helpers

Use the provided assertion helpers for consistent testing:

```swift
ShareExtensionTestUtilities.assertTaskCreated(
    task,
    expectedTitle: "Expected Title",
    expectedAttachmentCount: 1
)
```

### 4. Test Edge Cases

Include tests for edge cases:

- Empty content
- Very long content
- Special characters
- Error scenarios
- Unsupported types

### 5. Performance Testing

For performance-critical code, include performance tests:

```swift
@Test
func testShareExtensionPerformance() async throws {
    let operationCount = 50
    // ... test multiple operations
    #expect(duration < 5.0, "Should complete within 5 seconds")
}
```

## Troubleshooting

### Common Issues

1. **Tests fail with "MockError"**
   - Check that you're setting the correct `registeredTypeIdentifiers`
   - Ensure the mock provider has the expected data

2. **File cleanup issues**
   - Always use `ShareExtensionTestUtilities.cleanupTempFile()`
   - Check that temp files are being created in the correct location

3. **Async test failures**
   - Ensure you're using `async throws` for test methods
   - Use `await` when calling async functions

### Debug Tips

1. **Print mock provider state**:
   ```swift
   print("Provider types: \(provider.registeredTypeIdentifiers)")
   print("Provider URL: \(provider.mockURL)")
   ```

2. **Verify task creation**:
   ```swift
   print("Created task: \(task.title), \(task.details)")
   print("Attachments: \(task.attachments?.count ?? 0)")
   ```

3. **Check file content**:
   ```swift
   if let attachment = task.attachments?.first {
       print("Attachment: \(attachment.filename), \(attachment.byteSize) bytes")
   }
   ```

## Extending the Test Harness

### Adding New Test Scenarios

1. Add new cases to `ShareTestScenario` enum
2. Update `ShareExtensionTestUtilities.createTestScenario()`
3. Add corresponding tests

### Adding New File Types

1. Add new cases to `TestFileType` enum
2. Update `ShareExtensionTestUtilities.createTestData()`
3. Add tests for the new file type

### Adding New Assertions

1. Add new assertion methods to `ShareExtensionTestUtilities`
2. Use consistent naming: `assert[Component][Action]()`
3. Include helpful error messages

## Conclusion

The share extension test harness provides a comprehensive way to test share extension functionality without requiring the full extension environment. It uses unit testing principles with mock objects to simulate various share scenarios and verify that the extension correctly processes different types of content.

The test harness is designed to be:
- **Comprehensive** - Covers all major functionality
- **Reliable** - Uses deterministic mock objects
- **Fast** - Unit tests run quickly
- **Maintainable** - Well-organized with utility functions
- **Extensible** - Easy to add new test scenarios

Use this test harness to ensure your share extensions work correctly across all supported content types and scenarios.
