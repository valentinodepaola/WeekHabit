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

    @Query private var entries: [HabitEntry]
    @State private var weekOffset: Int = 0
    @State private var selectedHabit: Habit?
    @State private var lastToggle: ToggleHaptic?

    private var referenceDate: Date {
        AppCalendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: .now) ?? .now
    }

    private var weekRange: Range<Date> {
        AppCalendar.weekRange(containing: referenceDate)
    }

    private var entriesThisWeek: [HabitEntry] {
        entries.filter { entry in
            weekRange.contains(entry.date)
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
        entriesThisWeek.isEmpty ? "—" : "\(entriesThisWeek.count)"
    }

    private var totalGoal: Int {
        habits.reduce(0) { $0 + $1.targetDaysPerWeek }
    }

    private var consistencyDisplay: String {
        guard totalGoal > 0, !entriesThisWeek.isEmpty else { return "—" }
        let percentage = Double(entriesThisWeek.count) / Double(totalGoal) * 100
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
        if habits.isEmpty {
            WeekEmptyStateCard()
                .padding(.horizontal, 16)
            Spacer()
        } else {
            List {
                ForEach(habits) { habit in
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
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }
        let willMark = entriesForDay.isEmpty

        withAnimation(.easeInOut(duration: 0.2)) {
            if willMark {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: AppCalendar.isSameDay(date, .now) ? .now : nil,
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

}

private enum ToggleHaptic: Equatable {
    case marked(UUID)
    case unmarked(UUID)
}

#Preview {
    WeekView()
}
