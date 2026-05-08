//
//  HabitSchema.swift
//  WeekHabit
//
//  Versioned schema declaration. When the persisted shape of `Habit` or
//  `HabitEntry` changes, add a new schema, then a `MigrationStage` here.
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

enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self]
    }
}

enum SchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(4, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self]
    }
}

enum SchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(5, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self]
    }
}

enum SchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(6, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self]
    }
}

enum SchemaV7: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(7, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self]
    }
}

enum SchemaV8: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(8, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self]
    }
}

enum HabitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self,
            SchemaV3.self,
            SchemaV4.self,
            SchemaV5.self,
            SchemaV6.self,
            SchemaV7.self,
            SchemaV8.self
        ]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
            .lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self),
            .lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self),
            .lightweight(fromVersion: SchemaV4.self, toVersion: SchemaV5.self),
            .lightweight(fromVersion: SchemaV5.self, toVersion: SchemaV6.self),
            .lightweight(fromVersion: SchemaV6.self, toVersion: SchemaV7.self),
            .lightweight(fromVersion: SchemaV7.self, toVersion: SchemaV8.self)
        ]
    }
}
