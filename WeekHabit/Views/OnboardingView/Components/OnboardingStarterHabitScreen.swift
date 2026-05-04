//
//  OnboardingStarterHabitScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingStarterHabitScreen: View {
    @Binding var selectedTemplateID: StarterHabitTemplate.ID

    let templates: [StarterHabitTemplate]
    let onStartWeek: () -> Void
    let onCreateFromScratch: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                (
                    Text("Empieza con ")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)
                    +
                    Text("uno pequeño")
                        .font(AppFont.title.italic())
                        .foregroundStyle(AppColor.accent)
                )
                .fixedSize(horizontal: false, vertical: true)

                Text("Elige una plantilla o crea el tuyo. Siempre puedes cambiarlo.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 44)
            .padding(.bottom, 28)

            VStack(spacing: 12) {
                ForEach(templates) { template in
                    StarterHabitRow(
                        template: template,
                        isSelected: selectedTemplateID == template.id
                    ) {
                        selectedTemplateID = template.id
                    }
                }
            }
            .padding(.horizontal, 22)

            Spacer()

            OnboardingPrimaryButton(title: "Empezar mi semana", action: onStartWeek)
                .padding(.horizontal, 28)
                .padding(.bottom, 18)

            Button("o crear uno desde cero", action: onCreateFromScratch)
                .font(AppFont.captionApp)
                .foregroundStyle(AppColor.subtleText)
                .underline()
                .padding(.bottom, 34)
        }
        .onChange(of: templates.map(\.id)) { _, ids in
            guard let first = ids.first, !ids.contains(selectedTemplateID) else { return }
            selectedTemplateID = first
        }
    }
}
