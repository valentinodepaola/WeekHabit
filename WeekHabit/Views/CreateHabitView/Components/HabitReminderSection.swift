//
//  HabitReminderSection.swift
//  WeekHabit
//

import SwiftUI
import UserNotifications

struct HabitReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTime: Date

    let authorizationStatus: UNAuthorizationStatus

    private var canScheduleReminders: Bool {
        authorizationStatus.allowsReminderScheduling
    }

    var body: some View {
        CreateHabitFormSection(title: "Recordatorio") {
            Toggle("Recordarme este hábito", isOn: $isReminderEnabled)
                .font(AppFont.body2)
                .tint(AppColor.accent)
                .disabled(!canScheduleReminders)

            if canScheduleReminders, isReminderEnabled {
                DatePicker(
                    "Hora",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .font(AppFont.body2)
                .tint(AppColor.accent)
            } else if !canScheduleReminders {
                HStack(spacing: 8) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Activa los permisos en Ajustes")
                        .font(AppFont.body2)
                }
                .foregroundStyle(AppColor.subtleText)
            }
        }
    }
}
