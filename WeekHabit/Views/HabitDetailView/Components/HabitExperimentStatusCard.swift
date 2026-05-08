//
//  HabitExperimentStatusCard.swift
//  WeekHabit
//

import SwiftUI

struct HabitExperimentStatusCard: View {
    let experiment: HabitExperiment
    let habit: Habit
    var referenceDate: Date = .now

    private var title: String {
        experiment.needsReview(reference: referenceDate)
            ? "Prueba lista para revisar"
            : "Prueba de 7 días activa"
    }

    private var detail: String {
        let consistency = Int((experiment.currentConsistency(for: habit, reference: referenceDate) * 100).rounded())
        let base = experiment.needsReview(reference: referenceDate)
            ? "Revisa el resultado en Insights"
            : "\(experiment.daysRemaining(reference: referenceDate)) días restantes"

        if let suggestedHourText = experiment.suggestedHourText {
            return "\(base) · \(experiment.daySummary) · \(suggestedHourText) · \(consistency)%"
        }
        return "\(base) · \(experiment.daySummary) · \(consistency)%"
    }

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "flask")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.info)
                .frame(width: 36, height: 36)
                .background(AppColor.infoMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)

                Text(detail)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppSpacing.m)
        .background(AppColor.infoMuted.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(AppColor.info.opacity(0.18), lineWidth: 1)
        }
    }
}
