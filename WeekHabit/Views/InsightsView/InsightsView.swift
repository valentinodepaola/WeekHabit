//
//  InsightsView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]

    @State private var editRoute: InsightsEditHabitRoute?

    private var referenceDate: Date {
        .now
    }

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

    private var suggestion: RhythmExperimentSuggestion? {
        habits.rhythmExperimentSuggestion(
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
                    VStack(alignment: .leading, spacing: 16) {
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
                                    suggestion: suggestion,
                                    onStart: startExperiment
                                )

                                ForEach(activeExperiments) { experiment in
                                    ActiveExperimentCard(
                                        experiment: experiment,
                                        habit: habit(for: experiment),
                                        referenceDate: referenceDate
                                    )
                                }

                                summaryCards
                            } else {
                                warmupCard
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 15)
                    .padding(.bottom, 120)
                }
            }
            .fullScreenCover(item: $editRoute) { route in
                CreateHabitView(habitToEdit: route.habit)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ÚLTIMOS 30 DÍAS")
                .font(AppFont.captionApp)
                .fontWeight(.bold)
                .foregroundStyle(AppColor.subtleText)
                .tracking(2)

            Text("Tu ritmo")
                .font(AppFont.title)
                .foregroundStyle(AppColor.strongText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var warmupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColor.editAction.opacity(0.14))
                        .frame(width: 46, height: 46)

                    Image(systemName: "hourglass")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(AppColor.editAction)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("INSIGHTS EN PREPARACIÓN")
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.mutedText)
                        .tracking(1)

                    Text(readiness.remainingDays == 1 ? "Falta 1 día" : "Faltan \(readiness.remainingDays) días")
                        .font(AppFont.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.strongText)
                }
            }

            Text("Voy a esperar 5 días desde tu primer hábito para juntar una base más justa. Mientras tanto, la gráfica sí seguirá reaccionando a lo que marques.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColor.bgLight)

                        Capsule()
                            .fill(AppColor.editAction)
                            .frame(width: max(8, proxy.size.width * readiness.progress))
                    }
                }
                .frame(height: 8)

                Text("\(min(readiness.elapsedDays, readiness.requiredDays)) de \(readiness.requiredDays) días de contexto")
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.accent)

            Text("Aún no hay ritmo que leer")
                .font(AppFont.subtitle3)
                .foregroundStyle(AppColor.strongText)

            Text("Cuando empieces a marcar hábitos, esta pantalla detectará patrones y te propondrá pruebas de 7 días.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private var summaryCards: some View {
        VStack(spacing: 14) {
            if let top = habits.topConsistentHabit(reference: referenceDate) {
                InsightSummaryCard(
                    icon: "brain.head.profile",
                    iconColor: AppColor.highPurple,
                    title: "EL MÁS CONSISTENTE",
                    value: top.habit.title,
                    detail: top.detail
                )
            }

            if let attention = habits.attentionHabit(reference: referenceDate) {
                InsightSummaryCard(
                    icon: attention.habit.displayCategory.icon,
                    iconColor: attention.habit.displayCategory.color,
                    title: "NECESITA ATENCIÓN",
                    value: attention.habit.title,
                    detail: attention.detail,
                    actionTitle: "Editar",
                    action: { editRoute = InsightsEditHabitRoute(habit: attention.habit) }
                )
            }

            if let bestDay = habits.bestWeekday(reference: referenceDate) {
                InsightSummaryCard(
                    icon: "calendar",
                    iconColor: AppColor.editAction,
                    title: "TU MEJOR DÍA",
                    value: bestDay.weekday.displayName,
                    detail: "\(Int((bestDay.ratio * 100).rounded()))% de cumplimiento promedio"
                )
            }

            if let peakHour = habits.peakHour(reference: referenceDate) {
                InsightSummaryCard(
                    icon: "clock",
                    iconColor: AppColor.highPurple,
                    title: "TU HORA PUNTA",
                    value: peakHour.displayText,
                    detail: "basada en \(peakHour.count) marcas reales"
                )
            }
        }
    }

    private func habit(for experiment: HabitExperiment) -> Habit? {
        habits.first { $0.id == experiment.habitID }
    }

    private func startExperiment(_ suggestion: RhythmExperimentSuggestion) {
        guard experiments.activeExperiment(for: suggestion.habit.id, reference: referenceDate) == nil else {
            return
        }

        let experiment = HabitExperiment(
            habit: suggestion.habit,
            experimentTargetDaysPerWeek: suggestion.targetDaysPerWeek,
            experimentActiveDaysOfWeek: suggestion.activeDays,
            suggestedStartHour: suggestion.suggestedStartHour,
            baselineConsistency: suggestion.baselineConsistency,
            startedAt: referenceDate
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            experiment.apply(to: suggestion.habit)
            modelContext.insert(experiment)
        }
    }

    private func keep(_ experiment: HabitExperiment) {
        withAnimation(.easeInOut(duration: 0.2)) {
            experiment.keep(reference: referenceDate)
        }
    }

    private func revert(_ experiment: HabitExperiment, habit: Habit) {
        withAnimation(.easeInOut(duration: 0.2)) {
            experiment.revert(on: habit, reference: referenceDate)
        }
    }
}

private struct InsightsEditHabitRoute: Identifiable {
    let habit: Habit

    var id: UUID {
        habit.id
    }
}

#Preview {
    InsightsView()
}
