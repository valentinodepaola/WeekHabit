//
//  PlanMilestonesSection.swift
//  WeekHabit
//

import SwiftUI

struct PlanMilestonesSection: View {
    @Binding var milestones: [MilestoneDraft]
    let planEndsAt: Date

    private var canAddMore: Bool { milestones.count < 5 }

    private var nextDefaultDate: Date {
        let today = AppCalendar.startOfDay(for: .now)
        let end = AppCalendar.startOfDay(for: planEndsAt)
        let interval = end.timeIntervalSince(today)
        if interval <= 0 { return end }
        let midpoint = today.addingTimeInterval(interval / 2)
        return AppCalendar.startOfDay(for: midpoint)
    }

    var body: some View {
        WHFormSection(
            title: "Hitos",
            helper: "Momentos de revisión opcionales durante el plan."
        ) {
            VStack(spacing: AppSpacing.s) {
                ForEach($milestones) { $draft in
                    MilestoneDraftRow(
                        draft: $draft,
                        planEndsAt: planEndsAt
                    ) {
                        milestones.removeAll { $0.id == draft.id }
                    }
                }

                if canAddMore {
                    addButton
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: {
            milestones.append(MilestoneDraft(targetDate: nextDefaultDate))
        }) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColor.accent)
                Text("Agregar hito")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.m)
            .background(AppColor.accentMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MilestoneDraftRow: View {
    @Binding var draft: MilestoneDraft
    let planEndsAt: Date
    let onDelete: () -> Void

    private var dateRange: ClosedRange<Date> {
        let today = AppCalendar.startOfDay(for: .now)
        let end = max(today, AppCalendar.startOfDay(for: planEndsAt))
        return today...end
    }

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: "flag.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.accent)
                .frame(width: 28, height: 28)
                .background(AppColor.accentMuted)
                .clipShape(Circle())

            TextField(
                "Nombre del hito",
                text: $draft.title
            )
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .tint(AppColor.accent)
            .frame(maxWidth: .infinity, alignment: .leading)

            DatePicker(
                "",
                selection: $draft.targetDate,
                in: dateRange,
                displayedComponents: .date
            )
            .labelsHidden()
            .tint(AppColor.accent)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppColor.bgSunken))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.bgSunken)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }
}
