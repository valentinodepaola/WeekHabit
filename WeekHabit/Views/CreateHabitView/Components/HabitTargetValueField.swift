//
//  HabitTargetValueField.swift
//  WeekHabit
//

import SwiftUI

struct HabitTargetValueField: View {
    @Binding var targetValueText: String
    let unitLabel: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meta por sesión")
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.subtleText)

                TextField("20", text: $targetValueText)
                    .font(AppFont.subtitle)
                    .keyboardType(.decimalPad)
            }

            Text(unitLabel)
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
        }
        .padding()
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}
