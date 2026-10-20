//
//  PlanMilestoneRow.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct PlanMilestoneRow: View {
    let milestone: PlanMilestone
    let onToggleCompletion: () -> Void

    private var isCompleted: Bool { milestone.completedAt != nil }
    private var today: Date { AppCalendar.startOfDay(for: .now) }

    private var isOverdue: Bool {
        !isCompleted && milestone.targetDate < today
    }

    private var isUrgent: Bool {
        guard !isCompleted else { return false }
        let daysAway = AppCalendar.current.dateComponents([.day], from: today, to: milestone.targetDate).day ?? 0
        return daysAway >= 0 && daysAway <= 3
    }

    private var dateColor: Color {
        if isCompleted { return AppColor.success }
        if isOverdue { return AppColor.warning }
        if isUrgent { return AppColor.accent }
        return AppColor.textSecondary
    }

    private var dateText: String {
        let base = AppFormatters.string(from: milestone.targetDate, format: "d MMM")
        if isCompleted { return "Completado · \(base)" }
        if isOverdue { return "Vencido · \(base)" }
        return base
    }

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Button(action: onToggleCompletion) {
                ZStack {
                    Circle()
                        .strokeBorder(isCompleted ? AppColor.success : AppColor.divider, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    if isCompleted {
                        Circle()
                            .fill(AppColor.success)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(isCompleted ? AppColor.textTertiary : AppColor.textPrimary)
                    .strikethrough(isCompleted, color: AppColor.textTertiary)
                    .lineLimit(2)

                Text(dateText)
                    .font(AppFont.label)
                    .foregroundStyle(dateColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isOverdue && !isCompleted {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.warning)
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.vertical, AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(isOverdue && !isCompleted ? AppColor.warning.opacity(0.3) : AppColor.divider, lineWidth: 1)
        )
    }
}

#Preview("Del plan de muestra", traits: .sampleData) {
    @Previewable @Query var milestones: [PlanMilestone]

    VStack(spacing: AppSpacing.s) {
        ForEach(milestones.sorted { $0.targetDate < $1.targetDate }) { milestone in
            PlanMilestoneRow(milestone: milestone, onToggleCompletion: {})
        }
    }
    .padding()
    .background(AppColor.bgCanvas)
}

#Preview("Vencido y próximo", traits: .emptyData) {
    // Hitos sueltos, fuera del set compartido: el plan de muestra no tiene uno vencido.
    @Previewable @State var plan = Plan(title: "Mañanas con energía", endsAt: PreviewSamples.day(45))

    VStack(spacing: AppSpacing.s) {
        PlanMilestoneRow(
            milestone: PlanMilestone(title: "Primera semana completa", targetDate: PreviewSamples.day(-3), plan: plan),
            onToggleCompletion: {}
        )
        PlanMilestoneRow(
            milestone: PlanMilestone(title: "Correr 5 km seguidos", targetDate: PreviewSamples.day(2), plan: plan),
            onToggleCompletion: {}
        )
    }
    .padding()
    .background(AppColor.bgCanvas)
}
