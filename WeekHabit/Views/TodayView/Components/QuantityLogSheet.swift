//
//  QuantityLogSheet.swift
//  WeekHabit
//

import SwiftUI

struct QuantityLogSheet: View {
    let habit: Habit
    let date: Date
    let initialValue: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Double

    init(habit: Habit, date: Date, initialValue: Double, onSave: @escaping (Double) -> Void) {
        self.habit = habit
        self.date = date
        self.initialValue = initialValue
        self.onSave = onSave
        _value = State(initialValue: initialValue > 0 ? initialValue : habit.sessionTargetValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(AppColor.subtleText.opacity(0.25))
                .frame(width: 42, height: 4)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(AppFont.subtitle)
                    .foregroundStyle(AppColor.strongText)

                Text("Meta: \(habit.targetPerSessionText)")
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
            }

            HStack {
                stepButton(icon: "minus") {
                    value = max(0, value - step)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(Habit.formattedQuantity(value))
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.strongText)

                    Text(habit.unitDisplayText)
                        .font(AppFont.body2)
                        .foregroundStyle(AppColor.mutedText)
                }

                Spacer()

                stepButton(icon: "plus") {
                    value += step
                }
            }
            .padding()
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

            HStack(spacing: 10) {
                Button("Borrar") {
                    onSave(0)
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(AppColor.destructiveAction)

                Button {
                    onSave(value)
                    dismiss()
                } label: {
                    Text("Guardar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.accent)
            }
        }
        .padding()
    }

    private var step: Double {
        habit.measurementUnit == .kilometers ? 0.5 : 1
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColor.accent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
