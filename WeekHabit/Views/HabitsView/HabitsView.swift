//
//  HabitsView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct HabitsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]

    @State private var isShowingCreateHabit: Bool = false
    @State private var habitToDelete: Habit?
    @State private var showDeleteAlert: Bool = false
    @State private var editRoute: EditHabitRoute?

    var emptyState: Bool = true
    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                HStack {
                    Text("Hábitos")
                        .font(AppFont.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    IconButton(icon: "plus", style: .circle) {
                        isShowingCreateHabit = true
                    }

                }
                .padding(.horizontal)
                .padding(.top, 15)

                if habits.isEmpty {
                    Spacer()

                    EmptyStateView {
                        isShowingCreateHabit = true
                    }

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(habits) { habit in
                                SwipableRow(
                                    onEdit: {
                                        self.editRoute = EditHabitRoute(habit: habit)
                                    },
                                    onDelete: {
                                        self.habitToDelete = habit
                                        self.showDeleteAlert = true
                                    }
                                ) {
                                    HabitCard(
                                        habit: habit,
                                        includesHorizontalPadding: false
                                    ) { }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingCreateHabit) {
                CreateHabitView()
            }
            .fullScreenCover(item: $editRoute) { route in
                CreateHabitView(habitToEdit: route.habit)
            }
            .alert("¿Borrar hábito?", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) {
                    habitToDelete = nil
                }

                Button("Borrar", role: .destructive) {
                    deleteSelectedHabit()
                }
            } message: {
                Text("Esta acción eliminará el hábito y su progreso registrado. No se puede deshacer.")
            }
        }
    }

    private func deleteSelectedHabit() {
        guard let habitToDelete else { return }

        modelContext.delete(habitToDelete)
        self.habitToDelete = nil
    }
}

private struct EditHabitRoute: Identifiable {
    let habit: Habit

    var id: UUID {
        habit.id
    }
}

#Preview {
    HabitsView()
}
