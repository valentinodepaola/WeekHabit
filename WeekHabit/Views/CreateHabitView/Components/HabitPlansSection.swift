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
        CreateHabitFormSection(
            title: "Plan",
            helper: "Conecta este hábito con una meta que importa."
        ) {
            if activePlans.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppSpacing.s) {
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

    private var emptyState: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "target")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColor.textTertiary)
                .frame(width: 32, height: 32)
                .background(AppColor.bgSunken)
                .clipShape(Circle())

            Text("Sin planes activos. Puedes vincularlo más tarde desde el plan.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgSunken.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }
}

private struct PlanSelectionRow: View {
    let plan: Plan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.m) {
                ZStack {
                    Circle()
                        .fill(AppColor.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColor.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    Text(plan.daysRemainingText)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.accent : AppColor.textTertiary)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(isSelected ? AppColor.accentMuted.opacity(0.5) : AppColor.bgSunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(isSelected ? AppColor.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
