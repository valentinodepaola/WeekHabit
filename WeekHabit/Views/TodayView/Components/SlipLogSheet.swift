//
//  SlipLogSheet.swift
//  WeekHabit
//

import SwiftUI

struct SlipLogSheet: View {
    let habit: Habit
    var existingEntry: HabitEntry?
    let onSave: (SlipTrigger?, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrigger: SlipTrigger?
    @State private var contextText: String

    init(
        habit: Habit,
        existingEntry: HabitEntry? = nil,
        onSave: @escaping (SlipTrigger?, String?) -> Void
    ) {
        self.habit = habit
        self.existingEntry = existingEntry
        self.onSave = onSave
        _selectedTrigger = State(initialValue: existingEntry?.slipTrigger)
        _contextText = State(initialValue: existingEntry?.slipContext ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            dragIndicator
            header
            triggerGrid
            contextInput
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
                Image(systemName: habit.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(habit.habitColor)
                    .frame(width: 34, height: 34)
                    .background(habit.habitColor.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(existingEntry == nil ? "Registrar slip" : "Editar slip")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(habit.title)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                }
            }

            Text("Un slip es información, no fracaso. Registrarlo ayuda a entender el patrón y volver con menos carga.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var triggerGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("¿Qué lo detonó?")
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

    private var contextInput: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("Contexto opcional")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.4)

            ZStack(alignment: .topLeading) {
                if contextText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("¿Qué estaba pasando justo antes?")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textTertiary)
                        .padding(.horizontal, AppSpacing.m + 1)
                        .padding(.vertical, AppSpacing.m + 8)
                }

                TextEditor(text: $contextText)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, AppSpacing.s)
                    .padding(.vertical, AppSpacing.s)
                    .frame(minHeight: 112)
            }
            .background(AppColor.bgSunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 1)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.s) {
            WHButton(
                title: existingEntry == nil ? "Guardar slip" : "Guardar cambios",
                icon: "checkmark",
                variant: .primary
            ) {
                let trimmed = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(selectedTrigger, trimmed.isEmpty ? nil : trimmed)
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
    SlipLogSheet(
        habit: Habit(
            title: "No fumar",
            iconName: "lungs.fill",
            colorHex: "#7fa869",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            direction: .break
        )
    ) { _, _ in }
}
