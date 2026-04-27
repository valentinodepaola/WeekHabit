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
                    List {
                        ForEach(habits) { habit in
                            HabitCard(
                                habit: habit,
                                includesHorizontalPadding: false
                            ) { }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        habitToDelete = habit
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Borrar", systemImage: "trash")
                                    }
                                    .tint(AppColor.destructiveAction)

                                    Button {
                                        editRoute = EditHabitRoute(habit: habit)
                                    } label: {
                                        Label("Editar", systemImage: "pencil")
                                    }
                                    .tint(AppColor.editAction)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .listRowSpacing(12)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 18, for: .scrollContent)
                    .contentMargins(.bottom, 120, for: .scrollContent)
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
