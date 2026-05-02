//
//  HabitScheduleSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitScheduleSection: View {
    @Binding var scheduleKind: HabitScheduleKind
    @Binding var timesPerWeek: Int
    @Binding var selectedActiveDays: Set<Weekday>

    var body: some View {
        CreateHabitFormSection(title: "Ritmo") {
            HabitScheduleSelector(
                scheduleKind: $scheduleKind,
                selectedActiveDays: $selectedActiveDays
            )

            if scheduleKind == .specificDays {
                WeekdaySelectionComponent(selectedDays: $selectedActiveDays)
            } else if scheduleKind == .timesPerWeek {
                TimesPerWeekComponent(timesPerWeek: $timesPerWeek)
            }
        }
    }
}
