//
//  InsightsView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    @State private var habitRoute: HabitRoute?

    private var referenceDate: Date { .now }

    private var snapshot: GlobalInsightSnapshot {
        habits.globalInsightSnapshot(reference: referenceDate)
    }

    private var readiness: InsightReadiness {
        habits.insightReadiness(reference: referenceDate)
    }

    private var confidence: RhythmConfidence {
        habits.rhythmConfidence(reference: referenceDate)
    }

    private var activeExperimentIDs: Set<UUID> {
        experiments.activeHabitIDs(reference: referenceDate)
    }

    private var buildHabits: [Habit] {
        habits.filter { !$0.isBreakHabit }
    }

    private var breakHabits: [Habit] {
        habits.filter { $0.isBreakHabit }
    }

    private var urgePeakInsight: UrgePeakHourInsight? {
        breakHabits.urgePeakHourInsight(reference: referenceDate)
    }

    private var suggestions: [RankedRhythmSuggestion] {
        buildHabits.rhythmExperimentSuggestions(
            reference: referenceDate,
            excludingHabitIDs: activeExperimentIDs
        )
    }

    private var reviewExperiments: [HabitExperiment] {
        experiments.filter { $0.needsReview(reference: referenceDate) }
    }

    private var activeExperiments: [HabitExperiment] {
        experiments.filter { $0.isActive(reference: referenceDate) }
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.l) {
                        header

                        if habits.isEmpty {
                            emptyState
                        } else {
                            InsightsHeroCard(snapshot: snapshot, readiness: readiness)

                            if readiness.isReady {
                                InsightConfidenceCard(confidence: confidence)

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

                                RhythmExperimentCard(
                                    suggestions: suggestions,
                                    onStart: startExperiment
                                )

                                ForEach(activeExperiments) { experiment in
                                    ActiveExperimentCard(
                                        experiment: experiment,
                                        habit: habit(for: experiment),
                                        referenceDate: referenceDate
                                    )
                                }

                                if let urgePeakInsight {
                                    UrgePeakHoursCard(
                                        insight: urgePeakInsight,
                                        buckets: breakHabits.urgeHourBuckets(reference: referenceDate)
                                    )
                                }

                                summaryCards
                            } else {
                                warmupCard
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.l)
                    .padding(.top, AppSpacing.l)
                    .padding(.bottom, AppSpacing.xl)
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
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("ÚLTIMOS 30 DÍAS")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(1.2)

            Text("Tu ritmo")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var warmupCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(AppColor.warning.opacity(0.14))
                    Image(systemName: "hourglass")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(AppColor.warning)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("INSIGHTS EN PREPARACIÓN")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(0.8)

                    Text(readiness.remainingDays == 1 ? "Falta 1 día" : "Faltan \(readiness.remainingDays) días")
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                }

                Spacer()
            }

            Text("Voy a esperar 5 días desde tu primer hábito para juntar una base más justa. Mientras tanto, la gráfica sí seguirá reaccionando a lo que marques.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: AppSpacing.s) {
                WHProgressBar(
                    progress: readiness.progress,
                    progressColor: AppColor.warning,
                    height: 8
                )

                Text("\(min(readiness.elapsedDays, readiness.requiredDays)) de \(readiness.requiredDays) días de contexto")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.accent)

            Text("Aún no hay ritmo que leer")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text("Cuando empieces a marcar hábitos, esta pantalla detectará patrones y te propondrá pruebas de 7 días.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }

    private var summaryCards: some View {
        VStack(spacing: AppSpacing.m) {
            if let top = habits.topConsistentHabit(reference: referenceDate) {
                InsightSummaryCard(
                    icon: "brain.head.profile",
                    iconColor: AppColor.info,
                    title: "EL MÁS CONSISTENTE",
                    value: top.habit.title,
                    detail: top.detail,
                    isProvisional: top.habit.insightReadiness(reference: referenceDate).isProvisional
                )
            }

            if let attention = habits.attentionHabit(reference: referenceDate) {
                InsightSummaryCard(
                    icon: attention.habit.iconName,
                    iconColor: attention.habit.habitColor,
                    title: attention.failureType?.title.uppercased(with: Locale(identifier: "es_MX")) ?? "NECESITA ATENCIÓN",
                    value: attention.habit.title,
                    detail: attention.recommendation ?? attention.detail,
                    isProvisional: attention.habit.insightReadiness(reference: referenceDate).isProvisional,
                    actionTitle: "Editar",
                    action: { habitRoute = .edit(attention.habit) }
                )
            }

            if let bestDay = habits.contextualBestWeekday(reference: referenceDate) {
                InsightSummaryCard(
                    icon: "calendar",
                    iconColor: AppColor.success,
                    title: "TU MEJOR DÍA",
                    value: bestDay.performance.weekday.displayName,
                    detail: bestDay.contextText,
                    isProvisional: readiness.isProvisional
                )
            }

            if let peakHour = buildHabits.contextualPeakHour(reference: referenceDate) {
                InsightSummaryCard(
                    icon: "clock",
                    iconColor: AppColor.info,
                    title: "TU HORA PUNTA",
                    value: peakHour.window.displayText,
                    detail: peakHour.contextText,
                    isProvisional: readiness.isProvisional
                )
            }
        }
    }

    private func habit(for experiment: HabitExperiment) -> Habit? {
        habits.first { $0.id == experiment.habitID }
    }

    private func startExperiment(_ suggestion: RhythmExperimentSuggestion) {
        do {
            let didStart = try withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
                try HabitExperimentService.start(
                    suggestion: suggestion,
                    existingExperiments: experiments,
                    reference: referenceDate,
                    modelContext: modelContext
                ) != nil
            }

            if didStart {
                AppHaptics.play(.experimentApplied)
            }
        } catch {
            assertionFailure("Failed to start habit experiment: \(error)")
        }
    }

    private func keep(_ experiment: HabitExperiment) {
        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            experiment.keep(reference: referenceDate)
        }
        AppHaptics.play(.experimentApplied)
    }

    private func revert(_ experiment: HabitExperiment, habit: Habit) {
        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            experiment.revert(on: habit, reference: referenceDate)
        }
        AppHaptics.play(.selection)
    }
}

#Preview {
    InsightsView()
}
