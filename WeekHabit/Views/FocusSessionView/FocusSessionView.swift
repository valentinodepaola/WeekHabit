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

    let habits: [Habit]

    @State private var phase: FocusSessionPhase = .setup
    @State private var selectedDuration: FocusDurationPreset = .twentyFive
    @State private var selectedHabitIDs: Set<UUID>
    @State private var completedHabitIDs: Set<UUID> = []
    @State private var session: FocusSession?
    @State private var now: Date = .now

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(habits: [Habit]) {
        self.habits = habits

        let incompleteIDs = habits
            .filter { !$0.isCompleted(on: .now) }
            .map(\.id)
        let initialIDs = incompleteIDs.isEmpty ? habits.map(\.id) : incompleteIDs
        _selectedHabitIDs = State(initialValue: Set(initialIDs))
    }

    var body: some View {
        AppBackground {
            VStack(alignment: .leading, spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        switch phase {
                        case .setup:
                            setupContent
                        case .running:
                            runningContent
                        case .review:
                            reviewContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
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
    }

    private var topBar: some View {
        HStack {
            Button("Cerrar") {
                cancelAndDismiss()
            }
            .font(AppFont.body2)
            .foregroundStyle(AppColor.mutedText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 10)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("MODO ENFOQUE")
                .font(AppFont.captionApp)
                .fontWeight(.bold)
                .foregroundStyle(AppColor.subtleText)
                .tracking(2)

            Text(headerTitle)
                .font(AppFont.title)
                .foregroundStyle(AppColor.strongText)
        }
    }

    private var headerTitle: String {
        switch phase {
        case .setup:
            return "Sesión de ritmo"
        case .running:
            return "Enfoque activo"
        case .review:
            return "¿Qué completaste?"
        }
    }

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            FocusDurationPicker(selectedDuration: $selectedDuration)

            FocusHabitPicker(
                habits: habits,
                selectedHabitIDs: $selectedHabitIDs
            )

            Button {
                startSession()
            } label: {
                Text("Iniciar sesión")
                    .font(AppFont.body2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(selectedHabitIDs.isEmpty ? AppColor.subtleText : AppColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedHabitIDs.isEmpty)
        }
    }

    private var runningContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            FocusTimerCard(
                timeText: runningTimeText,
                progress: session?.progress(reference: now),
                selectedCount: selectedHabitIDs.count,
                onFinish: { finishSession(reference: .now) }
            )

            FocusSelectedHabitsCard(habits: selectedHabits)
        }
    }

    private var reviewContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Marca solo lo que completaste durante esta sesión. Estas marcas pesan más en Insights porque nacen en tiempo real.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            FocusReviewChecklist(
                habits: selectedHabits,
                completedHabitIDs: $completedHabitIDs
            )

            Button {
                saveSessionResults()
            } label: {
                Text(completedHabitIDs.isEmpty ? "Cerrar sin marcas" : "Guardar marcas")
                    .font(AppFont.body2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(AppColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var selectedHabits: [Habit] {
        habits.filter { selectedHabitIDs.contains($0.id) }
    }

    private var runningTimeText: String {
        guard let session else { return "0:00" }

        if let remaining = session.remainingSeconds(reference: now) {
            return FocusTimeFormatter.string(from: remaining)
        }

        return FocusTimeFormatter.string(from: session.elapsedSeconds(reference: now))
    }

    private func startSession() {
        let newSession = FocusSession(
            selectedHabitIDs: selectedHabitIDs,
            durationSeconds: selectedDuration.durationSeconds,
            startedAt: .now
        )

        modelContext.insert(newSession)
        session = newSession
        now = .now

        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .running
        }
    }

    private func finishSession(reference: Date) {
        guard phase == .running else { return }
        session?.finishForReview(reference: reference)

        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .review
        }
    }

    private func saveSessionResults() {
        guard let session else {
            dismiss()
            return
        }

        let completedAt = session.endedAt ?? .now

        for habit in selectedHabits where completedHabitIDs.contains(habit.id) {
            markCompleted(habit, completedAt: completedAt, sessionID: session.id)
        }

        session.complete(completedHabitIDs: completedHabitIDs, reference: completedAt)
        dismiss()
    }

    private func markCompleted(_ habit: Habit, completedAt: Date, sessionID: UUID) {
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, completedAt)
        }

        if let firstEntry = entriesForDay.first {
            firstEntry.completedAt = completedAt
            firstEntry.source = .focusSession
            firstEntry.focusSessionID = sessionID

            for duplicate in entriesForDay.dropFirst() {
                modelContext.delete(duplicate)
            }
        } else {
            modelContext.insert(
                HabitEntry(
                    date: completedAt,
                    completedAt: completedAt,
                    source: .focusSession,
                    focusSessionID: sessionID,
                    habit: habit
                )
            )
        }
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

#Preview {
    FocusSessionView(
        habits: [
            Habit(
                title: "Leer 20 páginas",
                category: .learning,
                targetDaysPerWeek: 4,
                activeDaysOfWeek: [.monday, .wednesday, .friday]
            )
        ]
    )
}
