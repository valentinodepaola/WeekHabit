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
            Toggle("Tiene fecha final", isOn: $hasEndDate)
                .font(AppFont.body2)
                .tint(AppColor.accent)

            if hasEndDate {
                DatePicker(
                    "Termina",
                    selection: $endsAt,
                    displayedComponents: .date
                )
                .font(AppFont.body2)
                .tint(AppColor.accent)
            }
        }
    }
}
