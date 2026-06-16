//
//  TodayPlansSection.swift
//  WeekHabit
//

import SwiftUI

struct TodayPlanActions {
    var onHabitTap: (Habit) -> Void
    var onOpenDetail: (Plan) -> Void
    var onEdit: (Plan) -> Void
    var onDelete: (Plan) -> Void
}

struct TodayPlansSection: View {
    let plans: [Plan]
    @Binding var expandedPlans: Set<UUID>
    let actions: TodayPlanActions

    var body: some View {
        Group {
            Text("Planes")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, AppSpacing.s)
                .todayListRow()

            ForEach(plans) { plan in
                planRow(plan)
            }
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        PlanAccordion(
            plan: plan,
            isExpanded: expandedPlans.contains(plan.id),
            onToggle: {
                withAnimation(AppMotion.smooth) {
                    if expandedPlans.contains(plan.id) {
                        expandedPlans.remove(plan.id)
                    } else {
                        expandedPlans.insert(plan.id)
                    }
                }
            },
            onHabitTap: actions.onHabitTap,
            onOpenDetail: { actions.onOpenDetail(plan) }
        )
        .todayListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                actions.onDelete(plan)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
            .tint(AppColor.destructiveAction)

            Button {
                actions.onEdit(plan)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(AppColor.editAction)
        }
    }
}
