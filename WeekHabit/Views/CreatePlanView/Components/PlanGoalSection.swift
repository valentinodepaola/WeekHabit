//
//  PlanGoalSection.swift
//  WeekHabit
//

import SwiftUI

struct PlanGoalSection: View {
    @Binding var targetCompletionRate: Double

    private var percentText: String {
        "\(Int(targetCompletionRate * 100))%"
    }

    var body: some View {
        CreateHabitFormSection(title: "Meta de completitud") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Completar al menos")
                        .font(AppFont.body2)
                        .foregroundStyle(AppColor.strongText)
                    Spacer()
                    Text(percentText)
                        .font(AppFont.subtitle2)
                        .foregroundStyle(AppColor.accent)
                        .monospacedDigit()
                }

                Slider(value: $targetCompletionRate, in: 0.5...1.0, step: 0.05)
                    .tint(AppColor.accent)

                HStack {
                    Text("50%")
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                    Spacer()
                    Text("100%")
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                }
            }
        }
    }
}
