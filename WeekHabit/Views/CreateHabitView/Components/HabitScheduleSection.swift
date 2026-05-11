//
//  HabitScheduleSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitScheduleSection: View {
    @Binding var scheduleKind: HabitScheduleKind
    @Binding var timesPerWeek: Int
    @Binding var selectedActiveDays: Set<Weekday>
    var showFlexible: Bool = true

    var body: some View {
        CreateHabitFormSection(
            title: "Ritmo",
            helper: "La semana es la unidad. Empieza con menos de lo que crees."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HabitScheduleSelector(
                    scheduleKind: $scheduleKind,
                    selectedActiveDays: $selectedActiveDays,
                    showFlexible: showFlexible
                )

                if scheduleKind == .specificDays {
                    WeekdaySelectionComponent(selectedDays: $selectedActiveDays)
                } else if scheduleKind == .timesPerWeek {
                    TimesPerWeekComponent(timesPerWeek: $timesPerWeek)
                }
            }
        }
    }
}
