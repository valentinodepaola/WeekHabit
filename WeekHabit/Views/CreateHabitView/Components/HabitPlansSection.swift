//
//  HabitPlansSection.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct HabitPlansSection: View {
    @Query(sort: \Plan.createdAt, order: .reverse) private var allPlans: [Plan]
    @Binding var selectedPlans: Set<UUID>

    private var activePlans: [Plan] {
        allPlans.filter { $0.isActive() }
    }

    var body: some View {
        CreateHabitFormSection(title: "Planes") {
            if activePlans.isEmpty {
                Text("No tienes planes activos. Puedes crear uno desde la pantalla de Hábitos.")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.subtleText)
                    .multilineTextAlignment(.leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(activePlans) { plan in
                        PlanSelectionRow(
                            plan: plan,
                            isSelected: selectedPlans.contains(plan.id)
                        ) {
                            if selectedPlans.contains(plan.id) {
                                selectedPlans.remove(plan.id)
                            } else {
                                selectedPlans.insert(plan.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PlanSelectionRow: View {
    let plan: Plan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(plan.displayCategory.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: plan.displayCategory.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(plan.displayCategory.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(AppFont.body2)
                        .foregroundStyle(AppColor.strongText)
                        .lineLimit(1)

                    Text(plan.daysRemainingText)
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.accent : AppColor.subtleText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
