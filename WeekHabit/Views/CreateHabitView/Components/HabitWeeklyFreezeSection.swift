//
//  HabitWeeklyFreezeSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitWeeklyFreezeSection: View {
    @Binding var allowsWeeklyFreeze: Bool

    var body: some View {
        CreateHabitFormSection(
            title: "Comodín semanal",
            helper: "Protege la racha una vez por semana cuando hay un olvido real."
        ) {
            Toggle("Permitir comodín semanal", isOn: $allowsWeeklyFreeze)
                .font(AppFont.body)
                .tint(AppColor.accent)
        }
    }
}
