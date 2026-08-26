//
//  RecoveryPromptView.swift
//  WeekHabit
//

import SwiftUI

/// Formulario de razones de un hábito. Es la pantalla de detalle de `RecoveryPromptSheet`:
/// cuando hay varios pendientes se llega empujándola desde la lista, y con uno solo es la raíz.
struct RecoveryPromptView: View {
    let candidate: RecoveryPromptCandidate
    var referenceDate: Date = .now
    let onSave: (HabitFailureReason) -> Void

    @State private var selectedReason: HabitFailureReason?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                header

                VStack(spacing: AppSpacing.s) {
                    ForEach(HabitFailureReason.allCases) { reason in
                        reasonRow(reason)
                    }
                }

                actions
            }
            .padding(AppSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.bgCanvas)
        .onAppear {
            if selectedReason == nil {
                selectedReason = candidate.habit.recoveryAnswer(on: candidate.date)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: candidate.habit.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(candidate.habit.habitColor)
                    .frame(width: 34, height: 34)
                    .background(candidate.habit.habitColor.opacity(0.14))
                    .clipShape(Circle())

                Text(titleText)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Un toque basta. Lo usamos para ajustar mejor tus insights.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reasonRow(_ reason: HabitFailureReason) -> some View {
        Button {
            selectedReason = reason
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selectedReason == reason ? candidate.habit.habitColor : AppColor.textTertiary)
                    .frame(width: 24, height: 24)

                Text(reason.title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            .background(rowBackground(for: reason))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(rowBorder(for: reason), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.title)
        .accessibilityValue(selectedReason == reason ? "Seleccionado" : "No seleccionado")
    }

    private var actions: some View {
        WHButton(
            title: "Guardar",
            icon: "checkmark",
            variant: .primary,
            isDisabled: selectedReason == nil,
            action: {
                guard let selectedReason else { return }
                onSave(selectedReason)
            }
        )
    }

    private var titleText: String {
        if let yesterday = AppCalendar.current.date(
            byAdding: .day,
            value: -1,
            to: AppCalendar.startOfDay(for: referenceDate)
        ), AppCalendar.isSameDay(candidate.date, yesterday) {
            return "Ayer no marcaste \(candidate.habit.title). ¿Qué pasó?"
        }

        return "No marcaste \(candidate.habit.title) el \(weekdayName). ¿Qué pasó?"
    }

    private var weekdayName: String {
        AppCalendar.weekday(of: candidate.date)
            .displayName
            .lowercased(with: AppFormatters.esMXLocale)
    }

    private func rowBackground(for reason: HabitFailureReason) -> Color {
        selectedReason == reason
            ? candidate.habit.habitColor.opacity(0.10)
            : AppColor.bgElevated
    }

    private func rowBorder(for reason: HabitFailureReason) -> Color {
        selectedReason == reason
            ? candidate.habit.habitColor.opacity(0.42)
            : AppColor.divider
    }
}

#Preview {
    let habit = Habit(title: "Leer", targetDaysPerWeek: 7, activeDaysOfWeek: Set(Weekday.ordered))
    return RecoveryPromptView(
        candidate: RecoveryPromptCandidate(habit: habit, date: .now),
        onSave: { _ in }
    )
}
