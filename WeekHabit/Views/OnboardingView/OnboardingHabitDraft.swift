//
//  OnboardingHabitDraft.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingHabitDraft: Identifiable {
    var id = UUID()
    var title: String
    var iconName: String = HabitAppearance.defaultIconName
    var colorHex: String = HabitAppearance.defaultColorHex
    var daysPerWeek: Int = 5
    var trackingKind: HabitTrackingKind = .check
    var measurementUnit: HabitMeasurementUnit = .none
    var targetValuePerSession: Double = 1

    var color: Color {
        HabitAppearance.color(for: colorHex)
    }

    var frequencyText: String {
        "\(daysPerWeek)d/sem"
    }

    func makeHabit() -> Habit {
        Habit(
            title: title,
            iconName: iconName,
            colorHex: colorHex,
            targetDaysPerWeek: daysPerWeek,
            activeDaysOfWeek: Set(Weekday.ordered),
            trackingKind: trackingKind,
            measurementUnit: measurementUnit,
            targetValuePerSession: targetValuePerSession,
            scheduleKind: .timesPerWeek
        )
    }

    static func from(_ template: StarterHabitTemplate) -> OnboardingHabitDraft {
        OnboardingHabitDraft(
            title: template.title,
            iconName: template.iconName,
            colorHex: template.colorHex,
            daysPerWeek: template.daysPerWeek,
            trackingKind: template.trackingKind,
            measurementUnit: template.measurementUnit,
            targetValuePerSession: template.targetValuePerSession
        )
    }
}
