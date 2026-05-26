//
//  UrgeLogSheet.swift
//  WeekHabit
//

import SwiftUI

struct UrgeLogSheet: View {
    let habit: Habit
    let onSave: (SlipTrigger?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrigger: SlipTrigger?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            dragIndicator
            header
            triggerGrid
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
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(habit.habitColor)
                    .frame(width: 34, height: 34)
                    .background(habit.habitColor.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Registrar impulso")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(habit.title)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                }
            }

            Text("Notarlo sin seguirlo también cuenta. Guardá qué lo detonó para encontrar patrones.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var triggerGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Detonante opcional")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.4)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 122), spacing: AppSpacing.s)],
                alignment: .leading,
                spacing: AppSpacing.s
            ) {
                ForEach(SlipTrigger.allCases) { trigger in
                    WHChip(
                        label: trigger.title,
                        icon: trigger.iconName,
                        isSelected: selectedTrigger == trigger
                    ) {
                        selectedTrigger = selectedTrigger == trigger ? nil : trigger
                    }
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.s) {
            WHButton(
                title: "Guardar impulso",
                icon: "checkmark",
                variant: .primary
            ) {
                onSave(selectedTrigger)
                AppHaptics.play(.urgeLogged)
                dismiss()
            }

            Button("Cancelar") {
                dismiss()
            }
            .font(AppFont.bodyEmphasis)
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

#Preview {
    UrgeLogSheet(
        habit: Habit(
            title: "No fumar",
            iconName: "lungs.fill",
            colorHex: "#7fa869",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            direction: .break
        )
    ) { _ in }
}
