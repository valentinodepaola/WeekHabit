//
//  FocusSequenceStepper.swift
//  WeekHabit
//
//  Stepper vertical del modo secuencia durante la sesión activa: una columna de
//  círculos conectados, uno por hábito en su orden. Cada nodo refleja el estado
//  planeado según el tiempo real transcurrido (pendiente, en curso, listo). Las
//  píldoras quedan fijas; solo se rellenan conforme avanza el tiempo.
//

import SwiftUI

struct FocusSequenceStepper: View {
    let items: [FocusSequenceItem]
    let habitsByID: [UUID: Habit]
    let elapsed: Int

    private var states: [FocusStepState] {
        FocusSequence.states(items: items, elapsed: elapsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Text("SECUENCIA")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .tracking(0.8)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(index: index, item: item, state: states[index])
                }
            }
            .padding(AppSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .appElevation(.low)
        }
    }

    @ViewBuilder
    private func row(index: Int, item: FocusSequenceItem, state: FocusStepState) -> some View {
        let habit = habitsByID[item.id]
        let isLast = index == items.count - 1

        HStack(alignment: .top, spacing: AppSpacing.m) {
            VStack(spacing: 0) {
                node(habit: habit, state: state)

                if !isLast {
                    Rectangle()
                        .fill(connectorColor(for: state))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(habit?.title ?? "Hábito")
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(isPending(state) ? AppColor.textSecondary : AppColor.textPrimary)
                    .lineLimit(1)

                Text(subtitle(item: item, state: state))
                    .font(AppFont.label)
                    .foregroundStyle(statusColor(state))
            }
            .padding(.bottom, isLast ? 0 : AppSpacing.l)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func node(habit: Habit?, state: FocusStepState) -> some View {
        switch state {
        case .done:
            ZStack {
                Circle().fill(AppColor.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

        case .inProgress(let fraction):
            WHProgressRing(
                progress: fraction,
                lineWidth: 3,
                size: 34,
                trackColor: AppColor.divider,
                progressColor: AppColor.accent
            ) {
                Image(systemName: habit?.iconName ?? "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }

        case .pending:
            ZStack {
                Circle().strokeBorder(AppColor.divider, lineWidth: 2)
                Image(systemName: habit?.iconName ?? "circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColor.textTertiary)
            }
            .frame(width: 34, height: 34)
        }
    }

    private func connectorColor(for state: FocusStepState) -> Color {
        if case .done = state { return AppColor.accent }
        return AppColor.divider
    }

    private func isPending(_ state: FocusStepState) -> Bool {
        if case .pending = state { return true }
        return false
    }

    private func statusColor(_ state: FocusStepState) -> Color {
        switch state {
        case .done: return AppColor.success
        case .inProgress: return AppColor.accent
        case .pending: return AppColor.textTertiary
        }
    }

    private func subtitle(item: FocusSequenceItem, state: FocusStepState) -> String {
        let minutes = item.seconds / 60
        switch state {
        case .done: return "Listo · \(minutes) min"
        case .inProgress: return "Ahora · \(minutes) min"
        case .pending: return "Pendiente · \(minutes) min"
        }
    }
}
