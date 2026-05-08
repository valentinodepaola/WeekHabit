//
//  CreateHabitFormSection.swift
//  WeekHabit
//
//  Wrapper que reusa `WHFormSection` para que todas las secciones del formulario
//  hereden el mismo lenguaje visual del sistema.
//

import SwiftUI

struct CreateHabitFormSection<Content: View>: View {
    let title: String
    var helper: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        WHFormSection(title: title, helper: helper) {
            content()
        }
    }
}
