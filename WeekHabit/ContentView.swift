//
//  ContentView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query var habits: [Habit]
    var body: some View {
        VStack {
            Text("Habits: \(habits.count)")
            Button("Agregar prueba") {
                let habit = Habit(
                    title: "Ejercicio",
                    category: "Salud",
                    targetDaysPerWeek: 5,
                    activeDaysOfWeek: [.monday, .wednesday, .friday]
                )
                context.insert(habit)
            }
        }
    }
}

#Preview {
    ContentView()
}
