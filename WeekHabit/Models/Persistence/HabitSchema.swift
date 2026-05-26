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
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self]
    }
}

enum SchemaV9: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(9, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self]
    }
}

enum SchemaV10: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(10, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self]
    }
}

enum SchemaV11: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(11, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self]
    }
}

enum SchemaV12: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(12, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self]
    }
}

enum SchemaV13: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(13, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self, PlanMilestone.self]
    }
}

enum SchemaV14: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(14, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, HabitEntry.self, HabitExperiment.self, FocusSession.self, Plan.self, StreakFreeze.self, PlanMilestone.self]
    }
}

enum SchemaV15: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(15, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Habit.self,
            HabitEntry.self,
            HabitExperiment.self,
            FocusSession.self,
            Plan.self,
            StreakFreeze.self,
            PlanMilestone.self,
            WeeklyReview.self,
            WeeklyReviewDecision.self
        ]
    }
}

enum SchemaV16: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(16, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Habit.self,
            HabitEntry.self,
            HabitExperiment.self,
            FocusSession.self,
            Plan.self,
            StreakFreeze.self,
            PlanMilestone.self,
            WeeklyReview.self,
            WeeklyReviewDecision.self
        ]
    }
}

enum SchemaV17: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(17, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Habit.self,
            HabitEntry.self,
            HabitExperiment.self,
            FocusSession.self,
            Plan.self,
            StreakFreeze.self,
            PlanMilestone.self,
            WeeklyReview.self,
            WeeklyReviewDecision.self
        ]
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
            SchemaV8.self,
            SchemaV9.self,
            SchemaV10.self,
            SchemaV11.self,
            SchemaV12.self,
            SchemaV13.self,
            SchemaV14.self,
            SchemaV15.self,
            SchemaV16.self,
            SchemaV17.self
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
            .lightweight(fromVersion: SchemaV7.self, toVersion: SchemaV8.self),
            .lightweight(fromVersion: SchemaV8.self, toVersion: SchemaV9.self),
            .lightweight(fromVersion: SchemaV9.self, toVersion: SchemaV10.self),
            .lightweight(fromVersion: SchemaV10.self, toVersion: SchemaV11.self),
            .lightweight(fromVersion: SchemaV11.self, toVersion: SchemaV12.self),
            .lightweight(fromVersion: SchemaV12.self, toVersion: SchemaV13.self),
            .lightweight(fromVersion: SchemaV13.self, toVersion: SchemaV14.self),
            .lightweight(fromVersion: SchemaV14.self, toVersion: SchemaV15.self),
            .lightweight(fromVersion: SchemaV15.self, toVersion: SchemaV16.self),
            .lightweight(fromVersion: SchemaV16.self, toVersion: SchemaV17.self)
        ]
    }
}
