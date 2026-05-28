//
//  WeekRhythmCard.swift
//  WeekHabit
//

import SwiftUI

struct WeekRhythmCard: View {
    let habits: [Habit]
    let daysInWeek: [Date]
    let today: Date
    let onSelectHabit: (Habit) -> Void
    let onToggle: (Habit, Date) -> Void
    let onSkip: (Habit, Date) -> Void

    private let habitColumnWidth: CGFloat = 78
    private let cellSize: CGFloat = 30

    private var markedDaysCount: Int {
        daysInWeek.filter { date in
            habits.contains { habit in
                habit.entries.contains {
                    AppCalendar.isSameDay($0.date, date) && $0.kind != .urge
                }
            }
        }
        .count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            header
            calendarGrid
            legend
        }
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        }
        .appElevation(.low)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Tu ritmo de la semana")
                .font(.system(size: 20, weight: .semibold, design: .serif).italic())
                .foregroundStyle(AppColor.textPrimary)

            Text("\(habits.count) hábitos · \(markedDaysCount) días con marcas")
                .font(AppFont.label)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var calendarGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(horizontalSpacing: AppSpacing.xs, verticalSpacing: AppSpacing.xs) {
                GridRow {
                    Color.clear
                        .frame(width: habitColumnWidth, height: 30)

                    ForEach(daysInWeek, id: \.self) { date in
                        dayHeader(for: date)
                    }
                }

                ForEach(habits) { habit in
                    GridRow {
                        Button {
                            onSelectHabit(habit)
                        } label: {
                            Text(habit.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(width: habitColumnWidth, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        ForEach(daysInWeek, id: \.self) { date in
                            WeekRhythmCell(
                                state: cellState(for: habit, on: date),
                                color: habit.habitColor,
                                isToday: AppCalendar.isSameDay(date, today),
                                size: cellSize,
                                onTap: { onToggle(habit, date) },
                                onSkip: { onSkip(habit, date) }
                            )
                        }
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func dayHeader(for date: Date) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(AppCalendar.weekday(of: date).oneLetterName)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textSecondary)

            Text("\(AppCalendar.current.component(.day, from: date))")
                .font(AppFont.label)
                .monospacedDigit()
                .foregroundStyle(AppCalendar.isSameDay(date, today) ? AppColor.bgCanvas : AppColor.textSecondary)
                .frame(width: 26, height: 20)
                .background {
                    if AppCalendar.isSameDay(date, today) {
                        Capsule()
                            .fill(AppColor.textPrimary)
                    }
                }
        }
        .frame(width: cellSize)
    }

    private var legend: some View {
        HStack(spacing: AppSpacing.m) {
            legendItem(label: "Confiable") {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(AppColor.accent)
            }

            legendItem(label: "Manual") {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(AppColor.accent.opacity(0.38))
            }

            legendItem(label: "Sin marca") {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.xs)
                        .fill(AppColor.bgSunken)
                    Circle()
                        .fill(AppColor.textTertiary.opacity(0.55))
                        .frame(width: 4, height: 4)
                }
            }

            legendItem(label: "Por venir") {
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(AppColor.bgSunken.opacity(0.42))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.xs)
                            .strokeBorder(
                                AppColor.divider,
                                style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                            )
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func legendItem<Sample: View>(
        label: String,
        @ViewBuilder sample: () -> Sample
    ) -> some View {
        HStack(spacing: AppSpacing.xs) {
            sample()
                .frame(width: 12, height: 12)

            Text(label)
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }

    private func cellState(for habit: Habit, on date: Date) -> WeekRhythmCell.State {
        let startOfDay = AppCalendar.startOfDay(for: date)
        let todayStart = AppCalendar.startOfDay(for: today)

        guard startOfDay <= todayStart, habit.isLoggable(on: date) else {
            return .upcoming
        }

        let entriesForDay = habit.entries.filter { AppCalendar.isSameDay($0.date, date) }
        let stateEntriesForDay = entriesForDay.filter { $0.kind != .urge }
        let onlyManualEntries = !stateEntriesForDay.isEmpty
            && stateEntriesForDay.allSatisfy { $0.source == .manual }

        if habit.isCompleted(on: date) {
            return onlyManualEntries ? .manual : .trusted
        }

        if habit.isMinimumCompleted(on: date) || habit.trackingKind == .quantity && habit.totalValue(on: date) > 0 {
            return onlyManualEntries ? .manualDot : .trustedDot
        }

        if habit.isSkipped(on: date) || habit.isFreezeProtected(on: date) {
            return .rest
        }

        return .unmarked
    }
}

private struct WeekRhythmCell: View {
    enum State: Equatable {
        case trusted
        case manual
        case trustedDot
        case manualDot
        case rest
        case unmarked
        case upcoming
    }

    let state: State
    let color: Color
    let isToday: Bool
    let size: CGFloat
    let onTap: () -> Void
    let onSkip: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                shape

                switch state {
                case .trusted, .manual:
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                case .trustedDot, .manualDot, .unmarked:
                    Circle()
                        .fill(dotColor)
                        .frame(width: 5, height: 5)
                case .rest:
                    Image(systemName: "pause.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)
                case .upcoming:
                    EmptyView()
                }
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(state == .upcoming)
        .contextMenu {
            if state != .upcoming {
                Button {
                    onSkip()
                } label: {
                    Label(state == .rest ? "Quitar descanso" : "Descanso intencional", systemImage: "pause.circle")
                }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var shape: some View {
        let base = RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)

        switch state {
        case .trusted:
            base.fill(color)
                .overlay(todayBorder)
        case .manual:
            base.fill(color.opacity(0.48))
                .overlay(todayBorder)
        case .trustedDot:
            base.fill(color.opacity(0.18))
                .overlay(todayBorder)
        case .manualDot:
            base.fill(color.opacity(0.12))
                .overlay(todayBorder)
        case .rest:
            base.fill(color.opacity(0.12))
                .overlay {
                    base.strokeBorder(color.opacity(0.45), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
                }
                .overlay(todayBorder)
        case .unmarked:
            base.fill(AppColor.bgSunken.opacity(0.82))
                .overlay(todayBorder)
        case .upcoming:
            base.fill(AppColor.bgSunken.opacity(0.42))
                .overlay {
                    base.strokeBorder(AppColor.divider, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                }
        }
    }

    private var todayBorder: some View {
        RoundedRectangle(cornerRadius: AppRadius.s, style: .continuous)
            .strokeBorder(isToday ? AppColor.textPrimary : Color.clear, lineWidth: 2)
    }

    private var dotColor: Color {
        switch state {
        case .trustedDot:
            return color
        case .manualDot:
            return color.opacity(0.58)
        default:
            return AppColor.textTertiary.opacity(0.55)
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .trusted: return "Marca confiable"
        case .manual: return "Marca manual"
        case .trustedDot: return "Avance confiable"
        case .manualDot: return "Avance manual"
        case .rest: return "Descanso intencional"
        case .unmarked: return "Sin marca"
        case .upcoming: return "Por venir"
        }
    }
}
