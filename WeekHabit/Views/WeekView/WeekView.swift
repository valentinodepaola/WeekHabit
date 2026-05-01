//
//  WeekView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query private var entries: [HabitEntry]
    @State private var weekOffset: Int = 0

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

    private var isWeekEmpty: Bool {
        entriesThisWeek.isEmpty
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
        AppBackground {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    dayStrip
                    contentArea
                    summarySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthYearLabel)
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)

            HStack(spacing: 16) {
                Text("Semana \(weekNumber)")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.strongText)

                Spacer()

                HStack(spacing: 8) {
                    navButton(systemName: "chevron.left") {
                        weekOffset -= 1
                    }

                    navButton(systemName: "chevron.right") {
                        weekOffset += 1
                    }
                    .disabled(weekOffset >= 0)
                }
            }
        }
    }

    private var dayStrip: some View {
        HStack(spacing: 0) {
            ForEach(daysInWeek, id: \.self) { date in
                DayColumn(date: date, isToday: AppCalendar.isSameDay(date, .now))
            }
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if isWeekEmpty {
            WeekEmptyStateCard()
        } else {
            WeekGridView(entries: entriesThisWeek, habits: habits)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESUMEN")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)

            HStack(spacing: 10) {
                StatTile(label: "Completados", value: completedDisplay)
                StatTile(label: "Meta total", value: "\(totalGoal)")
                StatTile(label: "Consistencia", value: consistencyDisplay)
            }
        }
    }

    private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.strongText)
                .frame(width: 40, height: 40)
                .background(AppColor.surface)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AppColor.subtleText.opacity(0.12), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct DayColumn: View {
    let date: Date
    let isToday: Bool

    private var dayAbbrev: String {
        AppCalendar.weekday(of: date)
            .shortName
            .uppercased(with: Locale(identifier: "es_MX"))
    }

    private var dayNumber: String {
        String(AppCalendar.current.component(.day, from: date))
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayAbbrev)
                .font(AppFont.formSectionText)
                .foregroundStyle(isToday ? .white : AppColor.mutedText)

            Text(dayNumber)
                .font(AppFont.dayLabel)
                .foregroundStyle(isToday ? .white : AppColor.strongText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isToday ? AppColor.accent : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}

private struct WeekGridView: View {
    let entries: [HabitEntry]
    let habits: [Habit]

    var body: some View {
        EmptyView()
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(AppFont.subtitle2)
                .foregroundStyle(value == "—" ? AppColor.subtleText : AppColor.strongText)

            Text(label)
                .font(AppFont.formSectionText2)
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}

#Preview {
    WeekView()
}
