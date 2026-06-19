//
//  CreateHabitStepHeader.swift
//  WeekHabit
//
//  Cabecera del wizard: chips de paso navegables + título serif del paso.
//  Los chips muestran dónde estás, qué completaste y a dónde puedes saltar.
//

import SwiftUI

struct CreateHabitStepHeader: View {
    let step: CreateHabitStep
    let unlockedSteps: Set<CreateHabitStep>
    let onSelect: (CreateHabitStep) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(spacing: AppSpacing.s) {
                ForEach(CreateHabitStep.allCases) { candidate in
                    chip(for: candidate)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(step.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Text(step.subtitle)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(for candidate: CreateHabitStep) -> some View {
        let isCurrent = candidate == step
        let isCompleted = candidate.rawValue < step.rawValue
        let isUnlocked = unlockedSteps.contains(candidate)

        return Button {
            onSelect(candidate)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                } else {
                    Text("\(candidate.rawValue + 1)")
                }
                Text(candidate.shortName)
            }
            .font(AppFont.micro)
            .foregroundStyle(chipForeground(isCurrent: isCurrent, isCompleted: isCompleted, isUnlocked: isUnlocked))
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(chipBackground(isCurrent: isCurrent, isCompleted: isCompleted))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked || isCurrent)
        .accessibilityLabel("Paso \(candidate.rawValue + 1) de \(CreateHabitStep.allCases.count): \(candidate.shortName)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func chipForeground(isCurrent: Bool, isCompleted: Bool, isUnlocked: Bool) -> Color {
        if isCurrent { return .white }
        if isCompleted { return AppColor.accent }
        return isUnlocked ? AppColor.textSecondary : AppColor.textTertiary
    }

    private func chipBackground(isCurrent: Bool, isCompleted: Bool) -> Color {
        if isCurrent { return AppColor.accent }
        if isCompleted { return AppColor.accentMuted.opacity(0.6) }
        return AppColor.bgSunken
    }
}

#Preview {
    VStack(spacing: AppSpacing.xl) {
        CreateHabitStepHeader(step: .action, unlockedSteps: [.action]) { _ in }
        CreateHabitStepHeader(step: .rhythm, unlockedSteps: [.action, .rhythm]) { _ in }
        CreateHabitStepHeader(step: .support, unlockedSteps: Set(CreateHabitStep.allCases)) { _ in }
    }
    .padding()
    .background(AppColor.bgCanvas)
}
