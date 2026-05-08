//
//  WeekView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct WeekView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @State private var weekOffset: Int = 0
    @State private var selectedHabit: Habit?
    @State private var lastToggle: ToggleHaptic?
    @State private var quantityRoute: WeekQuantityLogRoute?

    private var referenceDate: Date {
        AppCalendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: .now) ?? .now
    }

    private var weekRange: Range<Date> {
        AppCalendar.weekRange(containing: referenceDate)
    }

    private var visibleHabits: [Habit] {
        habits.filter { habit in
            daysInWeek.contains { habit.isLoggable(on: $0) || habit.isCompleted(on: $0) }
        }
    }

    private var daysInWeek: [Date] {
        (0..<7).compactMap { dayOffset in
            AppCalendar.current.date(byAdding: .day, value: dayOffset, to: weekRange.lowerBound)
        }
    }

    private var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
            .string(from: referenceDate)
            .folding(options: .diacriticInsensitive, locale: formatter.locale)
            .uppercased(with: formatter.locale)
    }

    private var weekNumber: Int {
        AppCalendar.current.component(.weekOfYear, from: referenceDate)
    }

    private var totalGoal: Int {
        visibleHabits.reduce(0) { $0 + $1.targetDaysPerWeek }
    }

    private var completedThisWeek: Int {
        visibleHabits.reduce(0) { partial, habit in
            partial + habit.completedDaysThisWeek(reference: referenceDate)
        }
    }

    private var previousWeekMarks: Int {
        guard let previousReference = AppCalendar.current.date(
            byAdding: .weekOfYear,
            value: -1,
            to: referenceDate
        ) else {
            return 0
        }

        let previousWeek = AppCalendar.weekRange(containing: previousReference)
        let previousDays = (0..<7).compactMap { dayOffset in
            AppCalendar.current.date(byAdding: .day, value: dayOffset, to: previousWeek.lowerBound)
        }

        return habits.reduce(0) { partial, habit in
            partial + previousDays.filter { hasAnyMark(for: habit, on: $0) }.count
        }
    }

    private var consistencyPercent: Int {
        guard totalGoal > 0, completedThisWeek > 0 else { return 0 }
        return Int((min(1, Double(completedThisWeek) / Double(totalGoal)) * 100).rounded())
    }

    private var totalMarksThisWeek: Int {
        visibleHabits.reduce(0) { partial, habit in
            partial + daysInWeek.filter { hasAnyMark(for: habit, on: $0) }.count
        }
    }

    private var marksDisplay: String {
        totalMarksThisWeek == 0 ? "—" : "\(totalMarksThisWeek)"
    }

    private var trustedMarksThisWeek: Int {
        visibleHabits.reduce(0) { partial, habit in
            partial + daysInWeek.filter { hasTrustedMark(for: habit, on: $0) }.count
        }
    }

    private var trustedMarksDisplay: String {
        "\(trustedMarksThisWeek) / \(totalMarksThisWeek)"
    }

    private var daysWithMarks: Int {
        daysInWeek.filter { date in
            visibleHabits.contains { hasAnyMark(for: $0, on: date) }
        }
        .count
    }

    private var completedDeltaText: String {
        let delta = totalMarksThisWeek - previousWeekMarks
        if delta == 0 { return "0" }
        return delta > 0 ? "+\(delta)" : "\(delta)"
    }

    private var bestWeekdayText: String {
        let best = daysInWeek
            .map { date in
                (
                    weekday: AppCalendar.weekday(of: date),
                    count: visibleHabits.filter { hasAnyMark(for: $0, on: date) }.count
                )
            }
            .max { lhs, rhs in lhs.count < rhs.count }

        guard let best, best.count > 0 else { return "—" }
        return best.weekday.shortName
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                VStack(alignment: .leading, spacing: 0) {
                    WeekHeaderSection(
                        monthYearLabel: monthYearLabel,
                        weekNumber: weekNumber,
                        weekOffset: $weekOffset
                    )

                    contentArea
                }
                .navigationDestination(item: $selectedHabit) { habit in
                    HabitDetailView(habit: habit)
                }
                .sensoryFeedback(.success, trigger: lastToggle) { _, newValue in
                    if case .marked = newValue { return true }
                    return false
                }
                .sensoryFeedback(.impact(weight: .light), trigger: lastToggle) { _, newValue in
                    if case .unmarked = newValue { return true }
                    return false
                }
                .sheet(item: $quantityRoute) { route in
                    QuantityLogSheet(
                        habit: route.habit,
                        date: route.date,
                        initialValue: route.habit.totalValue(on: route.date)
                    ) { value in
                        upsertQuantityEntry(for: route.habit, on: route.date, value: value)
                    }
                    .presentationDetents([.height(310)])
                }
            }
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if visibleHabits.isEmpty {
            WeekEmptyStateCard()
                .padding(.horizontal, 24)
            Spacer()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WeekRhythmCard(
                        habits: visibleHabits,
                        daysInWeek: daysInWeek,
                        today: .now,
                        completionPercent: consistencyPercent,
                        daysWithMarks: daysWithMarks,
                        onSelectHabit: { habit in selectedHabit = habit },
                        onToggle: { habit, date in toggleCompletion(for: habit, on: date) }
                    )

                    weekInsightCard

                    summarySection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Resumen")
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(AppColor.strongText)

                Spacer()

                Text(previousWeekComparisonText)
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.mutedText)
            }

            HStack(spacing: 10) {
                StatTile(
                    label: "MARCAS",
                    value: marksDisplay,
                    detail: completedDeltaText,
                    detailColor: completedDeltaText.hasPrefix("+") ? Color(hex: "#2f8f61") : AppColor.mutedText
                )
                StatTile(
                    label: "CONFIABLES",
                    value: trustedMarksDisplay
                )
                StatTile(
                    label: "MEJOR DÍA",
                    value: bestWeekdayText
                )
            }
        }
    }

    private var weekInsightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "#f8ead6"))
                    .frame(width: 38, height: 38)

                Image(systemName: "lightbulb")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
            }

            Text(weekInsightText)
                .font(.system(size: 18, weight: .semibold, design: .serif).italic())
                .foregroundStyle(AppColor.strongText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }

    private var weekInsightText: String {
        if completedThisWeek == 0 {
            return "La semana todavía está abierta. Una marca pequeña ya cambia el ritmo."
        }

        if isCurrentWeek, !hasAnyMarkToday {
            return "Llevas \(daysWithMarks) días volviendo. Si marcas hoy, cierras mejor la semana."
        }

        if completedThisWeek >= totalGoal {
            return "Semana cerrada. Esta referencia te sirve para sostener el siguiente ciclo."
        }

        return "Llevas \(daysWithMarks) días con marcas. El ritmo ya dejó una señal útil."
    }

    private var isCurrentWeek: Bool {
        weekOffset == 0
    }

    private var hasAnyMarkToday: Bool {
        visibleHabits.contains { hasAnyMark(for: $0, on: .now) }
    }

    private var previousWeekComparisonText: String {
        if weekOffset == 0 {
            return "vs. semana \(weekNumber - 1)"
        }

        return "historial"
    }

    private func toggleCompletion(for habit: Habit, on date: Date) {
        if habit.trackingKind == .quantity {
            quantityRoute = WeekQuantityLogRoute(habit: habit, date: date)
            return
        }

        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }
        let willMark = entriesForDay.isEmpty

        withAnimation(.easeInOut(duration: 0.2)) {
            if willMark {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: nil,
                        source: .manual,
                        value: 1,
                        habit: habit
                    )
                )
            } else {
                entriesForDay.forEach { entry in
                    modelContext.delete(entry)
                }
            }
        }

        lastToggle = willMark ? .marked(UUID()) : .unmarked(UUID())
    }

    private func upsertQuantityEntry(for habit: Habit, on date: Date, value: Double) {
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }
        let willMark = value > 0

        withAnimation(.easeInOut(duration: 0.2)) {
            if value <= 0 {
                entriesForDay.forEach { entry in
                    modelContext.delete(entry)
                }
            } else if let entry = entriesForDay.first {
                entry.value = value
                entry.completedCount = Int(value.rounded())
                entry.completedAt = nil
                entry.source = .manual
                entriesForDay.dropFirst().forEach { modelContext.delete($0) }
            } else {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: nil,
                        source: .manual,
                        completedCount: Int(value.rounded()),
                        value: value,
                        habit: habit
                    )
                )
            }
        }

        lastToggle = willMark ? .marked(UUID()) : .unmarked(UUID())
    }

    private func hasAnyMark(for habit: Habit, on date: Date) -> Bool {
        habit.totalValue(on: date) > 0
    }

    private func hasTrustedMark(for habit: Habit, on date: Date) -> Bool {
        habit.entries.contains { entry in
            AppCalendar.isSameDay(entry.date, date)
                && entry.source.isTrustedForInsights
                && (entry.value ?? Double(entry.completedCount)) > 0
        }
    }

}

private struct WeekRhythmCard: View {
    let habits: [Habit]
    let daysInWeek: [Date]
    let today: Date
    let completionPercent: Int
    let daysWithMarks: Int
    let onSelectHabit: (Habit) -> Void
    let onToggle: (Habit, Date) -> Void

    private let labelWidth: CGFloat = 68
    private let cellSize: CGFloat = 28
    private let cellSpacing: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tu ritmo de la semana")
                        .font(.system(size: 21, weight: .semibold, design: .serif).italic())
                        .foregroundStyle(AppColor.strongText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("\(habits.count) \(habits.count == 1 ? "hábito" : "hábitos") · \(daysWithMarks) días con marcas")
                        .font(AppFont.captionApp)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColor.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(completionPercent)%")
                        .font(.system(size: 31, weight: .semibold, design: .default))
                        .foregroundStyle(AppColor.strongText)
                        .monospacedDigit()

                    Text("CUMPLIMIENTO")
                        .font(AppFont.formSectionText2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColor.mutedText)
                        .tracking(0.8)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                calendarHeader

                ForEach(habits) { habit in
                    HStack(alignment: .center, spacing: 10) {
                        Button {
                            onSelectHabit(habit)
                        } label: {
                            Text(habit.title)
                                .font(AppFont.formSectionText)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColor.strongText)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                                .frame(width: labelWidth, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: cellSpacing) {
                            ForEach(daysInWeek, id: \.self) { date in
                                WeekMatrixCell(
                                    state: matrixState(for: habit, on: date),
                                    isToday: AppCalendar.isSameDay(date, today)
                                ) {
                                    onToggle(habit, date)
                                }
                                .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }

            WeekLegend()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }

    private var calendarHeader: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Color.clear
                .frame(width: labelWidth, height: 35)

            HStack(spacing: cellSpacing) {
                ForEach(daysInWeek, id: \.self) { date in
                    VStack(spacing: 5) {
                        Text(AppCalendar.weekday(of: date).oneLetterName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColor.mutedText)

                        Text(dayNumber(for: date))
                            .font(AppFont.formSectionText2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppCalendar.isSameDay(date, today) ? AppColor.surface : AppColor.mutedText)
                            .frame(width: cellSize, height: 18)
                            .background {
                                if AppCalendar.isSameDay(date, today) {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(AppColor.strongText)
                                }
                            }
                    }
                    .frame(width: cellSize)
                }
            }
        }
    }

    private func dayNumber(for date: Date) -> String {
        "\(AppCalendar.current.component(.day, from: date))"
    }

    private func matrixState(for habit: Habit, on date: Date) -> WeekMatrixCell.State {
        let startOfDay = AppCalendar.startOfDay(for: date)
        let todayStart = AppCalendar.startOfDay(for: today)

        if startOfDay > todayStart {
            return .future
        }

        if !habit.isLoggable(on: date) {
            return .inactive
        }

        let entries = habit.entries.filter { AppCalendar.isSameDay($0.date, date) }
        let hasTrustedEntry = entries.contains {
            $0.source.isTrustedForInsights && ($0.value ?? Double($0.completedCount)) > 0
        }
        let hasAnyEntry = entries.contains {
            ($0.value ?? Double($0.completedCount)) > 0
        }

        if habit.isCompleted(on: date) {
            return hasTrustedEntry ? .trustedComplete : .manualComplete
        }

        if hasAnyEntry {
            return hasTrustedEntry ? .trustedPartial : .manualPartial
        }

        return .empty
    }
}

private struct WeekMatrixCell: View {
    enum State: Equatable {
        case trustedComplete
        case manualComplete
        case trustedPartial
        case manualPartial
        case empty
        case inactive
        case future
    }

    let state: State
    let isToday: Bool
    let onTap: () -> Void

    private var isInteractive: Bool {
        state != .inactive && state != .future
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(fillColor)
                    .overlay {
                        if isToday {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(AppColor.strongText, lineWidth: 2)
                        } else if state == .future || state == .inactive {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(
                                    Color(hex: "#c9b998"),
                                    style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                                )
                        }
                    }

                switch state {
                case .trustedComplete, .manualComplete:
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                case .trustedPartial, .manualPartial, .empty:
                    Circle()
                        .fill(dotColor)
                        .frame(width: 5, height: 5)
                case .inactive, .future:
                    EmptyView()
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(WeekMatrixCellButtonStyle())
        .disabled(!isInteractive)
        .accessibilityLabel(accessibilityLabel)
    }

    private var fillColor: Color {
        switch state {
        case .trustedComplete, .trustedPartial:
            return AppColor.accent
        case .manualComplete, .manualPartial:
            return Color(hex: "#d9ab94")
        case .empty, .inactive:
            return Color(hex: "#ece2cc")
        case .future:
            return Color(hex: "#f1e9d9")
        }
    }

    private var dotColor: Color {
        switch state {
        case .trustedPartial:
            return AppColor.surface
        case .manualPartial:
            return Color(hex: "#7b6e58")
        default:
            return Color(hex: "#c3b28f")
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .trustedComplete:
            return "Marca confiable completada"
        case .manualComplete:
            return "Marca manual completada"
        case .trustedPartial:
            return "Marca confiable parcial"
        case .manualPartial:
            return "Marca manual parcial"
        case .empty:
            return "Sin marca"
        case .inactive:
            return "Día inactivo"
        case .future:
            return "Por venir"
        }
    }
}

private struct WeekMatrixCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.84 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct WeekLegend: View {
    var body: some View {
        HStack(spacing: 13) {
            legendItem("Confiable", fill: AppColor.accent)
            legendItem("Manual", fill: Color(hex: "#d9ab94"))
            legendItem("Sin marca", fill: Color(hex: "#ece2cc"), dot: Color(hex: "#c3b28f"))
            legendItem("Por venir", fill: Color(hex: "#f1e9d9"), dashed: true)
        }
        .font(AppFont.formSectionText2)
        .foregroundStyle(AppColor.mutedText)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }

    private func legendItem(
        _ title: String,
        fill: Color,
        dot: Color? = nil,
        dashed: Bool = false
    ) -> some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(fill)
                    .frame(width: 12, height: 12)
                    .overlay {
                        if dashed {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(
                                    Color(hex: "#c9b998"),
                                    style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                                )
                        }
                    }

                if let dot {
                    Circle()
                        .fill(dot)
                        .frame(width: 4, height: 4)
                }
            }

            Text(title)
        }
    }
}

private enum ToggleHaptic: Equatable {
    case marked(UUID)
    case unmarked(UUID)
}

private struct WeekQuantityLogRoute: Identifiable {
    let habit: Habit
    let date: Date

    var id: String {
        "\(habit.id)-\(date.timeIntervalSinceReferenceDate)"
    }
}

#Preview {
    WeekView()
}
