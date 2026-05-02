//
//  HabitScheduleSelector.swift
//  WeekHabit
//

import SwiftUI

struct HabitScheduleSelector: View {
    @Binding var scheduleKind: HabitScheduleKind
    @Binding var selectedActiveDays: Set<Weekday>

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
