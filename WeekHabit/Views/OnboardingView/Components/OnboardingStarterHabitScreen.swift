//
//  OnboardingStarterHabitScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingStarterHabitScreen: View {
    @Binding var selectedTemplateID: StarterHabitTemplate.ID

    let templates: [StarterHabitTemplate]
    let onContinue: () -> Void
    let onCreateFromScratch: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("Elige una plantilla o crea el tuyo. Siempre puedes cambiarlo.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)

            ScrollView {
                VStack(spacing: AppSpacing.s) {
                    ForEach(templates) { template in
                        StarterHabitRow(
                            template: template,
                            isSelected: selectedTemplateID == template.id
                        ) {
                            selectedTemplateID = template.id
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.l)
                .padding(.bottom, AppSpacing.s)
            }
            .scrollIndicators(.hidden)

            WHButton(title: "Empezar mi semana", variant: .primary, action: onContinue)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.s)

            Button("o crear uno desde cero", action: onCreateFromScratch)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .underline()
                .padding(.bottom, AppSpacing.xxl)
        }
        .onChange(of: templates.map(\.id)) { _, ids in
            guard let first = ids.first, !ids.contains(selectedTemplateID) else { return }
            selectedTemplateID = first
        }
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Empieza con")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("uno pequeño")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }
}
