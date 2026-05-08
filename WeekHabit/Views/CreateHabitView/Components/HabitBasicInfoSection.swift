//
//  HabitBasicInfoSection.swift
//  WeekHabit
//
//  Sección "Acción": qué se hace, cómo se identifica.
//  El cue ("Después de…") se elevó a sección propia (HabitCueSection).
//

import SwiftUI

struct HabitBasicInfoSection: View {
    @Binding var habitName: String
    @Binding var note: String
    @Binding var selectedIconName: String
    @Binding var selectedColorHex: String

    var body: some View {
        CreateHabitFormSection(
            title: "Acción",
            helper: "Específica y suficientemente pequeña para repetirse."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                TextFieldComponent(
                    titleSection: "Nombre",
                    placeholder: "Leer 10 minutos",
                    habitName: $habitName,
                    normalTextField: true
                )

                TextFieldComponent(
                    titleSection: "Nota opcional",
                    placeholder: "Antes de dormir, sin celular cerca…",
                    habitName: $note,
                    normalTextField: false
                )

                HabitAppearancePicker(
                    selectedIconName: $selectedIconName,
                    selectedColorHex: $selectedColorHex
                )
            }
        }
    }
}
