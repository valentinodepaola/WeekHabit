//
//  Habit.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftData
import Foundation
import SwiftUI

enum HabitTrackingKind: String, Codable, CaseIterable, Identifiable {
    case check
    case quantity

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .check: return "Hecho / no hecho"
        case .quantity: return "Cantidad"
        }
    }
}

enum HabitMeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case none
    case minutes
    case pages
    case kilometers
    case glasses
    case repetitions
    case custom

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .none: return "Sin unidad"
        case .minutes: return "Minutos"
        case .pages: return "Páginas"
        case .kilometers: return "Km"
        case .glasses: return "Vasos"
        case .repetitions: return "Repeticiones"
        case .custom: return "Personalizada"
        }
    }

    var shortTitle: String {
        switch self {
        case .none: return ""
        case .minutes: return "min"
        case .pages: return "pág"
        case .kilometers: return "km"
        case .glasses: return "vasos"
        case .repetitions: return "reps"
        case .custom: return ""
        }
    }
}

enum HabitScheduleKind: String, Codable, CaseIterable, Identifiable {
    case daily
    case specificDays
    case timesPerWeek

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .daily: return "Diario"
        case .specificDays: return "Días específicos"
        case .timesPerWeek: return "Veces por semana"
        }
    }
}

@Model
final class Habit {
    var id: UUID
    var title: String
    var note: String?
    var cue: String?
    @Attribute(originalName: "category")
    var legacyArea: LegacyHabitArea?
    var iconNameRaw: String?
    var colorHexRaw: String?
    var targetDaysPerWeek: Int
    var activeDaysOfWeekRaw: [Int]
    var trackingKindRaw: String?
    var measurementUnitRaw: String?
    var customUnitName: String?
    var targetValuePerSession: Double?
    var scheduleKindRaw: String?
    var endsAt: Date?
    var allowsWeeklyFreeze: Bool = true
    var isReminderEnabled: Bool = false
    var reminderTime: Date? = nil
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var entries: [HabitEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \StreakFreeze.habit)
    var streakFreezes: [StreakFreeze] = []

    var plans: [Plan] = []

    /// Set-based view of `activeDaysOfWeekRaw`.
    var activeDaysOfWeek: Set<Weekday> {
        get { Set(activeDaysOfWeekRaw.compactMap { Weekday(rawValue: $0) }) }
        set { activeDaysOfWeekRaw = newValue.map(\.rawValue) }
    }

    var iconName: String {
        get { iconNameRaw ?? legacyArea?.iconName ?? HabitAppearance.defaultIconName }
        set { iconNameRaw = newValue }
    }

    var colorHex: String {
        get { colorHexRaw ?? legacyArea?.colorHex ?? HabitAppearance.defaultColorHex }
        set { colorHexRaw = newValue }
    }

    var habitColor: Color {
        Color(hex: colorHex)
    }

    var trackingKind: HabitTrackingKind {
        get { HabitTrackingKind(rawValue: trackingKindRaw ?? "") ?? .check }
        set { trackingKindRaw = newValue.rawValue }
    }

    var measurementUnit: HabitMeasurementUnit {
        get { HabitMeasurementUnit(rawValue: measurementUnitRaw ?? "") ?? .none }
        set { measurementUnitRaw = newValue.rawValue }
    }

    var scheduleKind: HabitScheduleKind {
        get {
            if let scheduleKindRaw, let scheduleKind = HabitScheduleKind(rawValue: scheduleKindRaw) {
                return scheduleKind
            }

            return activeDaysOfWeek.count == Weekday.ordered.count ? .daily : .specificDays
        }
        set { scheduleKindRaw = newValue.rawValue }
    }

    init(
        title: String,
        note: String? = nil,
        cue: String? = nil,
        iconName: String = HabitAppearance.defaultIconName,
        colorHex: String = HabitAppearance.defaultColorHex,
        targetDaysPerWeek: Int,
        activeDaysOfWeek: Set<Weekday>,
        trackingKind: HabitTrackingKind = .check,
        measurementUnit: HabitMeasurementUnit = .none,
        customUnitName: String? = nil,
        targetValuePerSession: Double = 1,
        scheduleKind: HabitScheduleKind = .specificDays,
        endsAt: Date? = nil,
        allowsWeeklyFreeze: Bool = true,
        isReminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.cue = cue
        self.legacyArea = nil
        self.iconNameRaw = iconName
        self.colorHexRaw = colorHex
        self.targetDaysPerWeek = targetDaysPerWeek
        self.activeDaysOfWeekRaw = activeDaysOfWeek.map(\.rawValue)
        self.trackingKindRaw = trackingKind.rawValue
        self.measurementUnitRaw = measurementUnit.rawValue
        self.customUnitName = customUnitName
        self.targetValuePerSession = targetValuePerSession
        self.scheduleKindRaw = scheduleKind.rawValue
        self.endsAt = endsAt
        self.allowsWeeklyFreeze = allowsWeeklyFreeze
        self.isReminderEnabled = isReminderEnabled
        self.reminderTime = reminderTime
        self.createdAt = createdAt
    }
}
