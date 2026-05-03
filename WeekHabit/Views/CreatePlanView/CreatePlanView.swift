//
//  CreatePlanView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct CreatePlanView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Habit.createdAt, order: .reverse) private var allHabits: [Habit]

    @State private var planName: String = ""
    @State private var motivation: String = ""
    @State private var selectedCategory: HabitCategory = .health
    @State private var endsAt: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var targetCompletionRate: Double = 0.8
    @State private var selectedHabits: Set<UUID> = []

    private let planToEdit: Plan?

    private var isSaveDisabled: Bool {
        planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isEditing: Bool {
        planToEdit != nil
    }

    init(planToEdit: Plan? = nil) {
        self.planToEdit = planToEdit

        _planName = State(initialValue: planToEdit?.title ?? "")
        _motivation = State(initialValue: planToEdit?.motivation ?? "")
        _selectedCategory = State(initialValue: planToEdit?.displayCategory ?? .health)
        _endsAt = State(initialValue: planToEdit?.endsAt ?? Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now)
        _targetCompletionRate = State(initialValue: planToEdit?.targetCompletionRate ?? 0.8)
        _selectedHabits = State(initialValue: Set(planToEdit?.habits.map(\.id) ?? []))
    }

    var body: some View {
        AppBackground {
            ScrollView {
                CreatePlanTopBar(
                    isSaveDisabled: isSaveDisabled,
                    onCancel: { dismiss() },
                    onSave: { savePlan() }
                )

                VStack(alignment: .leading, spacing: 25) {
                    Text(isEditing ? "Editar plan" : "Nuevo plan")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)
                        .padding(.bottom, 8)

                    PlanBasicInfoSection(
                        planName: $planName,
                        motivation: $motivation,
                        selectedCategory: $selectedCategory
                    )

                    PlanScheduleSection(endsAt: $endsAt)

                    PlanGoalSection(targetCompletionRate: $targetCompletionRate)

                    PlanHabitsSection(selectedHabits: $selectedHabits)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }

    private func savePlan() {
        guard !isSaveDisabled else { return }

        let trimmedName = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMotivation = motivation.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEndsAt = AppCalendar.startOfDay(for: endsAt)
        let linkedHabits = allHabits.filter { selectedHabits.contains($0.id) }

        if let planToEdit {
            planToEdit.title = trimmedName
            planToEdit.motivation = trimmedMotivation.isEmpty ? nil : trimmedMotivation
            planToEdit.category = selectedCategory
            planToEdit.endsAt = normalizedEndsAt
            planToEdit.targetCompletionRate = targetCompletionRate
            planToEdit.habits = linkedHabits
        } else {
            let plan = Plan(
                title: trimmedName,
                motivation: trimmedMotivation.isEmpty ? nil : trimmedMotivation,
                category: selectedCategory,
                endsAt: normalizedEndsAt,
                targetCompletionRate: targetCompletionRate
            )
            modelContext.insert(plan)
            plan.habits = linkedHabits
        }

        dismiss()
    }
}

#Preview {
    CreatePlanView()
}
