//
//  HabitEndDateSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitEndDateSection: View {
    @Binding var hasEndDate: Bool
    @Binding var endsAt: Date

    var body: some View {
        CreateHabitFormSection(title: "Finalización") {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                Toggle("Tiene fecha final", isOn: $hasEndDate)
                    .font(AppFont.body)
                    .tint(AppColor.accent)

                if hasEndDate {
                    DatePicker(
                        "Termina",
                        selection: $endsAt,
                        displayedComponents: .date
                    )
                    .font(AppFont.body)
                    .tint(AppColor.accent)
                }
            }
        }
    }
}
