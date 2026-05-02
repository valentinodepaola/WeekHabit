//
//  CreateHabitTopBar.swift
//  WeekHabit
//

import SwiftUI

struct CreateHabitTopBar: View {
    let isSaveDisabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Button("Cancelar", action: onCancel)
                .foregroundStyle(AppColor.mutedText)

            Spacer()

            Button(action: onSave) {
                Text("Guardar")
            }
            .buttonStyle(.borderedProminent)
            .fontWeight(.bold)
            .tint(AppColor.accent)
            .disabled(isSaveDisabled)
        }
        .padding(.horizontal)
    }
}
