//
//  PlanMeasurableSection.swift
//  WeekHabit
//

import SwiftUI

struct PlanMeasurableSection: View {
    @Binding var measurableOutcome: String

    var body: some View {
        WHFormSection(
            title: "Resultado medible",
            helper: "Opcional. Define cómo sabrás que lo lograste."
        ) {
            TextField(
                "",
                text: $measurableOutcome,
                prompt: Text("Ej: Correr 5K en 25 min, meditar 50 días en 90...")
                    .foregroundColor(AppColor.textTertiary),
                axis: .vertical
            )
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .tint(AppColor.accent)
            .lineLimit(1...3)
            .padding(AppSpacing.m)
            .background(AppColor.bgSunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        }
    }
}
