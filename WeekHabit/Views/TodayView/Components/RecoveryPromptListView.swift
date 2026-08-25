//
//  RecoveryPromptListView.swift
//  WeekHabit
//

import SwiftUI

/// Lista de todos los hábitos que ayer quedaron sin marcar.
///
/// El roster que recibe está congelado por `RecoveryPromptSheet`: contestar una fila escribe una
/// entrada `.missed` y el hábito deja de ser candidato, así que si la lista se derivara en vivo la
/// fila desaparecería en vez de confirmarse. Lo que sí sale en vivo del `@Model` es el estado de
/// cada fila, vía `recoveryAnswer(on:)`.
struct RecoveryPromptListView: View {
    let candidates: [RecoveryPromptCandidate]
    let onSelect: (RecoveryPromptCandidate) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                header

                VStack(spacing: AppSpacing.s) {
                    ForEach(candidates) { candidate in
                        row(candidate)
                    }
                }
            }
            .padding(AppSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColor.bgCanvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text(titleText)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Un toque basta. Lo usamos para ajustar mejor tus insights.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func row(_ candidate: RecoveryPromptCandidate) -> some View {
        let answer = candidate.habit.recoveryAnswer(on: candidate.date)

        return Button {
            onSelect(candidate)
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: candidate.habit.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(candidate.habit.habitColor)
                    .frame(width: 32, height: 32)
                    .background(candidate.habit.habitColor.opacity(0.14))
                    .clipShape(Circle())

                Text(candidate.habit.title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: AppSpacing.s)

                if let answer {
                    Text(answer.title)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(candidate.habit.habitColor)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(candidate.habit.title)
        .accessibilityValue(answer?.title ?? "Sin responder")
    }

    private var titleText: String {
        candidates.count == 1
            ? "Ayer quedó 1 sin marcar"
            : "Ayer quedaron \(candidates.count) sin marcar"
    }
}

#Preview {
    let habit = Habit(title: "Leer", targetDaysPerWeek: 7, activeDaysOfWeek: Set(Weekday.ordered))
    let other = Habit(title: "Correr", targetDaysPerWeek: 7, activeDaysOfWeek: Set(Weekday.ordered))
    return RecoveryPromptListView(
        candidates: [
            RecoveryPromptCandidate(habit: habit, date: .now),
            RecoveryPromptCandidate(habit: other, date: .now)
        ],
        onSelect: { _ in }
    )
}
