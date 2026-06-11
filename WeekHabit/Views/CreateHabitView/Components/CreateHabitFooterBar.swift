//
//  CreateHabitFooterBar.swift
//  WeekHabit
//
//  CTA fijo del wizard. Cuando el paso está incompleto muestra el motivo
//  encima del botón en lugar de dejar un botón deshabilitado sin explicación.
//

import SwiftUI

struct CreateHabitFooterBar: View {
    let primaryTitle: String
    let isDisabled: Bool
    let blockerMessage: String?
    let onPrimary: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.s) {
            if let blockerMessage {
                Text(blockerMessage)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }

            WHButton(
                title: primaryTitle,
                variant: .primary,
                isDisabled: isDisabled,
                action: onPrimary
            )
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.top, AppSpacing.m)
        .padding(.bottom, AppSpacing.s)
        .background(AppColor.bgCanvas)
        .overlay(alignment: .top) {
            AppColor.divider
                .frame(height: 1)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        CreateHabitFooterBar(
            primaryTitle: "Continuar",
            isDisabled: true,
            blockerMessage: "Escribe qué vas a hacer para continuar.",
            onPrimary: {}
        )
        CreateHabitFooterBar(
            primaryTitle: "Crear hábito",
            isDisabled: false,
            blockerMessage: nil,
            onPrimary: {}
        )
    }
    .background(AppColor.bgCanvas)
}
