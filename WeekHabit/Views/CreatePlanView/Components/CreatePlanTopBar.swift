//
//  CreatePlanTopBar.swift
//  WeekHabit
//

import SwiftUI

struct CreatePlanTopBar: View {
    let isSaveDisabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.s) {
            Button(action: onCancel) {
                Text("Cancelar")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            WHButton(
                title: "Guardar",
                variant: .primary,
                size: .compact,
                fullWidth: false,
                isDisabled: isSaveDisabled,
                action: onSave
            )
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.s)
    }
}
