//
//  WeeklyReviewView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct WeeklyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let weekStart: Date

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    @Query(sort: \WeeklyReview.reviewedAt, order: .reverse)
    private var reviews: [WeeklyReview]

    @AppStorage("weeklyReviewWeekdayRaw") private var weeklyReviewWeekdayRaw: Int = Weekday.sunday.rawValue
    @AppStorage("weeklyReviewHour") private var weeklyReviewHour: Int = 19
    @AppStorage("weeklyReviewMinute") private var weeklyReviewMinute: Int = 0
    @AppStorage("weeklyReviewAutoPresent") private var weeklyReviewAutoPresent: Bool = false

    @State private var decisions: [UUID: WeeklyReviewDecisionKind] = [:]
    @State private var reflectionText: String = ""
    @State private var habitRoute: HabitRoute?
    @State private var didConfirm = false
    @State private var saveFailure: WeeklyReviewSaveFailure?

    private var referenceDate: Date { .now }

    private var weekEnd: Date {
        AppCalendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    private var snapshot: GlobalInsightSnapshot {
        habits.weeklySnapshot(weekStart: weekStart, reference: referenceDate)
    }

    private var readiness: InsightReadiness {
        habits.insightReadiness(reference: referenceDate)
    }

    private var confidence: RhythmConfidence {
        habits.rhythmConfidence(lastDays: 7, reference: min(weekEnd, referenceDate))
    }

    private var reviewExperiments: [HabitExperiment] {
        experiments.filter { $0.needsReview(reference: referenceDate) }
    }

    private var reviewHabits: [Habit] {
        habits.filter { habit in
            let created = AppCalendar.startOfDay(for: habit.createdAt)
            let ended = habit.endsAt.map(AppCalendar.startOfDay(for:)) ?? weekEnd
            return created <= weekEnd
                && ended >= weekStart
                && !habit.isPaused(reference: referenceDate)
        }
    }

    private var buildHabits: [Habit] {
        habits.filter { !$0.isBreakHabit }
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        WeeklyReviewHeader(
                            weekRangeText: weekRangeText,
                            onClose: { dismiss() }
                        )

                        if reviewHabits.isEmpty {
                            emptyState
                        } else {
                            if readiness.isReady {
                                InsightsHeroCard(
                                    snapshot: snapshot,
                                    readiness: readiness,
                                    title: "CONSISTENCIA DE LA SEMANA",
                                    trendCaption: "Cada barra resume un día de esta semana."
                                )

                                InsightConfidenceCard(confidence: confidence)
                                weeklySummaryCards
                                experimentSection
                            } else {
                                warmupCard
                            }

                            habitDecisionSection
                            WeeklyReflectionPromptCard(text: $reflectionText)
                            reviewSettingsCard

                            WHButton(
                                title: "Cerrar revisión",
                                icon: "checkmark",
                                variant: .primary,
                                isDisabled: didConfirm,
                                action: confirmReview
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.l)
                    .padding(.top, AppSpacing.l)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .fullScreenCover(item: $habitRoute) { route in
                switch route {
                case .edit(let habit):
                    CreateHabitView(habitToEdit: habit)
                case .create(let prefill):
                    CreateHabitView(
                        initialDaysPerWeek: prefill.initialDaysPerWeek ?? 7,
                        initialActiveDays: prefill.initialActiveDays
                    )
                }
            }
            .task {
                seedDefaultDecisions()
            }
            .alert(item: $saveFailure) { failure in
                Alert(
                    title: Text("No se pudo guardar"),
                    message: Text(failure.message),
                    dismissButton: .default(Text("Entendido"))
                )
            }
        }
    }

    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    private var emptyState: some View {
        WHEmptyState(
            icon: "calendar.badge.checkmark",
            title: "Nada que revisar por ahora",
            message: "Cuando haya hábitos con una semana de contexto, la revisión aparecerá aquí."
        )
    }

    private var warmupCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "leaf")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.info)

                Text("REVISIÓN LIGERA")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)
            }

            Text("Todavía estoy juntando contexto para los insights. Puedes decidir hábito por hábito y cerrar la semana sin presión.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }

    @ViewBuilder
    private var weeklySummaryCards: some View {
        VStack(spacing: AppSpacing.m) {
            if let bestDay = habits.contextualBestWeekday(reference: min(weekEnd, referenceDate)) {
                InsightSummaryCard(
                    icon: "calendar",
                    iconColor: AppColor.success,
                    title: "MEJOR DÍA",
                    value: bestDay.performance.weekday.displayName,
                    detail: bestDay.contextText,
                    isProvisional: readiness.isProvisional
                )
            }

            if let peakHour = buildHabits.contextualPeakHour(reference: min(weekEnd, referenceDate)) {
                InsightSummaryCard(
                    icon: "clock",
                    iconColor: AppColor.info,
                    title: "HORA PICO",
                    value: peakHour.window.displayText,
                    detail: peakHour.contextText,
                    isProvisional: readiness.isProvisional
                )
            }
        }
    }

    @ViewBuilder
    private var experimentSection: some View {
        ForEach(reviewExperiments) { experiment in
            if let habit = habit(for: experiment) {
                ExperimentReviewCard(
                    experiment: experiment,
                    habit: habit,
                    referenceDate: referenceDate,
                    onKeep: { keep(experiment) },
                    onRevert: { revert(experiment, habit: habit) }
                )
            }
        }
    }

    private var habitDecisionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("HÁBITOS")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)

            ForEach(reviewHabits) { habit in
                WeeklyHabitDecisionRow(
                    habit: habit,
                    summary: habit.weeklyDecisionSummary(
                        weekStart: weekStart,
                        activeExperiment: experiments.activeExperiment(for: habit.id, reference: referenceDate)
                    ),
                    decision: decisionBinding(for: habit),
                    onAdjust: { habitRoute = .edit(habit) },
                    onPause: { pause(habit) }
                )
            }
        }
    }

    private var reviewSettingsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("RITUAL SEMANAL")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)

            Picker("Día de revisión", selection: $weeklyReviewWeekdayRaw) {
                ForEach(Weekday.ordered) { weekday in
                    Text(weekday.displayName).tag(weekday.rawValue)
                }
            }
            .pickerStyle(.menu)

            DatePicker(
                "Hora",
                selection: reviewTimeBinding,
                displayedComponents: .hourAndMinute
            )
            .font(AppFont.callout)
            .foregroundStyle(AppColor.textSecondary)

            Toggle("Abrir automáticamente", isOn: $weeklyReviewAutoPresent)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
        .onChange(of: weeklyReviewWeekdayRaw) { _, _ in refreshReviewNotification() }
        .onChange(of: weeklyReviewHour) { _, _ in refreshReviewNotification() }
        .onChange(of: weeklyReviewMinute) { _, _ in refreshReviewNotification() }
    }

    private var reviewTimeBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = weeklyReviewHour
                comps.minute = weeklyReviewMinute
                return AppCalendar.current.date(from: comps) ?? .now
            },
            set: { newValue in
                let comps = AppCalendar.current.dateComponents([.hour, .minute], from: newValue)
                weeklyReviewHour = comps.hour ?? weeklyReviewHour
                weeklyReviewMinute = comps.minute ?? weeklyReviewMinute
            }
        )
    }

    private func seedDefaultDecisions() {
        for habit in reviewHabits where decisions[habit.id] == nil {
            decisions[habit.id] = .keep
        }
    }

    private func decisionBinding(for habit: Habit) -> Binding<WeeklyReviewDecisionKind> {
        Binding(
            get: { decisions[habit.id] ?? .keep },
            set: { decisions[habit.id] = $0 }
        )
    }

    private func habit(for experiment: HabitExperiment) -> Habit? {
        habits.first { $0.id == experiment.habitID }
    }

    /// Solo registra la decisión en el estado local; la pausa real se aplica en `confirmReview`
    /// para evitar que el hábito desaparezca de `reviewHabits` antes de persistir la decisión.
    private func pause(_ habit: Habit) {
        AppHaptics.play(.selection)
    }

    private func keep(_ experiment: HabitExperiment) {
        do {
            try withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                try HabitExperimentService.keep(
                    experiment,
                    reference: referenceDate,
                    modelContext: modelContext
                )
            }
            AppHaptics.play(.experimentApplied)
        } catch {
            assertionFailure("Failed to keep habit experiment: \(error)")
        }
    }

    private func revert(_ experiment: HabitExperiment, habit: Habit) {
        do {
            try withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                try HabitExperimentService.revert(
                    experiment,
                    on: habit,
                    reference: referenceDate,
                    modelContext: modelContext
                )
            }
            AppHaptics.play(.selection)
        } catch {
            assertionFailure("Failed to revert habit experiment: \(error)")
        }
    }

    private func confirmReview() {
        guard !didConfirm else { return }
        didConfirm = true

        let input = WeeklyReviewInput(
            weekStart: weekStart,
            weekEnd: weekEnd,
            reflectionNote: reflectionText,
            decisions: decisions
        )

        let result: WeeklyReviewSaveResult
        do {
            result = try WeeklyReviewEditorService.save(
                input: input,
                habits: reviewHabits,
                existingReviews: reviews,
                reference: referenceDate,
                modelContext: modelContext
            )
        } catch {
            didConfirm = false
            saveFailure = WeeklyReviewSaveFailure(message: error.localizedDescription)
            return
        }

        guard result.didCreateReview else {
            dismiss()
            return
        }

        Task {
            for id in result.pausedHabitIDs {
                await HabitReminderService.cancelReminder(forHabitID: id)
            }
            await HabitReminderService.refreshAllReminders(for: habits)
        }

        AppHaptics.play(.experimentApplied)
        dismiss()
    }

    private func refreshReviewNotification() {
        let weekday = Weekday(rawValue: weeklyReviewWeekdayRaw) ?? .sunday
        Task {
            await WeeklyReviewService.refreshReviewReminder(
                weekday: weekday,
                hour: weeklyReviewHour,
                minute: weeklyReviewMinute
            )
        }
    }
}

private struct WeeklyReviewSaveFailure: Identifiable {
    let id = UUID()
    let message: String
}
