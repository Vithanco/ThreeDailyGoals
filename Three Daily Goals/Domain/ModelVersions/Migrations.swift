import Foundation
//
//  Migrations.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//
@preconcurrency import SwiftData

public typealias SchemaLatest = SchemaV3_6

enum TDGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV3_1.self, SchemaV3_2.self, SchemaV3_3.self, SchemaV3_4.self, SchemaV3_5.self, SchemaV3_6.self]
    }

    static let migrateV3_1toV3_2 = MigrationStage.lightweight(
        fromVersion: SchemaV3_1.self,
        toVersion: SchemaV3_2.self
    )

    static let migrateV3_2toV3_3 = MigrationStage.custom(
        fromVersion: SchemaV3_2.self,
        toVersion: SchemaV3_3.self,
        willMigrate: { context in
            let oldTasks = try context.fetch(FetchDescriptor<SchemaV3_2.TaskItem>())

            for oldTask in oldTasks {

                guard let jsonData = try? JSONEncoder().encode(oldTask),
                    let jsonString = String(data: jsonData, encoding: .utf8)
                else {
                    // If we can't encode the old task, skip it and continue with migration
                    // This prevents the app from crashing due to corrupted data
                    let taskTitle = oldTask._title ?? "Unknown"
                    print("Warning: Failed to encode TaskItem during migration, skipping: \(taskTitle)")
                    
                    // Report this data loss to the user
                    reportMigrationIssue(
                        "Some tasks could not be migrated and were skipped during the database update.",
                        details: "Task: '\(taskTitle)' was skipped due to data corruption."
                    )
                    continue
                }
                print("Migrating TaskItem:\n\(jsonString)")

                var newTask = SchemaV3_3.TaskItem()  // V3_3 version
                newTask.allTags = oldTask._tags
                newTask._details = oldTask._details
                newTask._title = oldTask._title
                newTask._url = oldTask._url
                newTask._state = oldTask._state
                if let comments = oldTask.comments {
                    newTask.comments = []
                    for comment in comments {
                        let newComment = SchemaV3_3.Comment(old: comment)
                        newTask.comments?.append(newComment)
                    }
                }
                newTask.eventId = oldTask.eventId
                newTask.dueDate = oldTask.dueDate
                newTask.uuid = oldTask.uuid
                newTask.created = oldTask.created
                newTask.changed = oldTask.changed
                newTask.closed = oldTask.closed
                context.insert(newTask)
            }
            try? context.save()
        },
        didMigrate: { context in
            print("Migration from V3.2 to V3.3 completed successfully.")
        }
    )

    static let migrateV3_3toV3_4 = MigrationStage.custom(
        fromVersion: SchemaV3_3.self,
        toVersion: SchemaV3_4.self,
        willMigrate: { context in
            let oldTasks = try context.fetch(FetchDescriptor<SchemaV3_3.TaskItem>())

            for oldTask in oldTasks {
                var newTask = SchemaV3_4.TaskItem()
                newTask.allTagsString = oldTask.allTags.joined(separator: ",")
                newTask._details = oldTask._details
                newTask._title = oldTask._title
                newTask._url = oldTask._url
                newTask._state = oldTask._state
                if let comments = oldTask.comments {
                    newTask.comments = []
                    for comment in comments {
                        let newComment = SchemaV3_4.Comment(old: comment)
                        newTask.comments?.append(newComment)
                    }
                }
                newTask.eventId = oldTask.eventId
                newTask.dueDate = oldTask.dueDate
                newTask.uuid = oldTask.uuid
                newTask.created = oldTask.created
                newTask.changed = oldTask.changed
                newTask.closed = oldTask.closed
                context.insert(newTask)
            }
            try? context.save()
        },
        didMigrate: { context in
            print("Migration from V3.3 to V3.4 completed successfully.")
        }
    )

    static let migrateV3_4toV3_5 = MigrationStage.lightweight(
        fromVersion: SchemaV3_4.self,
        toVersion: SchemaV3_5.self
    )
    
    static let migrateV3_5toV3_6 = MigrationStage.lightweight(
            fromVersion: SchemaV3_5.self,
            toVersion: SchemaV3_6.self
        )

    static var stages: [MigrationStage] {
        [migrateV3_1toV3_2, migrateV3_2toV3_3, migrateV3_3toV3_4, migrateV3_4toV3_5, migrateV3_5toV3_6]
    }
}
