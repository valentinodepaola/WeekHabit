//
//  NotificationPermissionBanner.swift
//  WeekHabit
//
//  Banner de permiso de notificaciones: ícono, título, explicación y una acción. Lo usan el
//  recordatorio por hábito y la pantalla de avisos, con el mismo flujo de tres estados:
//   - .notDetermined → pedir permiso desde la app.
//   - .denied → explicar y abrir Ajustes (no se puede volver a pedir).
//   - .authorized / .provisional → no hay banner: se muestran los controles.
//

import SwiftUI

struct NotificationPermissionBanner: View {
    let icon: String
    let iconColor: Color
    let tint: Color
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
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

    /// Abre la página de la app en Ajustes, único camino tras un permiso denegado.
    static func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
