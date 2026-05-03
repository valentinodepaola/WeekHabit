//
//  PlanScheduleSection.swift
//  WeekHabit
//

import SwiftUI

struct PlanScheduleSection: View {
    @Binding var endsAt: Date

    private var minimumDate: Date {
        AppCalendar.current.date(byAdding: .day, value: 1, to: AppCalendar.startOfDay(for: .now)) ?? .now
    }

    var body: some View {
        CreateHabitFormSection(title: "Fecha de fin") {
            DatePicker(
                "Termina el",
                selection: $endsAt,
                in: minimumDate...,
                displayedComponents: .date
            )
            .font(AppFont.body2)
            .tint(AppColor.accent)
        }
    }
}
