//
//  LastWeeksHeatmapCard.swift
//  WeekHabit
//

import SwiftUI

struct LastWeeksHeatmapCard: View {
    let habit: Habit
    var weeks: Int = 10
    var referenceDate: Date = .now
    
    @State private var didScrollToLatestWeek = false

    private var matrix: [[CellState]] {
        habit.completionMatrix(weeks: weeks, reference: referenceDate)
    }

    private var heatmapCells: [HeatmapCell] {
        matrix.enumerated().flatMap { weekIndex, week in
            week.enumerated().map { dayIndex, state in
                HeatmapCell(
                    id: weekIndex * rowCount + dayIndex,
                    state: state
                )
            }
        }
    }

    private let cellSpacing: CGFloat = 6
    private let cellCornerRadius: CGFloat = 5
    private let rowCount = 7

    var body: some View {
        content
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }
    
    @ViewBuilder
    private var content: some View {
        if weeks > 12 {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                headerTitle
                
                YearHeatmapBody(
                    weeks: weeks,
                    matrix: matrix,
                    didScrollToLatestWeek: $didScrollToLatestWeek,
                    color: color
                )
            }
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                headerTitle
                heatmapGrid
            }
        }
    }
    
    private var headerTitle: some View {
        Text("ÚLTIMAS \(weeks) SEMANAS")
            .font(AppFont.label)
            .foregroundStyle(AppColor.textTertiary)
            .tracking(0.6)
    }

    private var heatmapGrid: some View {
        HeatmapGridLayout(
            columns: matrix.count,
            rows: rowCount,
            spacing: cellSpacing
        ) {
            ForEach(heatmapCells) { cell in
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                    .fill(color(for: cell.state))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func color(for state: CellState) -> Color {
        switch state {
        case .completed:
            return habit.habitColor
        case .frozen:
            return AppColor.info.opacity(0.24)
        case .inactive, .future, .minimum, .skipped, .missed, .slip, .urge:
            return AppColor.bgSunken
        }
    }
}

private struct HeatmapCell: Identifiable {
    let id: Int
    let state: CellState
}

private struct YearHeatmapBody: View {
    let weeks: Int
    let matrix: [[CellState]]
    @Binding var didScrollToLatestWeek: Bool
    let color: (CellState) -> Color
    
    private let cellSize: CGFloat = 10
    private let cellSpacing: CGFloat = 3
    private let weekdayLabelWidth: CGFloat = 14
    
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.s) {
            weekdayLabels
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(matrix.indices, id: \.self) { weekIndex in
                            YearHeatmapWeekColumn(
                                weekStates: matrix[weekIndex],
                                cellSize: cellSize,
                                cellSpacing: cellSpacing,
                                color: color
                            )
                            .id(weekIndex)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Mapa de actividad de las últimas \(weeks) semanas")
                .accessibilityHint("Desliza horizontalmente para ver semanas anteriores")
                .onAppear {
                    guard !didScrollToLatestWeek, let lastWeekIndex = matrix.indices.last else { return }
                    didScrollToLatestWeek = true
                    proxy.scrollTo(lastWeekIndex, anchor: .trailing)
                }
            }
        }
    }
    
    private var weekdayLabels: some View {
        VStack(alignment: .center, spacing: cellSpacing) {
            ForEach(Weekday.ordered) { weekday in
                Text(weekday.oneLetterName)
                    .font(AppFont.micro)
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: weekdayLabelWidth, height: cellSize, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct YearHeatmapWeekColumn: View {
    let weekStates: [CellState]
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let color: (CellState) -> Color
    
    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(weekStates.indices, id: \.self) { dayIndex in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(weekStates[dayIndex]))
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }
}

private struct HeatmapGridLayout: Layout {
    let columns: Int
    let rows: Int
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard columns > 0, rows > 0 else { return .zero }

        let fallbackCellSize: CGFloat = 12
        let fallbackWidth = CGFloat(columns) * fallbackCellSize + CGFloat(max(0, columns - 1)) * spacing
        let width = max(0, proposal.width ?? fallbackWidth)
        let cellSize = cellSize(for: width)
        let height = CGFloat(rows) * cellSize + CGFloat(max(0, rows - 1)) * spacing

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard columns > 0, rows > 0 else { return }

        let cellSize = cellSize(for: bounds.width)
        let cellProposal = ProposedViewSize(width: cellSize, height: cellSize)

        for index in subviews.indices {
            let column = index / rows
            let row = index % rows
            guard column < columns else { continue }

            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + CGFloat(column) * (cellSize + spacing),
                    y: bounds.minY + CGFloat(row) * (cellSize + spacing)
                ),
                anchor: .topLeading,
                proposal: cellProposal
            )
        }
    }

    private func cellSize(for width: CGFloat) -> CGFloat {
        let totalHorizontalSpacing = CGFloat(max(0, columns - 1)) * spacing
        return max(0, (width - totalHorizontalSpacing) / CGFloat(columns))
    }
}

#Preview("10 semanas - light") {
    LastWeeksHeatmapCard(habit: HeatmapPreviewData.habit)
        .padding()
        .background(AppColor.bgCanvas)
        .preferredColorScheme(.light)
}

#Preview("52 semanas - light") {
    LastWeeksHeatmapCard(habit: HeatmapPreviewData.habit, weeks: 52)
        .padding()
        .background(AppColor.bgCanvas)
        .preferredColorScheme(.light)
}

#Preview("10 semanas - dark") {
    LastWeeksHeatmapCard(habit: HeatmapPreviewData.habit)
        .padding()
        .background(AppColor.bgCanvas)
        .preferredColorScheme(.dark)
}

#Preview("52 semanas - dark") {
    LastWeeksHeatmapCard(habit: HeatmapPreviewData.habit, weeks: 52)
        .padding()
        .background(AppColor.bgCanvas)
        .preferredColorScheme(.dark)
}

private enum HeatmapPreviewData {
    static var habit: Habit {
        let calendar = AppCalendar.current
        let reference = AppCalendar.startOfDay(for: .now)
        let createdAt = calendar.date(byAdding: .day, value: -360, to: reference) ?? reference
        let habit = Habit(
            title: "Meditar",
            iconName: "brain.head.profile",
            colorHex: "#8b7fb0",
            targetDaysPerWeek: 5,
            activeDaysOfWeek: Set(Weekday.ordered),
            createdAt: createdAt
        )
        
        habit.entries = (0..<350).compactMap { dayOffset in
            guard dayOffset % 3 != 1,
                  let date = calendar.date(byAdding: .day, value: dayOffset, to: createdAt) else {
                return nil
            }
            
            let kind: EntryKind
            switch dayOffset % 29 {
            case 0:
                kind = .minimum
            case 7:
                kind = .skipped
            case 14:
                kind = .missed
            default:
                kind = .completed
            }
            
            return HabitEntry(date: date, kind: kind, habit: habit)
        }
        
        return habit
    }
}
