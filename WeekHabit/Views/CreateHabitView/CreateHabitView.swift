//
//  CreateHabitView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
//

import SwiftUI
import SwiftData
import Foundation
import UserNotifications

struct CreateHabitView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    @Query(sort: \Plan.createdAt, order: .reverse)
    private var allPlans: [Plan]

    @State private var habitName: String = ""
    @State private var note: String = ""
    @State private var cue: String = ""
    @State private var selectedIconName: String = HabitAppearance.defaultIconName
    @State private var selectedColorHex: String = HabitAppearance.defaultColorHex
    @State private var trackingKind: HabitTrackingKind = .check
    @State private var measurementUnit: HabitMeasurementUnit = .none
    @State private var targetValueText: String = "1"
    @State private var scheduleKind: HabitScheduleKind = .daily
    @State private var timesPerWeek: Int = 1
    @State private var selectedActiveDays: Set<Weekday> = []
    @State private var hasEndDate: Bool = false
    @State private var endsAt: Date = .now
    @State private var isReminderEnabled: Bool = false
    @State private var reminderTime: Date = Self.defaultReminderTime()
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var selectedPlans: Set<UUID> = []

    private let habitToEdit: Habit?

    private var isSaveDisabled: Bool {
        if habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        if trackingKind == .quantity {
            guard parsedTargetValue > 0 else { return true }
            if measurementUnit == .none { return true }
        }

        switch scheduleKind {
        case .daily:
            return false
        case .specificDays:
            return selectedActiveDays.isEmpty
        case .timesPerWeek:
            return !(1...7).contains(timesPerWeek)
        }
    }

    private var isEditing: Bool {
        habitToEdit != nil
    }

    private var parsedTargetValue: Double {
        let normalized = targetValueText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized) ?? 0
    }

    init(
        habitToEdit: Habit? = nil,
        initialDaysPerWeek: Int = 0,
        initialActiveDays: Set<Weekday> = []
    ) {
        self.habitToEdit = habitToEdit

        let initialScheduleKind: HabitScheduleKind
        if let habitToEdit {
            initialScheduleKind = habitToEdit.scheduleKind
        } else if initialDaysPerWeek > 0 || !initialActiveDays.isEmpty {
            initialScheduleKind = .specificDays
        } else {
            initialScheduleKind = .daily
        }

        _habitName = State(initialValue: habitToEdit?.title ?? "")
        _note = State(initialValue: habitToEdit?.note ?? "")
        _cue = State(initialValue: habitToEdit?.cue ?? "")
        _selectedIconName = State(initialValue: habitToEdit?.iconName ?? HabitAppearance.defaultIconName)
        _selectedColorHex = State(initialValue: habitToEdit?.colorHex ?? HabitAppearance.defaultColorHex)
        _trackingKind = State(initialValue: habitToEdit?.trackingKind ?? .check)
        _measurementUnit = State(initialValue: Self.normalizedInitialUnit(habitToEdit?.measurementUnit ?? .none))
        _targetValueText = State(initialValue: Habit.formattedQuantity(habitToEdit?.sessionTargetValue ?? 1))
        _scheduleKind = State(initialValue: initialScheduleKind)
        _timesPerWeek = State(initialValue: habitToEdit?.targetDaysPerWeek ?? max(initialDaysPerWeek, 1))
        _selectedActiveDays = State(initialValue: habitToEdit?.activeDaysOfWeek ?? initialActiveDays)
        _hasEndDate = State(initialValue: habitToEdit?.endsAt != nil)
        _endsAt = State(initialValue: habitToEdit?.endsAt ?? .now)
        _isReminderEnabled = State(initialValue: habitToEdit?.isReminderEnabled ?? false)
        _reminderTime = State(initialValue: habitToEdit?.reminderTime ?? Self.defaultReminderTime())
        _selectedPlans = State(initialValue: Set(habitToEdit?.plans.map(\.id) ?? []))
    }

    var body: some View {
        AppBackground {
            ScrollView {
                CreateHabitTopBar(
                    isSaveDisabled: isSaveDisabled,
                    onCancel: { dismiss() },
                    onSave: { saveHabit() }
                )

                VStack(alignment: .leading, spacing: 25) {
                    Text(isEditing ? "Editar hábito" : "Nuevo hábito")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)
                        .padding(.bottom, 8)

                    HabitBasicInfoSection(
                        habitName: $habitName,
                        note: $note,
                        cue: $cue,
                        selectedIconName: $selectedIconName,
                        selectedColorHex: $selectedColorHex
                    )

                    HabitMeasurementSection(
                        trackingKind: $trackingKind,
                        measurementUnit: $measurementUnit,
                        targetValueText: $targetValueText
                    )

                    HabitScheduleSection(
                        scheduleKind: $scheduleKind,
                        timesPerWeek: $timesPerWeek,
                        selectedActiveDays: $selectedActiveDays
                    )

                    HabitEndDateSection(
                        hasEndDate: $hasEndDate,
                        endsAt: $endsAt
                    )

                    HabitReminderSection(
                        isReminderEnabled: $isReminderEnabled,
                        reminderTime: $reminderTime,
                        authorizationStatus: notificationAuthorizationStatus
                    )

                    HabitPlansSection(selectedPlans: $selectedPlans)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .onChange(of: trackingKind) { _, newValue in
                    if newValue == .check {
                        measurementUnit = .none
                        targetValueText = "1"
                    } else if measurementUnit == .none {
                        measurementUnit = .minutes
                    }
                }
                .task {
                    await refreshNotificationAuthorizationStatus()
                }
                .onChange(of: scenePhase) { _, newValue in
                    if newValue == .active {
                        Task {
                            await refreshNotificationAuthorizationStatus()
                        }
                    }
                }
            }
        }
    }

    private func saveHabit() {
        guard !isSaveDisabled else { return }

        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCue = cue.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTargetValue = trackingKind == .check ? 1 : parsedTargetValue
        let normalizedMeasurementUnit: HabitMeasurementUnit = trackingKind == .check ? .none : measurementUnit
        let normalizedEndsAt = hasEndDate ? AppCalendar.startOfDay(for: endsAt) : nil
        let normalizedPlan = normalizedSchedulePlan()
        let normalizedReminderEnabled = isReminderEnabled && notificationAuthorizationStatus.allowsReminderScheduling

        let linkedPlans = allPlans.filter { selectedPlans.contains($0.id) }
        let savedHabit: Habit

        if let habitToEdit {
            if let activeExperiment = experiments.activeExperiment(for: habitToEdit.id) {
                activeExperiment.cancel()
            }

            habitToEdit.title = trimmedName
            habitToEdit.note = trimmedNote.isEmpty ? nil : trimmedNote
            habitToEdit.cue = trimmedCue.isEmpty ? nil : trimmedCue
            habitToEdit.iconName = selectedIconName
            habitToEdit.colorHex = selectedColorHex
            habitToEdit.trackingKind = trackingKind
            habitToEdit.measurementUnit = normalizedMeasurementUnit
            habitToEdit.customUnitName = nil
            habitToEdit.targetValuePerSession = normalizedTargetValue
            habitToEdit.scheduleKind = scheduleKind
            habitToEdit.targetDaysPerWeek = normalizedPlan.targetDaysPerWeek
            habitToEdit.activeDaysOfWeek = normalizedPlan.activeDays
            habitToEdit.endsAt = normalizedEndsAt
            habitToEdit.isReminderEnabled = normalizedReminderEnabled
            habitToEdit.reminderTime = normalizedReminderEnabled ? reminderTime : nil
            habitToEdit.plans = linkedPlans
            savedHabit = habitToEdit
        } else {
            let habit = Habit(
                title: trimmedName,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                cue: trimmedCue.isEmpty ? nil : trimmedCue,
                iconName: selectedIconName,
                colorHex: selectedColorHex,
                targetDaysPerWeek: normalizedPlan.targetDaysPerWeek,
                activeDaysOfWeek: normalizedPlan.activeDays,
                trackingKind: trackingKind,
                measurementUnit: normalizedMeasurementUnit,
                customUnitName: nil,
                targetValuePerSession: normalizedTargetValue,
                scheduleKind: scheduleKind,
                endsAt: normalizedEndsAt,
                isReminderEnabled: normalizedReminderEnabled,
                reminderTime: normalizedReminderEnabled ? reminderTime : nil
            )
            modelContext.insert(habit)
            habit.plans = linkedPlans
            savedHabit = habit
        }

        Task {
            await HabitReminderService.refreshReminder(for: savedHabit)
        }

        dismiss()
    }

    private func normalizedSchedulePlan() -> (targetDaysPerWeek: Int, activeDays: Set<Weekday>) {
        switch scheduleKind {
        case .daily:
            return (7, Set(Weekday.ordered))
        case .specificDays:
            return (selectedActiveDays.count, selectedActiveDays)
        case .timesPerWeek:
            return (timesPerWeek, Set(Weekday.ordered))
        }
    }

    private static func normalizedInitialUnit(_ unit: HabitMeasurementUnit) -> HabitMeasurementUnit {
        unit == .custom ? .minutes : unit
    }

    private func refreshNotificationAuthorizationStatus() async {
        let status = await HabitReminderService.authorizationStatus()
        notificationAuthorizationStatus = status

        if !status.allowsReminderScheduling {
            isReminderEnabled = false
        }
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

#Preview {
    CreateHabitView()
}
