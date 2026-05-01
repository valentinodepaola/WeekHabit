//
//  HabitSchema.swift
//  WeekHabit
//
//  Versioned schema declaration. When the persisted shape of `Habit` or
//  `HabitEntry` changes, add a new `SchemaV2`, then a `MigrationStage` here.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self]
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self]
    }
}

enum HabitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        ]
    }
}
