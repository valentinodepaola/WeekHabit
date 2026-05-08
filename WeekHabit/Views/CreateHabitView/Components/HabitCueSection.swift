//
//  HabitCueSection.swift
//  WeekHabit
//
//  Sección "Señal" — el corazón del modelo conductual.
//  "Un hábito sin señal depende de memoria y motivación, que son recursos
//  inestables." — IDENTIDAD_MISION.md
//

import SwiftUI

struct HabitCueSection: View {
    @Binding var cue: String

    var body: some View {
        CreateHabitFormSection(
            title: "Señal",
            helper: "Una rutina existente vale más que la fuerza de voluntad."
        ) {
            TextFieldComponent(
                titleSection: "Después de…",
                placeholder: "Ej: Después de servirme el café de la mañana",
                habitName: $cue,
                normalTextField: false
            )
        }
    }
}
