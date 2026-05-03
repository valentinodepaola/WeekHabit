//
//  HabitsView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct HabitsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \Plan.createdAt, order: .reverse) private var plans: [Plan]

    @State private var isShowingCreateHabit: Bool = false
    @State private var isShowingCreatePlan: Bool = false
    @State private var habitToDelete: Habit?
    @State private var showDeleteHabitAlert: Bool = false
    @State private var planToDelete: Plan?
    @State private var showDeletePlanAlert: Bool = false
    @State private var editHabitRoute: EditHabitRoute?
    @State private var editPlanRoute: EditPlanRoute?
    @State private var selectedHabit: Habit?
    @State private var expandedPlans: Set<UUID> = []

    private var activePlans: [Plan] {
        plans.filter { $0.isActive() }
    }

    private var finishedPlans: [Plan] {
        plans.filter { $0.isFinished() }
    }

    private var orphanHabits: [Habit] {
        habits.filter { $0.plans.isEmpty && !$0.isFinished() }
    }

    private var finishedHabits: [Habit] {
        habits.filter { $0.isFinished() }
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                VStack(spacing: 0) {
                    HStack {
                        Text("Hábitos")
                            .font(AppFont.title)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Menu {
                            Button {
                                isShowingCreateHabit = true
                            } label: {
                                Label("Nuevo hábito", systemImage: "plus.circle")
                            }

                            Button {
                                isShowingCreatePlan = true
                            } label: {
                                Label("Nuevo plan", systemImage: "target")
                            }
                        } label: {
                            IconButton(icon: "plus", style: .circle) {}
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)

                    if habits.isEmpty && plans.isEmpty {
                        Spacer()
                        EmptyStateView {
                            isShowingCreateHabit = true
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(activePlans) { plan in
                                Section {
                                    planAccordionRow(plan)
                                }
                                .listSectionSpacing(0)
                            }

                            if !orphanHabits.isEmpty {
                                Section {
                                    ForEach(orphanHabits) { habit in
                                        habitRow(habit)
                                    }
                                } header: {
                                    if !activePlans.isEmpty {
                                        Text("Sin plan")
                                            .font(AppFont.formSectionText)
                                            .foregroundStyle(AppColor.mutedText)
                                    }
                                }
                            }

                            if !finishedHabits.isEmpty || !finishedPlans.isEmpty {
                                Section {
                                    ForEach(finishedHabits) { habit in
                                        habitRow(habit)
                                    }
                                    ForEach(finishedPlans) { plan in
                                        planAccordionRow(plan)
                                    }
                                } header: {
                                    Text("Terminados")
                                        .font(AppFont.formSectionText)
                                        .foregroundStyle(AppColor.mutedText)
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
                .navigationDestination(item: $selectedHabit) { habit in
                    HabitDetailView(habit: habit)
                }
                .fullScreenCover(isPresented: $isShowingCreateHabit) {
                    CreateHabitView()
                }
                .fullScreenCover(isPresented: $isShowingCreatePlan) {
                    PlanFlowView()
                }
                .fullScreenCover(item: $editHabitRoute) { route in
                    CreateHabitView(habitToEdit: route.habit)
                }
                .fullScreenCover(item: $editPlanRoute) { route in
                    CreatePlanView(planToEdit: route.plan)
                }
                .alert("¿Borrar hábito?", isPresented: $showDeleteHabitAlert) {
                    Button("Cancelar", role: .cancel) { habitToDelete = nil }
                    Button("Borrar", role: .destructive) { deleteSelectedHabit() }
                } message: {
                    Text("Esta acción eliminará el hábito y su progreso registrado. No se puede deshacer.")
                }
                .alert("¿Eliminar plan?", isPresented: $showDeletePlanAlert) {
                    Button("Cancelar", role: .cancel) { planToDelete = nil }
                    Button("Eliminar", role: .destructive) { deleteSelectedPlan() }
                } message: {
                    Text("Los hábitos del plan no serán eliminados.")
                }
            }
        }
    }

    private func planAccordionRow(_ plan: Plan) -> some View {
        PlanAccordion(
            plan: plan,
            isExpanded: expandedPlans.contains(plan.id),
            onToggle: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if expandedPlans.contains(plan.id) {
                        expandedPlans.remove(plan.id)
                    } else {
                        expandedPlans.insert(plan.id)
                    }
                }
            },
            onHabitTap: { habit in
                selectedHabit = habit
            },
            onEdit: {
                editPlanRoute = EditPlanRoute(plan: plan)
            },
            onDelete: {
                planToDelete = plan
                showDeletePlanAlert = true
            }
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                planToDelete = plan
                showDeletePlanAlert = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                editPlanRoute = EditPlanRoute(plan: plan)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func habitRow(_ habit: Habit) -> some View {
        HabitCard(
            habit: habit,
            includesHorizontalPadding: false
        ) {
            selectedHabit = habit
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                habitToDelete = habit
                showDeleteHabitAlert = true
            } label: {
                Label("Borrar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                editHabitRoute = EditHabitRoute(habit: habit)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }

    private func deleteSelectedHabit() {
        guard let habitToDelete else { return }
        modelContext.delete(habitToDelete)
        self.habitToDelete = nil
    }

    private func deleteSelectedPlan() {
        guard let planToDelete else { return }
        modelContext.delete(planToDelete)
        self.planToDelete = nil
    }
}

private struct EditHabitRoute: Identifiable {
    let habit: Habit
    var id: UUID { habit.id }
}

private struct EditPlanRoute: Identifiable {
    let plan: Plan
    var id: UUID { plan.id }
}

#Preview {
    HabitsView()
}
