//
//  CreateHabitView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
//

import SwiftUI
import SwiftData
import Foundation

struct CreateHabitView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var habitName: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: HabitCategory = .health
    @State private var daysPerWeek: Int = 0
    @State private var selectedActiveDays: Set<Weekday> = []
    
    private var isSaveDisabled: Bool {
        habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        daysPerWeek == 0 ||
        selectedActiveDays.count != daysPerWeek
    }
    
    var body: some View {
        AppBackground {
            ScrollView {
                HStack {
                    Button("Cancelar") {
                        self.dismiss()
                    }
                    .foregroundStyle(AppColor.mutedText)

                    Spacer()

                    Button {
                        saveHabit()
                    } label: {
                        Text("Guardar")
                    }
                    .buttonStyle(.borderedProminent)
                    .fontWeight(.bold)
                    .tint(AppColor.accent)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 25) {

                    Text("Nuevo habito")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)
                        .padding(.bottom, 20)
                    
                    TextFieldComponent(
                        titleSection: "Nombre",
                        placeholder: "Tomar agua",
                        habitName: $habitName,
                        normalTextField: true
                    )
                    
                    TextFieldComponent(
                        titleSection: "Nota opcional",
                        placeholder: "Un vaso cada 2 horas...",
                        habitName: $note,
                        normalTextField: false
                    )
                    
                    Text("Categoria")
                        .font(AppFont.formSectionText)
                        .foregroundStyle(AppColor.mutedText)
                        .textCase(.uppercase)

                    //TODO: Agregar animacion al cambiar de boton.
                    ButtonCategoryComponent(selectedCategory: $selectedCategory)

                    Text("Meta semanal")
                        .font(AppFont.formSectionText)
                        .foregroundStyle(AppColor.mutedText)
                        .textCase(.uppercase)
                    
                    WeekGoalComponent(days: self.$daysPerWeek)
                    
                    ActiveDaysComponent(
                        selectedDays: $selectedActiveDays,
                        targetDays: daysPerWeek
                    )
                    
                    HStack {
                        Image(systemName: "circle.hexagongrid")
                            .foregroundStyle(AppColor.accent)

                        Text("Lunes a viernes es un buen ritmo para empezar.")
                            .font(AppFont.formSectionText)
                            .foregroundStyle(AppColor.accent)
                    }
                    .padding(8)
                    .background(AppColor.accent.opacity(0.2))
                    .cornerRadius(AppRadius.medium)
                    
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .onChange(of: daysPerWeek) { _, newValue in
                    trimSelectedDays(to: newValue)
                }
                
                Spacer()
                
            }
        }
    }
    
    private func trimSelectedDays(to targetDays: Int) {
        guard selectedActiveDays.count > targetDays else { return }
        
        selectedActiveDays = Set(
            Weekday.ordered
                .filter { selectedActiveDays.contains($0) }
                .prefix(targetDays)
        )
    }
    
    private func saveHabit() {
        guard !isSaveDisabled else { return }
        
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let habit = Habit(
            title: trimmedName,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            category: selectedCategory,
            targetDaysPerWeek: daysPerWeek,
            activeDaysOfWeek: selectedActiveDays
        )
        
        modelContext.insert(habit)
        dismiss()
    }
}


#Preview {
    CreateHabitView()
}
