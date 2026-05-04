//
//  LastWeeksHeatmapCard.swift
//  WeekHabit
//

import SwiftUI

struct LastWeeksHeatmapCard: View {
    let habit: Habit
    var weeks: Int = 10
    var referenceDate: Date = .now

    private var matrix: [[CellState]] {
        habit.completionMatrix(weeks: weeks, reference: referenceDate)
    }

    private var heatmapCells: [HeatmapCell] {
        matrix.enumerated().flatMap { weekIndex, week in
            week.enumerated().map { dayIndex, state in
                HeatmapCell(
                    id: weekIndex * rowCount + dayIndex,
                    weekIndex: weekIndex,
                    state: state
                )
            }
        }
    }

    private let cellSpacing: CGFloat = 7
    private let cellCornerRadius: CGFloat = 6
    private let rowCount = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ÚLTIMAS 10 SEMANAS")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .textCase(.uppercase)

            heatmapGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private var heatmapGrid: some View {
        HeatmapGridLayout(
            columns: matrix.count,
            rows: rowCount,
            spacing: cellSpacing
        ) {
            ForEach(heatmapCells) { cell in
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                    .fill(color(for: cell.state, intensity: intensity(for: cell.weekIndex)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func intensity(for weekIndex: Int) -> Double {
        guard matrix.indices.contains(weekIndex) else { return 0 }
        let ratio = matrix[weekIndex].completionRatio(target: habit.targetDaysPerWeek)

        switch ratio {
        case 0:
            return 0
        case 0...0.25:
            return 0.25
        case 0.25...0.5:
            return 0.5
        case 0.5...0.75:
            return 0.75
        default:
            return 1
        }
    }

    private func color(for state: CellState, intensity: Double) -> Color {
        switch state {
        case .completed:
            return habit.habitColor.opacity(max(0.25, intensity))
        case .missed:
            return habit.habitColor.opacity(0.10)
        case .inactive, .future:
            return AppColor.bgLight
        }
    }
}

private struct HeatmapCell: Identifiable {
    let id: Int
    let weekIndex: Int
    let state: CellState
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

#Preview {
    LastWeeksHeatmapCard(
        habit: Habit(
            title: "Meditar",
            iconName: "brain.head.profile",
            colorHex: "#8b7fb0",
            targetDaysPerWeek: 5,
            activeDaysOfWeek: Set(Weekday.ordered)
        )
    )
    .padding()
    .background(AppColor.bgLight)
}
