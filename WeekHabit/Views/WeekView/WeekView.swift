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

    private var completedDisplay: String {
        let completed = completedThisWeek
        return completed == 0 ? "—" : "\(completed)"
    }

    private var totalGoal: Int {
        visibleHabits.reduce(0) { $0 + $1.targetDaysPerWeek }
    }

    private var completedThisWeek: Int {
        visibleHabits.reduce(0) { partial, habit in
            partial + habit.completedDaysThisWeek(reference: referenceDate)
        }
    }

    private var consistencyDisplay: String {
        guard totalGoal > 0, completedThisWeek > 0 else { return "—" }
        let percentage = min(1, Double(completedThisWeek) / Double(totalGoal)) * 100
        return "\(Int(percentage))%"
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
                    
                    dayStrip
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
    
    private var dayStrip: some View {
        HStack(spacing: WeekGridLayout.cellSpacing) {
            ForEach(daysInWeek, id: \.self) { date in
                DayColumn(date: date, isToday: AppCalendar.isSameDay(date, .now))
            }
        }
        .padding(.leading, 34)
        .padding(.trailing, 30)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var contentArea: some View {
        if visibleHabits.isEmpty {
            WeekEmptyStateCard()
                .padding(.horizontal, 16)
            Spacer()
        } else {
            List {
                ForEach(visibleHabits) { habit in
                    WeekGridRow(
                        habit: habit,
                        daysInWeek: daysInWeek,
                        referenceDate: referenceDate,
                        today: .now,
                        onSelectHabit: { selectedHabit = habit },
                        onToggle: { date in toggleCompletion(for: habit, on: date) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section {
                    summarySection
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 0, trailing: 16))
                }
            }
            .listStyle(.plain)
            .listRowSpacing(6)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, 120, for: .scrollContent)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESUMEN")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)

            HStack(spacing: 10) {
                StatTile(label: "Completados", value: completedDisplay, icon: "checkmark.circle.fill")
                StatTile(label: "Meta total", value: "\(totalGoal)", icon: "target")
                StatTile(label: "Consistencia", value: consistencyDisplay, icon: "chart.bar.fill")
            }
        }
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
