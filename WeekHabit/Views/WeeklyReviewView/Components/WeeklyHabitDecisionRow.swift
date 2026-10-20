//
//  WeeklyHabitDecisionRow.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct WeeklyHabitDecisionRow: View {
    let habit: Habit
    let summary: WeeklyHabitSummary
    @Binding var decision: WeeklyReviewDecisionKind
    let onAdjust: () -> Void
    let onPause: () -> Void

    private var detailText: String {
        if summary.scheduled == 0 {
            return "Sin días programados esta semana"
        }

        if let reason = summary.dominantFailureReason {
            return "\(summary.completed)/\(summary.scheduled) · aparece: \(AppFormatters.lowercased(reason.reason.title))"
        }

        if summary.hasActiveExperiment {
            return "\(summary.completed)/\(summary.scheduled) · con experimento activo"
        }

        return "\(summary.completed)/\(summary.scheduled) marcas de la semana"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .center, spacing: AppSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                        .fill(habit.habitColor.opacity(0.14))
                    Image(systemName: habit.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(habit.habitColor)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(habit.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)

                    Text(detailText)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text(summary.scheduled == 0 ? "—" : "\(summary.percentage)%")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
            }

            WHProgressBar(
                progress: summary.completionRatio,
                progressColor: habit.habitColor,
                height: 7
            )

            HStack(spacing: AppSpacing.s) {
                decisionChip(.keep) {
                    decision = .keep
                }

                decisionChip(.adjust) {
                    decision = .adjust
                    onAdjust()
                }

                decisionChip(.pause) {
                    decision = .pause
                    onPause()
                }
            }
        }
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(decision == .keep ? AppColor.divider : AppColor.accent.opacity(0.26), lineWidth: 1)
        }
        .appElevation(.low)
    }

    private func decisionChip(
        _ kind: WeeklyReviewDecisionKind,
        action: @escaping () -> Void
    ) -> some View {
        WHChip(
            label: kind.title,
            icon: kind.iconName,
            isSelected: decision == kind,
            action: action
        )
    }
}

#Preview(traits: .sampleData) {
    @Previewable @Query(sort: \Habit.createdAt) var habits: [Habit]
    @Previewable @State var decisions: [UUID: WeeklyReviewDecisionKind] = [:]

    let weekStart = AppCalendar.weekRange(containing: PreviewSamples.day(-7)).lowerBound

    ScrollView {
        VStack(spacing: AppSpacing.m) {
            ForEach(habits) { habit in
                WeeklyHabitDecisionRow(
                    habit: habit,
                    summary: habit.weeklyDecisionSummary(weekStart: weekStart),
                    decision: Binding(
                        get: { decisions[habit.id] ?? .keep },
                        set: { decisions[habit.id] = $0 }
                    ),
                    onAdjust: {},
                    onPause: {}
                )
            }
        }
        .padding()
    }
    .background(AppColor.bgCanvas)
}
