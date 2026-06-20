//
//  WeekGridRow.swift
//  WeekHabit
//
//  Fila de la matriz semanal. Las celdas usan los insets de `WeekGridLayout`
//  para quedar alineadas con las columnas del strip de días; las celdas SON
//  el progreso de la semana (sin barra duplicada).
//

import SwiftUI

struct WeekGridRow: View {
    let habit: Habit
    let daysInWeek: [Date]
    let referenceDate: Date
    let today: Date
    let onSelectHabit: () -> Void
    let onToggle: (Date) -> Void
    let onSkip: (Date) -> Void

    private var habitColor: Color { habit.habitColor }
    private var completedCount: Int { habit.completedDaysThisWeek(reference: referenceDate) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            Button(action: onSelectHabit) {
                HStack(alignment: .center, spacing: AppSpacing.m) {
                    ZStack {
                        Circle()
                            .fill(habitColor.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: habit.iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(habitColor)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(habit.title)
                            .font(AppFont.bodyEmphasis)
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(AppFont.label)
                            .foregroundStyle(AppColor.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AppSpacing.s)

                    WeekProgressPill(
                        completed: completedCount,
                        target: habit.targetDaysPerWeek,
                        color: habitColor
                    )
                }
                .padding(.horizontal, AppSpacing.l)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: WeekGridLayout.cellSpacing) {
                ForEach(daysInWeek, id: \.self) { date in
                    WeekGridCell(
                        state: cellState(for: date),
                        habitColor: habitColor,
                        onTap: { onToggle(date) },
                        onSkip: { onSkip(date) }
                    )
                    .overlay {
                        if AppCalendar.isSameDay(date, today) {
                            todayRing
                        }
                    }
                }
            }
            .padding(WeekGridLayout.trayInnerPadding)
            .background(AppColor.bgSunken.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
            .padding(.horizontal, WeekGridLayout.trayOuterInset)
        }
        .padding(.vertical, AppSpacing.l)
        .background(AppColor.bgElevated)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(habitColor)
                .frame(width: WeekGridLayout.accentStripWidth)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(habitColor.opacity(0.14), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
        .padding(.vertical, 2)
    }

    /// Continúa la banda vertical de "hoy" que arranca en el strip de días.
    private var todayRing: some View {
        RoundedRectangle(cornerRadius: AppRadius.s + 2, style: .continuous)
            .strokeBorder(AppColor.accent.opacity(0.45), lineWidth: 1.5)
            .frame(width: WeekGridLayout.cellSize + 4, height: WeekGridLayout.cellSize + 4)
            .allowsHitTesting(false)
    }

    private var subtitle: String {
        if habit.trackingKind == .quantity {
            return habit.targetPerSessionText
        }
        return habit.scheduleSummaryText
    }

    private func cellState(for date: Date) -> WeekGridCell.State {
        let startOfDay = AppCalendar.startOfDay(for: date)
        let todayStart = AppCalendar.startOfDay(for: today)

        if startOfDay > todayStart {
            return .future
        }

        if !habit.isLoggable(on: date) {
            return .inactive
        }

        let entriesForDay = habit.entries.filter { AppCalendar.isSameDay($0.date, date) }
        let stateEntriesForDay = entriesForDay.filter { $0.kind != .urge }
        let isCompleted = habit.isCompleted(on: date)
        let isSkipped = habit.isSkipped(on: date)
        let totalValue = habit.totalValue(on: date)
        let isPartial = habit.trackingKind == .quantity && totalValue > 0 && !isCompleted

        // Confianza: si TODAS las marcas son `.manual`, es retroactiva.
        let onlyManualEntries = !stateEntriesForDay.isEmpty
            && stateEntriesForDay.allSatisfy { $0.source == .manual }

        if isCompleted {
            return onlyManualEntries ? .completedRetro : .completed
        }
        if habit.isMinimumCompleted(on: date) {
            return .minimum
        }
        if isSkipped {
            return .skipped
        }
        if habit.isFreezeProtected(on: date) {
            return .frozen
        }
        if habit.isSlip(on: date) {
            return .slip
        }
        if habit.isMissed(on: date) {
            return .missed
        }
        if habit.hasUrge(on: date) {
            return .urge
        }
        if isPartial {
            return onlyManualEntries ? .partialRetro : .partial
        }
        return .pending
    }
}

private struct WeekProgressPill: View {
    let completed: Int
    let target: Int
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("\(completed)/\(target)")
                .font(AppFont.label)
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, 5)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}
