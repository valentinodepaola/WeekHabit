//
//  FocusSessionView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData
internal import Combine

struct FocusSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let habits: [Habit]

    @State private var phase: FocusSessionPhase = .setup
    @State private var selectedDuration: FocusDurationPreset = .twentyFive
    @State private var selectedHabitIDs: Set<UUID>
    @State private var completedHabitIDs: Set<UUID> = []
    @State private var isSequenced = false
    @State private var sequence: [FocusSequenceItem] = []
    @State private var session: FocusSession?
    @State private var now: Date = .now
    @State private var milestoneCover: MilestoneCelebrationPayload?
    @State private var milestoneQueue: [MilestoneCelebrationPayload] = []
    @State private var shouldDismissAfterMilestones = false
    @State private var saveFailure: FocusSessionSaveFailure?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(habits: [Habit]) {
        self.habits = habits

        let incompleteIDs = habits
            .filter { !$0.isCompleted(on: .now) && !$0.isSkipped(on: .now) }
            .map(\.id)
        let initialIDs = incompleteIDs.isEmpty ? habits.map(\.id) : incompleteIDs
        _selectedHabitIDs = State(initialValue: Set(initialIDs))
    }

    var body: some View {
        AppBackground {
            VStack(alignment: .leading, spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        header

                        switch phase {
                        case .setup: setupContent
                        case .running: runningContent
                        case .review: reviewContent
                        }
                    }
                    .padding(.horizontal, AppSpacing.l)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .onReceive(timer) { date in
            guard phase == .running, let session else { return }
            now = date

            if let remaining = session.remainingSeconds(reference: date), remaining == 0 {
                finishSession(reference: date)
            }
        }
        .onChange(of: selectedHabitIDs) { _, newValue in
            guard isSequenced else { return }
            sequence = FocusSequence.reconcile(
                items: sequence,
                selectedIDs: newValue,
                appendingOrder: habits.map(\.id)
            )
        }
        .onChange(of: isSequenced) { _, newValue in
            guard newValue else { return }
            sequence = FocusSequence.reconcile(
                items: sequence,
                selectedIDs: selectedHabitIDs,
                appendingOrder: habits.map(\.id)
            )
        }
        .fullScreenCover(item: $milestoneCover, onDismiss: presentNextMilestoneOrDismiss) { payload in
            MilestoneCelebrationView(habit: payload.habit, milestone: payload.milestone)
        }
        .alert(item: $saveFailure) { failure in
            Alert(
                title: Text("No se pudo iniciar"),
                message: Text(failure.message),
                dismissButton: .default(Text("Entendido"))
            )
        }
    }

    private var topBar: some View {
        HStack {
            Button("Cerrar") {
                cancelAndDismiss()
            }
            .font(AppFont.body)
            .foregroundStyle(AppColor.textSecondary)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.l)
        .padding(.bottom, AppSpacing.s)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("MODO ENFOQUE")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(1.2)

            Text(headerTitle)
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var headerTitle: String {
        switch phase {
        case .setup: return "Sesión de ritmo"
        case .running: return "Enfoque activo"
        case .review: return "¿Qué no alcanzaste a completar?"
        }
    }

    // MARK: - Setup

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            sequenceToggle

            if !isSequenced {
                FocusDurationPicker(selectedDuration: $selectedDuration)
            }

            FocusHabitPicker(
                habits: habits,
                selectedHabitIDs: $selectedHabitIDs
            )

            if isSequenced {
                FocusSequenceSetup(
                    items: $sequence,
                    habitsByID: habitsByID
                )
            }

            WHButton(
                title: "Iniciar sesión",
                icon: "play.fill",
                variant: .primary,
                isDisabled: selectedHabitIDs.isEmpty,
                action: startSession
            )
        }
    }

    private var sequenceToggle: some View {
        Toggle(isOn: $isSequenced.animation(AppMotion.respectful(AppMotion.smooth, reduceMotion))) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ordenar y repartir tiempo")
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Define la secuencia y el tiempo de cada hábito")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .tint(AppColor.accent)
        .padding(AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
    }

    // MARK: - Running

    private var runningContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            FocusTimerRing(
                timeText: runningTimeText,
                subtitle: selectedHabitIDs.count == 1 ? "1 hábito en enfoque" : "\(selectedHabitIDs.count) hábitos en enfoque",
                remainingFraction: remainingFraction
            )
            .padding(.vertical, AppSpacing.l)

            if isSequenced {
                FocusSequenceStepper(
                    items: sequence,
                    habitsByID: habitsByID,
                    elapsed: session?.elapsedSeconds(reference: now) ?? 0
                )
            } else {
                FocusSelectedHabitsCard(habits: reviewHabits)
            }

            WHButton(title: "Terminar sesión", variant: .secondary, action: { finishSession(reference: .now) })
        }
    }

    // MARK: - Review

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Text("Desmarca los hábitos que no lograste completar en esta sesión.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(reviewEncouragement)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FocusReviewChecklist(
                habits: reviewHabits,
                completedHabitIDs: $completedHabitIDs
            )

            WHButton(
                title: "Guardar sesión",
                variant: .primary,
                action: saveSessionResults
            )
        }
    }

    private var reviewEncouragement: String {
        let total = selectedHabitIDs.count
        let done = completedHabitIDs.count

        if done == total {
            return "Cerraste todo lo que te propusiste. Buen ritmo."
        }
        if done == 0 {
            return "Está bien — registrar la sesión ya es avanzar."
        }
        return "Cada bloque cuenta. Lo demás queda para la próxima."
    }

    // MARK: - Derived

    private var habitsByID: [UUID: Habit] {
        Dictionary(habits.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Hábitos seleccionados en orden: secuencia si está activa, si no el orden natural.
    private var reviewHabits: [Habit] {
        if isSequenced {
            return sequence.compactMap { item in habitsByID[item.id] }
        }
        return habits.filter { selectedHabitIDs.contains($0.id) }
    }

    private var runningTimeText: String {
        guard let session else { return "0:00" }

        if let remaining = session.remainingSeconds(reference: now) {
            return FocusTimeFormatter.string(from: remaining)
        }
        return FocusTimeFormatter.string(from: session.elapsedSeconds(reference: now))
    }

    /// Fracción restante (0...1) para el anillo. `nil` en sesiones libres.
    private var remainingFraction: Double? {
        guard let session, let progress = session.progress(reference: now) else { return nil }
        return 1 - progress
    }

    private var sessionDurationSeconds: Int? {
        if isSequenced {
            return FocusSequence.totalSeconds(sequence)
        }
        return selectedDuration.durationSeconds
    }

    // MARK: - Actions

    private func startSession() {
        let startedAt = Date()

        do {
            session = try FocusSessionEditorService.start(
                selectedHabitIDs: selectedHabitIDs,
                durationSeconds: sessionDurationSeconds,
                startedAt: startedAt,
                modelContext: modelContext
            )
        } catch {
            saveFailure = FocusSessionSaveFailure(message: error.localizedDescription)
            return
        }

        now = startedAt

        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            phase = .running
        }
    }

    private func finishSession(reference: Date) {
        guard phase == .running else { return }
        session?.finishForReview(reference: reference)
        AppHaptics.play(.focusClosed)

        // Cierre invertido: todos preseleccionados, el usuario desmarca lo que faltó.
        completedHabitIDs = selectedHabitIDs

        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            phase = .review
        }
    }

    private func saveSessionResults() {
        guard let session else {
            dismiss()
            return
        }

        let completedAt = session.endedAt ?? .now
        var reachedMilestones: [MilestoneCelebrationPayload] = []

        for habit in reviewHabits where completedHabitIDs.contains(habit.id) {
            if let payload = markCompleted(habit, completedAt: completedAt, sessionID: session.id) {
                reachedMilestones.append(payload)
            }
        }

        session.complete(completedHabitIDs: completedHabitIDs, reference: completedAt)
        if !completedHabitIDs.isEmpty {
            AppHaptics.play(.habitCompleted)
        }

        guard let firstMilestone = reachedMilestones.first else {
            dismiss()
            return
        }

        milestoneQueue = Array(reachedMilestones.dropFirst())
        shouldDismissAfterMilestones = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            milestoneCover = firstMilestone
        }
    }

    private func presentNextMilestoneOrDismiss() {
        guard !milestoneQueue.isEmpty else {
            if shouldDismissAfterMilestones {
                shouldDismissAfterMilestones = false
                dismiss()
            }
            return
        }

        let next = milestoneQueue.removeFirst()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            milestoneCover = next
        }
    }

    private func markCompleted(_ habit: Habit, completedAt: Date, sessionID: UUID) -> MilestoneCelebrationPayload? {
        HabitTrackingService.setCompleted(
            habit,
            on: completedAt,
            source: .focusSession,
            completedAt: completedAt,
            value: habit.sessionTargetValue,
            focusSessionID: sessionID,
            modelContext: modelContext,
            streakFreezes: habit.streakFreezes
        )

        guard let milestone = habit.crossedMilestone(on: completedAt) else { return nil }
        habit.markMilestoneCelebrated(milestone)
        return MilestoneCelebrationPayload(habit: habit, milestone: milestone)
    }

    private func cancelAndDismiss() {
        session?.cancel(reference: .now)
        dismiss()
    }
}

private enum FocusSessionPhase {
    case setup
    case running
    case review
}

private struct FocusSessionSaveFailure: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    FocusSessionView(
        habits: [
            Habit(
                title: "Leer 20 páginas",
                iconName: "book.fill",
                colorHex: "#5c89a8",
                targetDaysPerWeek: 4,
                activeDaysOfWeek: [.monday, .wednesday, .friday]
            )
        ]
    )
}
