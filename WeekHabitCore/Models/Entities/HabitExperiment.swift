//
//  HabitExperiment.swift
//  WeekHabit
//

import Foundation
import SwiftData

enum HabitExperimentStatus: String, Codable {
    case active
    case kept
    case reverted
    case cancelled
}

@Model
final class HabitExperiment {
    var id: UUID
    var habitID: UUID
    var habitTitle: String

    var originalTargetDaysPerWeek: Int
    var originalActiveDaysOfWeekRaw: [Int]

    var experimentTargetDaysPerWeek: Int
    var experimentActiveDaysOfWeekRaw: [Int]
    var suggestedStartHour: Int?

    var baselineConsistency: Double
    var startedAt: Date
    var endsAt: Date
    var resolvedAt: Date?
    var statusRaw: String

    var originalActiveDaysOfWeek: Set<Weekday> {
        get { Set(originalActiveDaysOfWeekRaw.compactMap { Weekday(rawValue: $0) }) }
        set { originalActiveDaysOfWeekRaw = newValue.map(\.rawValue) }
    }

    var experimentActiveDaysOfWeek: Set<Weekday> {
        get { Set(experimentActiveDaysOfWeekRaw.compactMap { Weekday(rawValue: $0) }) }
        set { experimentActiveDaysOfWeekRaw = newValue.map(\.rawValue) }
    }

    var status: HabitExperimentStatus {
        get { HabitExperimentStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    init(
        habit: Habit,
        experimentTargetDaysPerWeek: Int,
        experimentActiveDaysOfWeek: Set<Weekday>,
        suggestedStartHour: Int?,
        baselineConsistency: Double,
        startedAt: Date = .now
    ) {
        self.id = UUID()
        self.habitID = habit.id
        self.habitTitle = habit.title
        self.originalTargetDaysPerWeek = habit.targetDaysPerWeek
        self.originalActiveDaysOfWeekRaw = habit.activeDaysOfWeek.map(\.rawValue)
        self.experimentTargetDaysPerWeek = experimentTargetDaysPerWeek
        self.experimentActiveDaysOfWeekRaw = experimentActiveDaysOfWeek.map(\.rawValue)
        self.suggestedStartHour = suggestedStartHour
        self.baselineConsistency = baselineConsistency
        self.startedAt = AppCalendar.startOfDay(for: startedAt)
        self.endsAt = AppCalendar.current.date(
            byAdding: .day,
            value: 7,
            to: AppCalendar.startOfDay(for: startedAt)
        ) ?? startedAt
        self.resolvedAt = nil
        self.statusRaw = HabitExperimentStatus.active.rawValue
    }
}
