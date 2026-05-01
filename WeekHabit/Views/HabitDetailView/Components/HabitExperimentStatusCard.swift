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
        experiment.needsReview(reference: referenceDate) ? "Prueba lista para revisar" : "Prueba de 7 días activa"
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
        HStack(spacing: 12) {
            Image(systemName: "flask")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.accent)
                .frame(width: 34, height: 34)
                .background(AppColor.accent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.strongText)

                Text(detail)
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(AppColor.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}
