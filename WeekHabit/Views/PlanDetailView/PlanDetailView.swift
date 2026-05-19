//
//  PlanDetailView.swift
//  WeekHabit
//

import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plan: Plan

    private var sortedMilestones: [PlanMilestone] {
        plan.milestones.sorted { $0.targetDate < $1.targetDate }
    }

    private var urgentMilestone: PlanMilestone? {
        let today = AppCalendar.startOfDay(for: .now)
        return sortedMilestones.first { m in
            guard m.completedAt == nil else { return false }
            let days = AppCalendar.current.dateComponents([.day], from: today, to: m.targetDate).day ?? 0
            return days <= 3
        }
    }

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    topBar
                    headerSection
                    progressSection

                    if let urgent = urgentMilestone {
                        urgentBanner(for: urgent)
                    }

                    if !sortedMilestones.isEmpty {
                        milestonesSection
                    }
                }
                .padding(.horizontal, AppSpacing.l)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Secciones

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColor.bgSunken))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, AppSpacing.m)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                Text("PLAN ACTIVO")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)
            }

            Text(plan.title)
                .font(AppFont.display)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let motivation = plan.motivation, !motivation.isEmpty {
                Text(motivation)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let outcome = plan.measurableOutcome, !outcome.isEmpty {
                HStack(spacing: AppSpacing.s) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColor.success)
                    Text(outcome)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, AppSpacing.m)
                .padding(.vertical, AppSpacing.s)
                .background(AppColor.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                        .stroke(AppColor.success.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(plan.progress() * 100))%")
                    .font(AppFont.headline)
                    .foregroundStyle(plan.meetsGoal() ? AppColor.success : AppColor.textPrimary)
                    .monospacedDigit()
                Text("de avance")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text(plan.daysRemainingText)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
            }

            WHProgressBar(
                progress: plan.progress(),
                progressColor: AppColor.accent,
                height: 8,
                goalMarker: plan.targetCompletionRate
            )
        }
    }

    private func urgentBanner(for milestone: PlanMilestone) -> some View {
        let today = AppCalendar.startOfDay(for: .now)
        let days = AppCalendar.current.dateComponents([.day], from: today, to: milestone.targetDate).day ?? 0
        let isToday = days == 0
        let isOverdue = days < 0

        let text: String
        if isOverdue {
            text = "Hito vencido: \(milestone.title)"
        } else if isToday {
            text = "Hito de hoy: \(milestone.title)"
        } else {
            text = "Hito en \(days) \(days == 1 ? "día" : "días"): \(milestone.title)"
        }

        return HStack(spacing: AppSpacing.m) {
            Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "flag.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.warning)
                .frame(width: 30, height: 30)
                .background(AppColor.warning.opacity(0.12))
                .clipShape(Circle())

            Text(text)
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.s)
        .background(AppColor.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .stroke(AppColor.warning.opacity(0.25), lineWidth: 1)
        )
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("HITOS")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.6)

            VStack(spacing: AppSpacing.s) {
                ForEach(sortedMilestones) { milestone in
                    PlanMilestoneRow(milestone: milestone) {
                        toggleMilestone(milestone)
                    }
                }
            }
        }
    }

    // MARK: - Acción

    private func toggleMilestone(_ milestone: PlanMilestone) {
        if milestone.completedAt != nil {
            milestone.completedAt = nil
        } else {
            milestone.completedAt = .now
        }
        AppHaptics.play(.experimentApplied)
    }
}

#Preview {
    let plan = Plan(title: "Correr 5K", motivation: "Quiero sentirme con energía", endsAt: .now.addingTimeInterval(30 * 86400))
    plan.measurableOutcome = "Terminar en menos de 30 minutos"
    return PlanDetailView(plan: plan)
}
