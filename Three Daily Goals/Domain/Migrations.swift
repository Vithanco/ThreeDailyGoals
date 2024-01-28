//
//  Migrations.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//
import  SwiftData

import Foundation


typealias SchemaLatest = SchemaV2

enum TDGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: nil
    )
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
}



