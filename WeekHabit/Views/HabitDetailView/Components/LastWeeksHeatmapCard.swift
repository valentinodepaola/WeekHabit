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
                    weekIndex: weekIndex,
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
                    weeklyIntensities: matrix.indices.map(intensity),
                    didScrollToLatestWeek: $didScrollToLatestWeek,
                    color: color
                )
                
                heatmapLegend
            }
        } else {
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                HStack(alignment: .firstTextBaseline) {
                    headerTitle

                    Spacer()

                    heatmapLegend
                }

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

    private var heatmapLegend: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("menos")
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                RoundedRectangle(cornerRadius: 2)
                    .fill(intensityFill(intensity))
                    .frame(width: 9, height: 9)
            }
            Text("más")
                .font(AppFont.micro)
                .foregroundStyle(AppColor.textTertiary)
        }
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
        case 0: return 0
        case 0...0.25: return 0.25
        case 0.25...0.5: return 0.5
        case 0.5...0.75: return 0.75
        default: return 1
        }
    }

    private func color(for state: CellState, intensity: Double) -> Color {
        switch state {
        case .completed:
            return habit.habitColor.opacity(max(0.35, intensity))
        case .minimum:
            return habit.habitColor.opacity(0.42)
        case .skipped:
            return habit.habitColor.opacity(0.18)
        case .frozen:
            return AppColor.info.opacity(0.24)
        case .missed:
            return habit.habitColor.opacity(0.08)
        case .slip:
            return AppColor.warning.opacity(0.28)
        case .urge:
            return habit.habitColor.opacity(0.18)
        case .inactive, .future:
            return AppColor.bgSunken
        }
    }

    private func intensityFill(_ intensity: Double) -> Color {
        if intensity == 0 {
            return habit.habitColor.opacity(0.12)
        }
        return habit.habitColor.opacity(max(0.35, intensity))
    }
}

private struct HeatmapCell: Identifiable {
    let id: Int
    let weekIndex: Int
    let state: CellState
}

private struct YearHeatmapBody: View {
    let weeks: Int
    let matrix: [[CellState]]
    let weeklyIntensities: [Double]
    @Binding var didScrollToLatestWeek: Bool
    let color: (CellState, Double) -> Color
    
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
                                intensity: weeklyIntensities.indices.contains(weekIndex)
                                    ? weeklyIntensities[weekIndex]
                                    : 0,
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
    let intensity: Double
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let color: (CellState, Double) -> Color
    
    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(weekStates.indices, id: \.self) { dayIndex in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(weekStates[dayIndex], intensity))
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
