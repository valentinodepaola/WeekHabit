//
//  HabitScheduleSelector.swift
//  WeekHabit
//

import SwiftUI

struct HabitScheduleSelector: View {
    @Binding var scheduleKind: HabitScheduleKind
    @Binding var selectedActiveDays: Set<Weekday>
    var showFlexible: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            HabitOptionButton(
                title: "Diario",
                subtitle: "Todos los días",
                icon: "sun.max.fill",
                isSelected: scheduleKind == .daily
            ) {
                scheduleKind = .daily
            }

            HabitOptionButton(
                title: "Días específicos",
                subtitle: "Elige L, M, X...",
                icon: "calendar.badge.checkmark",
                isSelected: scheduleKind == .specificDays
            ) {
                scheduleKind = .specificDays
                if selectedActiveDays.isEmpty {
                    selectedActiveDays = [.monday, .wednesday, .friday]
                }
            }

            if showFlexible {
                HabitOptionButton(
                    title: "Veces por semana",
                    subtitle: "Flexible, sin días fijos",
                    icon: "repeat.circle.fill",
                    isSelected: scheduleKind == .timesPerWeek
                ) {
                    scheduleKind = .timesPerWeek
                }
            }
        }
    }
}

#Preview("Con flexible") {
    @Previewable @State var scheduleKind: HabitScheduleKind = .daily
    @Previewable @State var selectedActiveDays: Set<Weekday> = []

    HabitScheduleSelector(scheduleKind: $scheduleKind, selectedActiveDays: $selectedActiveDays)
        .padding()
        .background(AppColor.bgCanvas)
}

#Preview("Hábito a dejar") {
    @Previewable @State var scheduleKind: HabitScheduleKind = .specificDays
    @Previewable @State var selectedActiveDays: Set<Weekday> = [.monday, .wednesday, .friday]

    HabitScheduleSelector(
        scheduleKind: $scheduleKind,
        selectedActiveDays: $selectedActiveDays,
        showFlexible: false
    )
    .padding()
    .background(AppColor.bgCanvas)
}
