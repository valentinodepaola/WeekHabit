//
//  HabitDraft.swift
//  WeekHabit
//

import Foundation

struct HabitDraft {
    var name: String
    var note: String
    var cue: String
    var minimumViableTitle: String
    var iconName: String
    var colorHex: String
    var direction: HabitDirection
    var trackingKind: HabitTrackingKind
    var measurementUnit: HabitMeasurementUnit
    var targetValueText: String
    var scheduleKind: HabitScheduleKind
    var timesPerWeek: Int
    var activeDays: Set<Weekday>
    var hasEndDate: Bool
    var endsAt: Date
    var allowsWeeklyFreeze: Bool
    var isReminderEnabled: Bool
    var reminderTime: Date
    var selectedPlanIDs: Set<UUID>
    var replacementMode: HabitReplacementMode
    var replacementHabitID: UUID?
    var newReplacementHabitName: String
    var newReplacementHabitCue: String

    init(
        habit: Habit? = nil,
        initialDaysPerWeek: Int = 0,
        initialActiveDays: Set<Weekday> = [],
        initialPlanIDs: Set<UUID> = [],
        requiredPlans: [Plan] = []
    ) {
        let scheduleKind: HabitScheduleKind
        if let habit {
            scheduleKind = habit.scheduleKind
        } else if initialDaysPerWeek > 0 || !initialActiveDays.isEmpty {
            scheduleKind = .specificDays
        } else {
            scheduleKind = .daily
        }

        let requiredPlanIDs = requiredPlans.map(\.id)
        let selectedPlanIDs = habit.map { $0.plans.map(\.id) } ?? Array(initialPlanIDs)

        self.name = habit?.title ?? ""
        self.note = habit?.note ?? ""
        self.cue = habit?.cue ?? ""
        self.minimumViableTitle = habit?.minimumViableTitle ?? ""
        self.iconName = habit?.iconName ?? HabitAppearance.defaultIconName
        self.colorHex = habit?.colorHex ?? HabitAppearance.defaultColorHex
        self.direction = habit?.direction ?? .build
        self.trackingKind = habit?.trackingKind ?? .check
        self.measurementUnit = Self.normalizedInitialUnit(habit?.measurementUnit ?? .none)
        self.targetValueText = Habit.formattedQuantity(habit?.sessionTargetValue ?? 1)
        self.scheduleKind = scheduleKind
        self.timesPerWeek = habit?.targetDaysPerWeek ?? max(initialDaysPerWeek, 1)
        self.activeDays = habit?.activeDaysOfWeek ?? initialActiveDays
        self.hasEndDate = habit?.endsAt != nil
        self.endsAt = habit?.endsAt ?? .now
        self.allowsWeeklyFreeze = habit?.allowsWeeklyFreeze ?? true
        self.isReminderEnabled = habit?.isReminderEnabled ?? false
        self.reminderTime = habit?.reminderTime ?? Self.defaultReminderTime()
        self.selectedPlanIDs = Set(selectedPlanIDs + requiredPlanIDs)
        self.replacementMode = habit?.replacementHabit == nil ? .skip : .existing
        self.replacementHabitID = habit?.replacementHabit?.id
        self.newReplacementHabitName = ""
        self.newReplacementHabitCue = ""
    }

    var parsedTargetValue: Double {
        Double(targetValueText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var normalizedTargetValue: Double {
        trackingKind == .check ? 1 : parsedTargetValue
    }

    var normalizedMeasurementUnit: HabitMeasurementUnit {
        trackingKind == .check ? .none : measurementUnit
    }

    var normalizedEndsAt: Date? {
        hasEndDate ? AppCalendar.startOfDay(for: endsAt) : nil
    }

    var normalizedSchedule: (targetDaysPerWeek: Int, activeDays: Set<Weekday>) {
        switch scheduleKind {
        case .daily:
            return (7, Set(Weekday.ordered))
        case .specificDays:
            return (activeDays.count, activeDays)
        case .timesPerWeek:
            return (timesPerWeek, Set(Weekday.ordered))
        }
    }

    // MARK: - Validación por paso
    // El formulario se completa en pasos; cada paso valida solo lo suyo y
    // expone el motivo del bloqueo para mostrarlo junto al CTA.

    /// Paso 1 — Acción: nombre y, para hábitos a dejar, reemplazo resuelto.
    var actionStepBlocker: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Escribe qué vas a hacer para continuar."
        }
        if direction == .break && replacementMode == .create
            && newReplacementHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Ponle nombre al reemplazo, o elige omitirlo por ahora."
        }
        if direction == .break && replacementMode == .existing && replacementHabitID == nil {
            return "Elige el hábito de reemplazo, o cambia de opción."
        }
        return nil
    }

    /// Paso 2 — Ritmo: agenda semanal válida y medición completa.
    var rhythmStepBlocker: String? {
        if trackingKind == .quantity {
            if measurementUnit == .none {
                return "Elige la unidad con la que vas a medirlo."
            }
            if parsedTargetValue <= 0 {
                return "Define una meta por sesión mayor a cero."
            }
        }
        switch scheduleKind {
        case .daily:
            return nil
        case .specificDays:
            return activeDays.isEmpty ? "Elige al menos un día de la semana." : nil
        case .timesPerWeek:
            return (1...7).contains(timesPerWeek) ? nil : "Elige entre 1 y 7 veces por semana."
        }
    }

    var isActionStepComplete: Bool {
        actionStepBlocker == nil
    }

    var isRhythmStepComplete: Bool {
        rhythmStepBlocker == nil
    }

    var isSaveDisabled: Bool {
        !isActionStepComplete || !isRhythmStepComplete
    }

    mutating func reconcileDirection() {
        if direction == .break && scheduleKind == .timesPerWeek {
            scheduleKind = .daily
        }
        if direction == .build {
            replacementMode = .skip
            replacementHabitID = nil
        }
    }

    mutating func reconcileTrackingKind() {
        if trackingKind == .check {
            measurementUnit = .none
            targetValueText = "1"
        } else if measurementUnit == .none {
            measurementUnit = .minutes
        }
    }

    private static func normalizedInitialUnit(_ unit: HabitMeasurementUnit) -> HabitMeasurementUnit {
        unit == .custom ? .minutes : unit
    }

    private static func defaultReminderTime() -> Date {
        AppCalendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: .now
        ) ?? .now
    }
}
