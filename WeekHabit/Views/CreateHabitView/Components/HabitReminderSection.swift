//
//  HabitReminderSection.swift
//  WeekHabit
//
//  Flujo de permisos:
//   - .notDetermined → CTA "Activar recordatorios" pide permiso desde la app.
//   - .denied → banner explicando + abrir Ajustes (no se puede pedir de nuevo).
//   - .authorized / .provisional → toggle + hora.
//

import SwiftUI
import UserNotifications

struct HabitReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTime: Date

    let authorizationStatus: UNAuthorizationStatus
    var onRequestAuthorization: () -> Void = {}

    private var canScheduleReminders: Bool {
        authorizationStatus.allowsReminderScheduling
    }

    var body: some View {
        CreateHabitFormSection(
            title: "Recordatorio",
            helper: "Una hora fija reduce el olvido sin depender de la motivación."
        ) {
            switch authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                authorizedContent
            case .denied:
                deniedBanner
            case .notDetermined:
                notDeterminedBanner
            @unknown default:
                deniedBanner
            }
        }
    }

    private var authorizedContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Toggle("Recordarme este hábito", isOn: $isReminderEnabled)
                .font(AppFont.body)
                .tint(AppColor.accent)

            if isReminderEnabled {
                DatePicker(
                    "Hora",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .font(AppFont.body)
                .tint(AppColor.accent)
            }
        }
    }

    private var notDeterminedBanner: some View {
        NotificationPermissionBanner(
            icon: "bell.badge",
            iconColor: AppColor.accent,
            tint: AppColor.accentMuted,
            title: "Activa los recordatorios",
            message: "Para que pueda avisarte a la hora elegida.",
            actionTitle: "Activar recordatorios",
            action: onRequestAuthorization
        )
    }

    private var deniedBanner: some View {
        NotificationPermissionBanner(
            icon: "bell.slash",
            iconColor: AppColor.warning,
            tint: AppColor.warning.opacity(0.14),
            title: "Recordatorios deshabilitados",
            message: "Los apagaste antes. Puedes reactivarlos en Ajustes.",
            actionTitle: "Abrir Ajustes",
            action: { NotificationPermissionBanner.openSettings() }
        )
    }
}
