//
//  HabitReplacementSection.swift
//  WeekHabit
//

import SwiftUI

enum HabitReplacementMode: String, CaseIterable, Identifiable {
    case skip
    case existing
    case create

    var id: String { rawValue }
}

struct HabitReplacementSection: View {
    let availableHabits: [Habit]
    @Binding var mode: HabitReplacementMode
    @Binding var selectedHabitID: UUID?
    @Binding var newHabitName: String
    @Binding var newHabitCue: String

    var body: some View {
        CreateHabitFormSection(
            title: "¿Qué vas a hacer en su lugar?",
            helper: "Elegí una acción breve para usar cuando aparezca el impulso."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                VStack(spacing: AppSpacing.s) {
                    HabitOptionButton(
                        title: "Crear reemplazo",
                        subtitle: "Definir una acción nueva ahora",
                        icon: "plus.circle.fill",
                        isSelected: mode == .create
                    ) {
                        mode = .create
                    }

                    HabitOptionButton(
                        title: "Vincular existente",
                        subtitle: availableHabits.isEmpty ? "No hay hábitos build disponibles" : "Usar un hábito que ya tenés",
                        icon: "link.circle.fill",
                        isSelected: mode == .existing
                    ) {
                        if !availableHabits.isEmpty {
                            mode = .existing
                            selectedHabitID = selectedHabitID ?? availableHabits.first?.id
                        }
                    }

                    HabitOptionButton(
                        title: "Saltar por ahora",
                        subtitle: "Podés agregarlo más tarde",
                        icon: "forward.circle.fill",
                        isSelected: mode == .skip
                    ) {
                        mode = .skip
                    }
                }

                if mode == .create {
                    newReplacementFields
                }

                if mode == .existing, !availableHabits.isEmpty {
                    existingHabitPicker
                }
            }
        }
    }

    private var newReplacementFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            TextFieldComponent(
                titleSection: "Reemplazo",
                placeholder: "Respiración 4-7-8",
                habitName: $newHabitName,
                normalTextField: true
            )

            TextFieldComponent(
                titleSection: "Señal opcional",
                placeholder: "Cuando sienta el impulso...",
                habitName: $newHabitCue,
                normalTextField: false
            )
        }
        .padding(.top, AppSpacing.xs)
    }

    private var existingHabitPicker: some View {
        VStack(spacing: AppSpacing.s) {
            ForEach(availableHabits) { habit in
                Button {
                    selectedHabitID = habit.id
                } label: {
                    HStack(spacing: AppSpacing.m) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(habit.habitColor)
                            .frame(width: 34, height: 34)
                            .background(habit.habitColor.opacity(0.14))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(1)

                            Text(habit.scheduleSummaryText)
                                .font(AppFont.label)
                                .foregroundStyle(AppColor.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: selectedHabitID == habit.id ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(selectedHabitID == habit.id ? AppColor.accent : AppColor.textTertiary)
                    }
                    .padding(.horizontal, AppSpacing.m)
                    .padding(.vertical, AppSpacing.s)
                    .background(selectedHabitID == habit.id ? AppColor.accentMuted.opacity(0.5) : AppColor.bgSunken)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                            .strokeBorder(
                                selectedHabitID == habit.id ? AppColor.accent.opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, AppSpacing.xs)
    }
}

#Preview {
    HabitReplacementSection(
        availableHabits: [],
        mode: .constant(.create),
        selectedHabitID: .constant(nil),
        newHabitName: .constant("Respiración 4-7-8"),
        newHabitCue: .constant("")
    )
    .padding()
    .background(AppColor.bgCanvas)
}
