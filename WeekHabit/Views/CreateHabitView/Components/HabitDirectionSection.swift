//
//  HabitDirectionSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitDirectionSection: View {
    @Binding var direction: HabitDirection

    var body: some View {
        CreateHabitFormSection(
            title: "Tipo de hábito",
            helper: "¿Quieres construir algo nuevo o eliminar algo que no te sirve?"
        ) {
            VStack(spacing: 10) {
                HabitOptionButton(
                    title: "Construir un hábito",
                    subtitle: "Quiero hacer esto regularmente",
                    icon: "plus.circle.fill",
                    isSelected: direction == .build
                ) {
                    direction = .build
                }

                HabitOptionButton(
                    title: "Eliminar un hábito",
                    subtitle: "Quiero dejar de hacer esto",
                    icon: "xmark.circle.fill",
                    isSelected: direction == .`break`
                ) {
                    direction = .`break`
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        HabitDirectionSection(direction: .constant(.build))
        HabitDirectionSection(direction: .constant(.`break`))
    }
    .padding()
    .background(AppColor.bgCanvas)
}
