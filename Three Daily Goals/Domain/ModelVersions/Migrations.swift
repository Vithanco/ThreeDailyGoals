import Foundation
//
//  Migrations.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//
@preconcurrency import SwiftData

public typealias SchemaLatest = SchemaV3_4

enum TDGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV3_1.self, SchemaV3_2.self, SchemaV3_3.self, SchemaV3_4.self]
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
                    fatalError()
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
                newTask.tags = oldTask.allTags
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

    static var stages: [MigrationStage] {
        [migrateV3_1toV3_2, migrateV3_2toV3_3, migrateV3_3toV3_4]
    }
}
