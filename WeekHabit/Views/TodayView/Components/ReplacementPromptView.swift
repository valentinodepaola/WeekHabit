//
//  ReplacementPromptView.swift
//  WeekHabit
//

import SwiftUI

struct ReplacementPromptView: View {
    let breakHabit: Habit
    let replacementHabit: Habit
    let onStart: () -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            dragIndicator
            header
            replacementCard
            actions
        }
        .padding(AppSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.bgCanvas)
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(AppColor.textTertiary.opacity(0.25))
            .frame(width: 42, height: 4)
            .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Tengo el impulso")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text("¿Querés hacer \(replacementHabit.title) ahora?")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var replacementCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: replacementHabit.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(replacementHabit.habitColor)
                .frame(width: 38, height: 38)
                .background(replacementHabit.habitColor.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(replacementHabit.title)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)

                if let cue = replacementCue {
                    Text(cue)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Reemplazo para \(breakHabit.title)")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                .strokeBorder(AppColor.divider, lineWidth: 1)
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.s) {
            WHButton(
                title: "Iniciar ahora",
                icon: "play.fill",
                variant: .primary
            ) {
                dismiss()
                onStart()
            }

            Button("Ahora no") {
                dismiss()
                onSkip()
            }
            .font(AppFont.bodyEmphasis)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private var replacementCue: String? {
        guard let cue = replacementHabit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }
        return cue
    }
}

#Preview {
    ReplacementPromptView(
        breakHabit: Habit(
            title: "No fumar",
            iconName: "lungs.fill",
            colorHex: "#7fa869",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            direction: .break
        ),
        replacementHabit: Habit(
            title: "Respiración 4-7-8",
            cue: "Cuando aparezca el impulso",
            iconName: "figure.mind.and.body",
            colorHex: "#5c89a8",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered)
        ),
        onStart: {},
        onSkip: {}
    )
}
