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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColor.accent.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: "flask")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("EXPERIMENTO ACTIVO")
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .tracking(1)

                Text(title)
                    .font(AppFont.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)

                Text(detailText)
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }

    private var detailText: String {
        if let suggestedHourText = experiment.suggestedHourText {
            return "\(remainingText) · \(experiment.daySummary) · \(suggestedHourText)"
        }

        return "\(remainingText) · \(experiment.daySummary)"
    }
}
