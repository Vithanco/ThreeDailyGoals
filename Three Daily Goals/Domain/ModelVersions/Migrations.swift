//
//  Migrations.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 28/01/2024.
//
import  SwiftData

import Foundation


typealias SchemaLatest = SchemaV2_1

enum TDGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV2_1.self]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self)
    static let migrateV2toV2_1 = MigrationStage.lightweight(fromVersion: SchemaV2.self,
        toVersion: SchemaV2_1.self)
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV2_1]
    }
}



