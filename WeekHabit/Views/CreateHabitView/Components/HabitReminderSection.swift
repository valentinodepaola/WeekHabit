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
        permissionBanner(
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
        permissionBanner(
            icon: "bell.slash",
            iconColor: AppColor.warning,
            tint: AppColor.warning.opacity(0.14),
            title: "Recordatorios deshabilitados",
            message: "Los apagaste antes. Puedes reactivarlos en Ajustes.",
            actionTitle: "Abrir Ajustes",
            action: openSettings
        )
    }

    private func permissionBanner(
        icon: String,
        iconColor: Color,
        tint: Color,
        title: String,
        message: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .top, spacing: AppSpacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(tint)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(message)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            WHButton(
                title: actionTitle,
                variant: .secondary,
                size: .compact,
                fullWidth: false,
                action: action
            )
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
