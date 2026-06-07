//
//  CreateHabitView.swift
//  WeekHabit
//
//  Orden por modelo conductual:
//    Acción → Señal → Medición (si cantidad) → Ritmo → Finalización → Recordatorio → Plan
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

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var allHabits: [Habit]

    @State private var draft: HabitDraft
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var saveFailure: HabitSaveFailure?

    private let habitToEdit: Habit?
    private let requiredPlans: [Plan]
    private let locksPlanSelection: Bool

    private var isSaveDisabled: Bool {
        draft.isSaveDisabled
    }

    private var isEditing: Bool {
        habitToEdit != nil
    }

    private var replacementCandidates: [Habit] {
        allHabits.filter { candidate in
            candidate.direction == .build && candidate.id != habitToEdit?.id
        }
    }

    init(
        habitToEdit: Habit? = nil,
        initialDaysPerWeek: Int = 0,
        initialActiveDays: Set<Weekday> = [],
        initialPlanIDs: Set<UUID> = [],
        requiredPlans: [Plan] = [],
        locksPlanSelection: Bool = false
    ) {
        self.habitToEdit = habitToEdit
        self.requiredPlans = requiredPlans
        self.locksPlanSelection = locksPlanSelection

        _draft = State(
            initialValue: HabitDraft(
                habit: habitToEdit,
                initialDaysPerWeek: initialDaysPerWeek,
                initialActiveDays: initialActiveDays,
                initialPlanIDs: initialPlanIDs,
                requiredPlans: requiredPlans
            )
        )
    }

    var body: some View {
        AppBackground {
            ScrollView {
                CreateHabitTopBar(
                    isSaveDisabled: isSaveDisabled,
                    onCancel: { dismiss() },
                    onSave: { saveHabit() }
                )

                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text(isEditing ? "Editar hábito" : "Nuevo hábito")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.bottom, AppSpacing.xs)

                    // 0. Dirección
                    HabitDirectionSection(direction: $draft.direction)

                    // 1. Acción
                    HabitBasicInfoSection(
                        habitName: $draft.name,
                        note: $draft.note,
                        selectedIconName: $draft.iconName,
                        selectedColorHex: $draft.colorHex
                    )

                    HabitMinimalVersionSection(minimumViableTitle: $draft.minimumViableTitle)

                    // 2. Señal
                    HabitCueSection(cue: $draft.cue)

                    if draft.direction == .`break` {
                        HabitReplacementSection(
                            availableHabits: replacementCandidates,
                            mode: $draft.replacementMode,
                            selectedHabitID: $draft.replacementHabitID,
                            newHabitName: $draft.newReplacementHabitName,
                            newHabitCue: $draft.newReplacementHabitCue
                        )
                    }

                    // 3. Medición (siempre visible — el selector check/quantity es parte)
                    HabitMeasurementSection(
                        trackingKind: $draft.trackingKind,
                        measurementUnit: $draft.measurementUnit,
                        targetValueText: $draft.targetValueText
                    )

                    // 4. Ritmo
                    HabitScheduleSection(
                        scheduleKind: $draft.scheduleKind,
                        timesPerWeek: $draft.timesPerWeek,
                        selectedActiveDays: $draft.activeDays,
                        showFlexible: draft.direction != .`break`
                    )

                    HabitEndDateSection(
                        hasEndDate: $draft.hasEndDate,
                        endsAt: $draft.endsAt
                    )

                    HabitWeeklyFreezeSection(allowsWeeklyFreeze: $draft.allowsWeeklyFreeze)

                    // 5. Recordatorio
                    HabitReminderSection(
                        isReminderEnabled: $draft.isReminderEnabled,
                        reminderTime: $draft.reminderTime,
                        authorizationStatus: notificationAuthorizationStatus,
                        onRequestAuthorization: requestNotificationAuthorization
                    )

                    if !locksPlanSelection {
                        // 6. Plan
                        HabitPlansSection(selectedPlans: $draft.selectedPlanIDs)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.l)
                .padding(.bottom, AppSpacing.xxl)
                .onChange(of: draft.direction) { _, _ in
                    draft.reconcileDirection()
                }
                .onChange(of: replacementCandidates.map(\.id)) { _, candidateIDs in
                    guard draft.replacementMode == .existing else { return }
                    if draft.replacementHabitID.map({ candidateIDs.contains($0) }) != true {
                        draft.replacementHabitID = candidateIDs.first
                    }
                    if candidateIDs.isEmpty {
                        draft.replacementMode = .skip
                    }
                }
                .onChange(of: draft.trackingKind) { _, _ in
                    draft.reconcileTrackingKind()
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
        .alert(item: $saveFailure) { failure in
            Alert(
                title: Text("No se pudo guardar"),
                message: Text(failure.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }

    private func saveHabit() {
        guard !isSaveDisabled else { return }

        let savedHabit: Habit
        do {
            savedHabit = try HabitEditorService.save(
                draft: draft,
                editing: habitToEdit,
                experiments: experiments,
                allPlans: allPlans,
                allHabits: allHabits,
                requiredPlans: requiredPlans,
                locksPlanSelection: locksPlanSelection,
                canScheduleReminders: notificationAuthorizationStatus.allowsReminderScheduling,
                modelContext: modelContext
            )
        } catch {
            saveFailure = HabitSaveFailure(message: error.localizedDescription)
            return
        }

        Task {
            await HabitReminderService.refreshReminder(for: savedHabit)
        }

        dismiss()
    }

    private func refreshNotificationAuthorizationStatus() async {
        let status = await HabitReminderService.authorizationStatus()
        notificationAuthorizationStatus = status

        if !status.allowsReminderScheduling {
            draft.isReminderEnabled = false
        }
    }

    private func requestNotificationAuthorization() {
        Task {
            let granted = await HabitReminderService.requestAuthorization()
            await refreshNotificationAuthorizationStatus()
            if granted {
                draft.isReminderEnabled = true
            }
        }
    }
}

private struct HabitSaveFailure: Identifiable {
    let id = UUID()
    let message: String
}

private struct HabitMinimalVersionSection: View {
    @Binding var minimumViableTitle: String

    var body: some View {
        CreateHabitFormSection(
            title: "Versión mínima viable",
            helper: "Una versión pequeña para días difíciles. Cuenta para tu racha aunque no para el conteo de días completos."
        ) {
            TextFieldComponent(
                titleSection: "Mínima",
                placeholder: "Ej: Caminar 5 min",
                habitName: $minimumViableTitle,
                normalTextField: false
            )
        }
    }
}

#Preview {
    CreateHabitView()
}
