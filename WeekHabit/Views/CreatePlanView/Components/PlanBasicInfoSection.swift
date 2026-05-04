//
//  PlanBasicInfoSection.swift
//  WeekHabit
//

import SwiftUI

struct PlanBasicInfoSection: View {
    @Binding var planName: String
    @Binding var motivation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextFieldComponent(
                titleSection: "Nombre",
                placeholder: "Maratón septiembre",
                habitName: $planName,
                normalTextField: true
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Motivación (opcional)")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
                    .textCase(.uppercase)

                ZStack(alignment: .topLeading) {
                    if motivation.isEmpty {
                        Text("¿Por qué quieres lograr esto?")
                            .font(AppFont.body2)
                            .foregroundStyle(AppColor.subtleText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $motivation)
                        .font(AppFont.body2)
                        .foregroundStyle(AppColor.strongText)
                        .tint(AppColor.accent)
                        .frame(minHeight: 80, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                }
                .padding(10)
                .background(AppColor.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
        }
    }
}
