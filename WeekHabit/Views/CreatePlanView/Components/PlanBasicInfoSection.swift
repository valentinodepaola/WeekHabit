//
//  PlanBasicInfoSection.swift
//  WeekHabit
//
//  Secciones por intención: "Tu meta" (qué) y "Por qué importa" (motivación).
//

import SwiftUI

struct PlanBasicInfoSection: View {
    @Binding var planName: String
    @Binding var motivation: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            WHFormSection(
                title: "Tu meta",
                helper: "Una dirección concreta. Ej: Maratón septiembre, Mes sin alcohol."
            ) {
                TextField(
                    "",
                    text: $planName,
                    prompt: Text("¿Qué quieres lograr?")
                        .foregroundColor(AppColor.textTertiary)
                )
                .font(AppFont.body)
                .foregroundStyle(AppColor.textPrimary)
                .tint(AppColor.accent)
                .padding(AppSpacing.m)
                .background(AppColor.bgSunken)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            }

            WHFormSection(
                title: "Por qué importa",
                helper: "La motivación se vuelve mensaje en tus recordatorios."
            ) {
                ZStack(alignment: .topLeading) {
                    if motivation.isEmpty {
                        Text("¿Por qué quieres lograr esto?")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.textTertiary)
                            .padding(.horizontal, AppSpacing.s)
                            .padding(.vertical, AppSpacing.s)
                    }
                    TextEditor(text: $motivation)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                        .tint(AppColor.accent)
                        .frame(minHeight: 80, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                }
                .padding(AppSpacing.s)
                .background(AppColor.bgSunken)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            }
        }
    }
}
