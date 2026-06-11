//
//  CreateHabitView.swift
//  WeekHabit
//
//  Wizard en 3 pasos siguiendo el modelo conductual:
//    1. Acción (tipo, nombre, apariencia, reemplazo)  — obligatorio
//    2. Ritmo  (días de la semana, medición)          — obligatorio
//    3. Apoyos (señal, recordatorio, extras)          — todo opcional
//
//  Al crear, el flujo es lineal con validación por paso. Al editar, los tres
//  pasos quedan desbloqueados y se puede guardar desde cualquiera.
//

import SwiftUI
import SwiftData
import Foundation
import UserNotifications

struct CreateHabitView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    @Query(sort: \Plan.createdAt, order: .reverse)
    private var allPlans: [Plan]

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var allHabits: [Habit]

    @State private var draft: HabitDraft
    @State private var step: CreateHabitStep = .action
    @State private var furthestVisitedStep: CreateHabitStep
    @State private var navigatesForward = true
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var saveFailure: HabitSaveFailure?

    private let habitToEdit: Habit?
    private let requiredPlans: [Plan]
    private let locksPlanSelection: Bool

    private let topAnchorID = "create-habit-top"

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

        // Al editar, los tres pasos quedan disponibles desde el inicio.
        _furthestVisitedStep = State(initialValue: habitToEdit == nil ? .action : .support)
    }

    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                topBar

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.xl) {
                            CreateHabitStepHeader(
                                step: step,
                                unlockedSteps: unlockedSteps,
                                onSelect: { moveTo($0) }
                            )
                            .id(topAnchorID)

                            stepContent
                                .id(step)
                                .transition(stepTransition)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.l)
                        .padding(.top, AppSpacing.m)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: step) { _, _ in
                        proxy.scrollTo(topAnchorID, anchor: .top)
                    }
                }

                CreateHabitFooterBar(
                    primaryTitle: primaryTitle,
                    isDisabled: isPrimaryDisabled,
                    blockerMessage: blockerMessage,
                    onPrimary: handlePrimaryAction
                )
            }
        }
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
        .alert(item: $saveFailure) { failure in
            Alert(
                title: Text("No se pudo guardar"),
                message: Text(failure.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }

    // MARK: - Barra superior

    private var topBar: some View {
        HStack(spacing: AppSpacing.s) {
            backButton
                .opacity(step.previous == nil ? 0 : 1)
                .disabled(step.previous == nil)

            Spacer()

            Text(isEditing ? "Editar hábito" : "Nuevo hábito")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)
                .textCase(.uppercase)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Cancelar")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.s)
    }

    private var backButton: some View {
        Button {
            if let previous = step.previous {
                moveTo(previous)
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: 34, height: 34)
                .background(AppColor.bgElevated)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Paso anterior")
    }

    // MARK: - Contenido por paso

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .action:
            CreateHabitActionStep(
                draft: $draft,
                replacementCandidates: replacementCandidates,
                autoFocusName: !isEditing
            )
        case .rhythm:
            CreateHabitRhythmStep(draft: $draft)
        case .support:
            CreateHabitSupportStep(
                draft: $draft,
                notificationAuthorizationStatus: notificationAuthorizationStatus,
                onRequestNotificationAuthorization: requestNotificationAuthorization,
                showsPlanSection: !locksPlanSelection,
                isEditing: isEditing
            )
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: navigatesForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: navigatesForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - Navegación

    private var unlockedSteps: Set<CreateHabitStep> {
        Set(CreateHabitStep.allCases.filter { $0.rawValue <= furthestVisitedStep.rawValue })
    }

    private func moveTo(_ newStep: CreateHabitStep) {
        guard newStep != step else { return }

        navigatesForward = newStep.rawValue > step.rawValue
        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            step = newStep
        }
        if newStep.rawValue > furthestVisitedStep.rawValue {
            furthestVisitedStep = newStep
        }
    }

    // MARK: - CTA principal

    private var primaryTitle: String {
        if isEditing {
            return "Guardar cambios"
        }
        return step == .support ? "Crear hábito" : "Continuar"
    }

    private var isPrimaryDisabled: Bool {
        if isEditing {
            return draft.isSaveDisabled
        }
        switch step {
        case .action:
            return !draft.isActionStepComplete
        case .rhythm:
            return !draft.isRhythmStepComplete
        case .support:
            return draft.isSaveDisabled
        }
    }

    private var blockerMessage: String? {
        guard isPrimaryDisabled else { return nil }

        if isEditing || step == .support {
            return draft.actionStepBlocker ?? draft.rhythmStepBlocker
        }
        switch step {
        case .action:
            return draft.actionStepBlocker
        case .rhythm:
            return draft.rhythmStepBlocker
        case .support:
            return nil
        }
    }

    private func handlePrimaryAction() {
        if isEditing {
            saveHabit()
            return
        }
        if let next = step.next {
            moveTo(next)
        } else {
            saveHabit()
        }
    }

    // MARK: - Persistencia

    private func saveHabit() {
        guard !draft.isSaveDisabled else { return }

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

#Preview {
    CreateHabitView()
}
