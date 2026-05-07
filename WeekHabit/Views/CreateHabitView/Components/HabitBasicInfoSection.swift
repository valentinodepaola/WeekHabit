//
//  HabitBasicInfoSection.swift
//  WeekHabit
//

import SwiftUI

struct HabitBasicInfoSection: View {
    @Binding var habitName: String
    @Binding var note: String
    @Binding var cue: String
    @Binding var selectedIconName: String
    @Binding var selectedColorHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextFieldComponent(
                titleSection: "Nombre",
                placeholder: "Leer",
                habitName: $habitName,
                normalTextField: true
            )

            TextFieldComponent(
                titleSection: "Nota opcional",
                placeholder: "Antes de dormir, sin celular cerca...",
                habitName: $note,
                normalTextField: false
            )

            TextFieldComponent(
                titleSection: "Después de...",
                placeholder: "Ej: Después de servirme el café de la mañana",
                habitName: $cue,
                normalTextField: false
            )

            HabitAppearancePicker(
                selectedIconName: $selectedIconName,
                selectedColorHex: $selectedColorHex
            )
        }
    }
}
