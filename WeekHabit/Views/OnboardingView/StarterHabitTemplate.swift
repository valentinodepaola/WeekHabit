//
//  StarterHabitTemplate.swift
//  WeekHabit
//

import SwiftUI

struct StarterHabitTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let iconName: String
    let colorHex: String
    let daysPerWeek: Int
    let trackingKind: HabitTrackingKind
    let measurementUnit: HabitMeasurementUnit
    let targetValuePerSession: Double

    var subtitle: String {
        if trackingKind == .quantity, measurementUnit != .none {
            return "\(Habit.formattedQuantity(targetValuePerSession)) \(measurementUnit.shortTitle) · \(daysPerWeek)d/sem"
        }
        return "\(daysPerWeek)d/sem"
    }

    var icon: String {
        iconName
    }

    var color: Color {
        HabitAppearance.color(for: colorHex)
    }

    static let defaultID = "meditate"

    static let all: [StarterHabitTemplate] = [
        StarterHabitTemplate(
            id: "stretch",
            title: "Estirar",
            iconName: "leaf.fill",
            colorHex: "#7fa774",
            daysPerWeek: 5,
            trackingKind: .quantity,
            measurementUnit: .minutes,
            targetValuePerSession: 5
        ),
        StarterHabitTemplate(
            id: "meditate",
            title: "Meditar",
            iconName: "brain.head.profile",
            colorHex: "#8b7fb0",
            daysPerWeek: 7,
            trackingKind: .quantity,
            measurementUnit: .minutes,
            targetValuePerSession: 10
        ),
        StarterHabitTemplate(
            id: "read",
            title: "Leer",
            iconName: "book.fill",
            colorHex: "#5c89a8",
            daysPerWeek: 6,
            trackingKind: .check,
            measurementUnit: .none,
            targetValuePerSession: 1
        ),
        StarterHabitTemplate(
            id: "walk",
            title: "Caminar",
            iconName: "figure.walk",
            colorHex: "#7fa774",
            daysPerWeek: 5,
            trackingKind: .quantity,
            measurementUnit: .minutes,
            targetValuePerSession: 30
        ),
        StarterHabitTemplate(
            id: "journal",
            title: "Diario matutino",
            iconName: "pencil",
            colorHex: "#c89046",
            daysPerWeek: 5,
            trackingKind: .check,
            measurementUnit: .none,
            targetValuePerSession: 1
        )
    ]
}
