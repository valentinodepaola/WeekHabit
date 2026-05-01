//
//  ExperimentReviewCard.swift
//  WeekHabit
//

import SwiftUI

struct ExperimentReviewCard: View {
    let experiment: HabitExperiment
    let habit: Habit
    let referenceDate: Date
    let onKeep: () -> Void
    let onRevert: () -> Void

    private var currentConsistency: Double {
        experiment.currentConsistency(for: habit, reference: referenceDate)
    }

    private var delta: Int {
        Int(((currentConsistency - experiment.baselineConsistency) * 100).rounded())
    }

    private var resultText: String {
        if delta > 0 { return "Mejoró \(delta) puntos." }
        if delta < 0 { return "Bajó \(abs(delta)) puntos." }
        return "Se mantuvo estable."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LISTO PARA REVISAR")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .tracking(1.3)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(AppFont.subtitle3)
                    .foregroundStyle(AppColor.strongText)

                Text(resultText)
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)

                Text("Decide si este ritmo se queda o volvemos al anterior.")
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
            }

            HStack(spacing: 10) {
                Button("Volver") {
                    onRevert()
                }
                .font(AppFont.body2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.mutedText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppColor.bgLight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

                Button("Conservar") {
                    onKeep()
                }
                .font(AppFont.body2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}
