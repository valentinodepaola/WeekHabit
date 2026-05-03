//
//  StarterHabitTemplate.swift
//  WeekHabit
//

import SwiftUI

struct StarterHabitTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let category: HabitCategory
    let daysPerWeek: Int
    let trackingKind: HabitTrackingKind
    let measurementUnit: HabitMeasurementUnit
    let targetValuePerSession: Double

    var subtitle: String {
        "\(category.displayTitle) · \(daysPerWeek)d/sem"
    }

    var icon: String {
        OnboardingAreaOption.all.first { $0.category == category }?.icon ?? category.icon
    }

    var color: Color {
        OnboardingAreaOption.all.first { $0.category == category }?.color ?? category.color
    }

    func makeHabit() -> Habit {
        Habit(
            title: title,
            category: category,
            targetDaysPerWeek: daysPerWeek,
            activeDaysOfWeek: Set(Weekday.ordered),
            trackingKind: trackingKind,
            measurementUnit: measurementUnit,
            targetValuePerSession: targetValuePerSession,
            scheduleKind: .timesPerWeek
        )
    }

    static let defaultID = "meditate"

    static let all: [StarterHabitTemplate] = [
        StarterHabitTemplate(
            id: "water",
            title: "Beber 2L de agua",
            category: .health,
            daysPerWeek: 7,
            trackingKind: .check,
            measurementUnit: .none,
            targetValuePerSession: 1
        ),
        StarterHabitTemplate(
            id: "meditate",
            title: "Meditar 10 min",
            category: .personal,
            daysPerWeek: 7,
            trackingKind: .quantity,
            measurementUnit: .minutes,
            targetValuePerSession: 10
        ),
        StarterHabitTemplate(
            id: "read",
            title: "Leer antes de dormir",
            category: .learning,
            daysPerWeek: 6,
            trackingKind: .check,
            measurementUnit: .none,
            targetValuePerSession: 1
        ),
        StarterHabitTemplate(
            id: "walk",
            title: "Caminar 30 min",
            category: .health,
            daysPerWeek: 5,
            trackingKind: .quantity,
            measurementUnit: .minutes,
            targetValuePerSession: 30
        ),
        StarterHabitTemplate(
            id: "journal",
            title: "Diario matutino",
            category: .work,
            daysPerWeek: 5,
            trackingKind: .check,
            measurementUnit: .none,
            targetValuePerSession: 1
        )
    ]
}
