//
//  OnboardingAreasScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingAreasScreen: View {
    @Binding var selectedAreas: Set<HabitCategory>
    let onContinue: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                (
                    Text("¿Qué áreas ")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)
                    +
                    Text("te importan?")
                        .font(AppFont.title.italic())
                        .foregroundStyle(AppColor.accent)
                )
                .fixedSize(horizontal: false, vertical: true)

                Text("Elige una o varias. Te sugeriremos hábitos para arrancar.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(2)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 76)
            .padding(.bottom, 28)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(OnboardingAreaOption.all) { option in
                    OnboardingAreaCard(
                        option: option,
                        isSelected: selectedAreas.contains(option.category)
                    ) {
                        toggle(option.category)
                    }
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            OnboardingPrimaryButton(title: "Continuar", action: onContinue)
                .padding(.horizontal, 28)
                .padding(.bottom, 34)
        }
    }

    private func toggle(_ category: HabitCategory) {
        if selectedAreas.contains(category) {
            selectedAreas.remove(category)
        } else {
            selectedAreas.insert(category)
        }
    }
}
