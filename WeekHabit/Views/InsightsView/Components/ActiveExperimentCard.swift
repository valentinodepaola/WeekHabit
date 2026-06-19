//
//  ActiveExperimentCard.swift
//  WeekHabit
//

import SwiftUI

struct ActiveExperimentCard: View {
    let experiment: HabitExperiment
    let habit: Habit?
    let referenceDate: Date

    private var title: String {
        habit?.title ?? experiment.habitTitle
    }

    private var remainingText: String {
        let days = experiment.daysRemaining(reference: referenceDate)
        if days == 0 { return "termina hoy" }
        if days == 1 { return "queda 1 día" }
        return "quedan \(days) días"
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(AppColor.info.opacity(0.14))
                Image(systemName: "flask")
                    .font(AppFont.iconMedium)
                    .foregroundStyle(AppColor.info)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("EXPERIMENTO ACTIVO")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)

                Text(title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(detailText)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .insightCard(background: AppColor.infoMuted.opacity(0.5), elevation: nil)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(AppColor.info.opacity(0.18), lineWidth: 1)
        }
    }

    private var detailText: String {
        if let suggestedHourText = experiment.suggestedHourText {
            return "\(remainingText) · \(experiment.daySummary) · \(suggestedHourText)"
        }
        return "\(remainingText) · \(experiment.daySummary)"
    }
}
