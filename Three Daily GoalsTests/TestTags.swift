import Foundation
import Testing
@testable import Three_Daily_Goals
@testable import tdgCoreMain

@Suite
@MainActor
struct TestTags {
    
    var appComps: AppComponents!
    var dataManager: DataManager!
    
    init() {
        appComps = setupApp(isTesting: true)
        dataManager = appComps.dataManager
    }
    
    // MARK: - Test Tag Addition
    
    @Test
    func testAddTag_CreatesSingleComment() throws {
        // Given: A task with no tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // Verify initial state
        #expect(task.tags.isEmpty, "Task should start with no tags")
        #expect(task.comments?.count == 0, "Task should start with no comments")
        
        // When: Adding a tag
        task.addTag("important")
        
        // Then: Should have exactly one tag and one comment
        #expect(task.tags.count == 1, "Task should have exactly one tag")
        #expect(task.tags.contains("important"), "Task should contain the added tag")
        #expect(task.comments?.count == 1, "Task should have exactly one comment")
        
        // Verify the comment content
        let comment = task.comments?.first
        #expect(comment?.text == "Added tag: important", "Comment should show 'Added tag: important'")
        #expect(comment?.icon == "tag", "Comment should have tag icon")
    }
    
    @Test
    func testAddMultipleTags_CreatesCorrectComments() throws {
        // Given: A task with no tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // When: Adding multiple tags
        task.addTag("urgent")
        task.addTag("work")
        task.addTag("personal")
        
        // Then: Should have all tags and correct number of comments
        #expect(task.tags.count == 3, "Task should have exactly three tags")
        #expect(task.tags.contains("urgent"), "Task should contain 'urgent' tag")
        #expect(task.tags.contains("work"), "Task should contain 'work' tag")
        #expect(task.tags.contains("personal"), "Task should contain 'personal' tag")
        #expect(task.comments?.count == 3, "Task should have exactly three comments")
        
        // Verify all comments are present
        let commentTexts = task.comments?.compactMap { $0.text } ?? []
        #expect(commentTexts.contains("Added tag: urgent"), "Should have comment for 'urgent' tag")
        #expect(commentTexts.contains("Added tag: work"), "Should have comment for 'work' tag")
        #expect(commentTexts.contains("Added tag: personal"), "Should have comment for 'personal' tag")
    }
    
    @Test
    func testAddDuplicateTag_DoesNotCreateComment() throws {
        // Given: A task with an existing tag
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        task.addTag("existing")
        
        let initialCommentCount = task.comments?.count ?? 0
        
        // When: Adding the same tag again
        task.addTag("existing")
        
        // Then: Should not create additional comments
        #expect(task.comments?.count == initialCommentCount, "Adding duplicate tag should not create new comment")
        #expect(task.tags.count == 1, "Task should still have only one tag")
    }
    
    // MARK: - Test Tag Removal
    
    @Test
    func testRemoveTag_CreatesSingleComment() throws {
        // Given: A task with a tag
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        task.addTag("removable")
        
        let initialCommentCount = task.comments?.count ?? 0
        
        // When: Removing the tag
        task.removeTag("removable")
        
        // Then: Should have no tags and one additional comment
        #expect(task.tags.isEmpty, "Task should have no tags after removal")
        #expect(task.comments?.count == initialCommentCount + 1, "Task should have one additional comment")
        
        // Verify the removal comment
        let removalComment = task.comments?.last
        #expect(removalComment?.text == "Removed tag: removable", "Comment should show 'Removed tag: removable'")
        #expect(removalComment?.icon == "tag", "Comment should have tag icon")
    }
    
    @Test
    func testRemoveNonExistentTag_DoesNotCreateComment() throws {
        // Given: A task with no tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        let initialCommentCount = task.comments?.count ?? 0
        
        // When: Removing a non-existent tag
        task.removeTag("nonexistent")
        
        // Then: Should not create additional comments
        #expect(task.comments?.count == initialCommentCount, "Removing non-existent tag should not create new comment")
        #expect(task.tags.isEmpty, "Task should still have no tags")
    }
    
    // MARK: - Test Direct Tags Assignment
    
    @Test
    func testDirectTagsAssignment_CreatesCorrectComments() throws {
        // Given: A task with no tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // When: Directly assigning tags
        task.tags = ["direct", "assignment", "test"]
        
        // Then: Should have all tags and correct comments
        #expect(task.tags.count == 3, "Task should have exactly three tags")
        #expect(task.comments?.count == 3, "Task should have exactly three comments")
        
        // Verify all comments are present
        let commentTexts = task.comments?.compactMap { $0.text } ?? []
        #expect(commentTexts.contains("Added tag: direct"), "Should have comment for 'direct' tag")
        #expect(commentTexts.contains("Added tag: assignment"), "Should have comment for 'assignment' tag")
        #expect(commentTexts.contains("Added tag: test"), "Should have comment for 'test' tag")
    }
    
    @Test
    func testTagsReplacement_CreatesCorrectComments() throws {
        // Given: A task with existing tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        task.tags = ["old1", "old2", "old3"]
        
        let initialCommentCount = task.comments?.count ?? 0
        
        // When: Replacing all tags
        task.tags = ["new1", "new2"]
        
        // Then: Should have new tags and additional comments for changes
        #expect(task.tags.count == 2, "Task should have exactly two tags")
        #expect(task.tags.contains("new1"), "Task should contain 'new1' tag")
        #expect(task.tags.contains("new2"), "Task should contain 'new2' tag")
        
        // Should have comments for both removals and additions
        let commentTexts = task.comments?.compactMap { $0.text } ?? []
        #expect(commentTexts.contains("Removed tag: old1"), "Should have comment for removing 'old1'")
        #expect(commentTexts.contains("Removed tag: old2"), "Should have comment for removing 'old2'")
        #expect(commentTexts.contains("Removed tag: old3"), "Should have comment for removing 'old3'")
        #expect(commentTexts.contains("Added tag: new1"), "Should have comment for adding 'new1'")
        #expect(commentTexts.contains("Added tag: new2"), "Should have comment for adding 'new2'")
    }
    
    // MARK: - Test Edge Cases
    
    @Test
    func testEmptyTagsArray_DoesNotCreateComments() throws {
        // Given: A task with existing tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        task.tags = ["existing"]
        
        let initialCommentCount = task.comments?.count ?? 0
        
        // When: Setting empty tags array
        task.tags = []
        
        // Then: Should have no tags and one removal comment
        #expect(task.tags.isEmpty, "Task should have no tags")
        #expect(task.comments?.count == initialCommentCount + 1, "Task should have one additional comment")
        
        let removalComment = task.comments?.last
        #expect(removalComment?.text == "Removed tag: existing", "Comment should show 'Removed tag: existing'")
    }
    
    @Test
    func testWhitespaceOnlyTags_AreFilteredOut() throws {
        // Given: A task with no tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        #expect(task.comments?.count == 0, "Task should have exactly zero comments initially")
        
        // When: Adding tags with whitespace
        task.tags = ["  valid  ", "", "   ", "\t\n", "another"]
        
        // Then: Should only have valid tags (whitespace trimmed, empty ones filtered)
        #expect(task.tags.count == 2, "Task should have exactly two tags")
        #expect(task.tags.contains("valid"), "Task should contain 'valid' tag (whitespace trimmed)")
        #expect(task.tags.contains("another"), "Task should contain 'another' tag")
        #expect(task.comments?.count == 2, "Task should have exactly two comments")
    }
    
    // MARK: - Test Performance
    
    @Test
    func testTagOperations_Performance() throws {
        // Given: A task with no tags
        let task = TaskItem(title: "Test Task")
        dataManager.modelContext.insert(task)
        
        // When: Performing multiple tag operations
        let startTime = Date()
        
        for i in 0..<100 {
            task.addTag("tag\(i)")
        }
        
        for i in 0..<50 {
            task.removeTag("tag\(i)")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then: Should complete within reasonable time
        #expect(duration < 1.0, "Tag operations should complete within 1 second")
        #expect(task.tags.count == 50, "Task should have exactly 50 tags after operations")
        #expect(task.comments?.count == 150, "Task should have exactly 150 comments (100 additions + 50 removals)")
    }
}
