//
//  TodayView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @Query(sort: \HabitExperiment.startedAt, order: .reverse)
    private var experiments: [HabitExperiment]
    
    @State private var createHabitRoute: TodayCreateHabitRoute?
    @State private var isShowingFocusSession = false
    @State private var quantityHabit: Habit?

    private var referenceDate: Date {
        Date()
    }
    
    private var currentWeekday: Weekday {
        AppCalendar.weekday(of: referenceDate)
    }
    
    private var currentDayTitle: String {
        currentWeekday.displayName
    }
    
    private var currentDayNameForSentence: String {
        currentDayTitle.lowercased(with: Locale(identifier: "es_MX"))
    }

    private var currentDateTitle: String {
        let locale = Locale(identifier: "es_MX")
        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = locale
        formatter.dateFormat = "EEEE d 'DE' MMMM"
        return formatter
            .string(from: referenceDate)
            .folding(options: .diacriticInsensitive, locale: locale)
            .uppercased(with: locale)
    }
    
    private var todayHabits: [Habit] {
        habits.filter { habit in
            habit.isLoggable(on: referenceDate)
        }
    }
    
    private var tomorrowDate: Date {
        AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
    }
    
    private var tomorrowHabitsCount: Int {
        habits.filter { habit in
            habit.isLoggable(on: tomorrowDate)
        }.count
    }

    private var completedTodayCount: Int {
        todayHabits.filter { isCompleteForTodayList($0) }.count
    }

    private var remainingTodayCount: Int {
        max(todayHabits.count - completedTodayCount, 0)
    }

    private var dailyProgress: Double {
        guard !todayHabits.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(todayHabits.count)
    }

    var body: some View {
        AppBackground {
            if todayHabits.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 15)

                    emptyTodayContent
                }
            } else {
                todayHabitsContent
            }
        }
        .fullScreenCover(item: $createHabitRoute) { route in
            switch route {
            case .today(let weekday):
                CreateHabitView(
                    initialDaysPerWeek: 1,
                    initialActiveDays: [weekday]
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingFocusSession) {
            FocusSessionView(habits: todayHabits)
        }
        .sheet(item: $quantityHabit) { habit in
            QuantityLogSheet(
                habit: habit,
                date: referenceDate,
                initialValue: habit.totalValue(on: referenceDate)
            ) { value in
                upsertQuantityEntry(for: habit, on: referenceDate, value: value, source: .today)
            }
            .presentationDetents([.height(310)])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(currentDateTitle)
                .font(AppFont.captionApp)
                .foregroundStyle(AppColor.mutedText)

            Text("Buenos días")
                .font(AppFont.title)
        }
    }

    private var emptyTodayContent: some View {
        ZStack {
            TodayEmptyStateView(
                weekdayName: currentDayNameForSentence,
                tomorrowHabitsCount: tomorrowHabitsCount
            ) {
                createHabitRoute = .today(currentWeekday)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 120)
    }

    private var todayHabitsContent: some View {
        ScrollView() {
            VStack(alignment: .leading, spacing: 18) {
                header

                DailyProgressCard(
                    progress: dailyProgress,
                    completedCount: completedTodayCount,
                    totalCount: todayHabits.count,
                    remainingCount: remainingTodayCount
                )

                FocusSessionLauncherCard(
                    remainingCount: remainingTodayCount,
                    onStart: { isShowingFocusSession = true }
                )

                HStack {
                    Text("Habitos de hoy")
                        .font(AppFont.subtitle2)
                    Spacer()
                    Text(self.currentDayTitle)
                        .font(AppFont.body2)
                        .foregroundStyle(AppColor.mutedText)
                }

                ForEach(todayHabits) { habit in
                    TodayHabitComponent(
                        habit: habit,
                        isCompleted: isCompleteForTodayList(habit),
                        activeExperiment: experiments.activeExperiment(
                            for: habit.id,
                            reference: referenceDate
                        ),
                        referenceDate: referenceDate
                    ) {
                        toggleCompletion(for: habit)
                    }
                }

                if let top = todayHabits.topStreakHabit(reference: referenceDate) {
                    LongestStreakBanner(
                        habitTitle: top.habit.title,
                        streakDays: top.streak,
                        allSameStreak: todayHabits.allShareSameCurrentStreak(reference: referenceDate)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .padding(.bottom, 120)
        }
    }

    private func toggleCompletion(for habit: Habit) {
        if habit.trackingKind == .quantity {
            quantityHabit = habit
            return
        }

        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            if entriesForToday.isEmpty {
                let entry = HabitEntry(
                    date: referenceDate,
                    completedAt: .now,
                    source: .today,
                    value: 1,
                    habit: habit
                )
                modelContext.insert(entry)
            } else {
                entriesForToday.forEach { entry in
                    modelContext.delete(entry)
                }
            }
        }
    }

    private func isCompleteForTodayList(_ habit: Habit) -> Bool {
        if habit.isFlexibleSchedule && habit.completedDaysThisWeek(reference: referenceDate) >= habit.targetDaysPerWeek {
            return true
        }

        return habit.isCompleted(on: referenceDate)
    }

    private func upsertQuantityEntry(
        for habit: Habit,
        on date: Date,
        value: Double,
        source: HabitEntrySource
    ) {
        let entriesForDay = habit.entries.filter {
            AppCalendar.isSameDay($0.date, date)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            if value <= 0 {
                entriesForDay.forEach { modelContext.delete($0) }
                return
            }

            if let entry = entriesForDay.first {
                entry.value = value
                entry.completedCount = Int(value.rounded())
                entry.completedAt = .now
                entry.source = source
                entriesForDay.dropFirst().forEach { modelContext.delete($0) }
            } else {
                modelContext.insert(
                    HabitEntry(
                        date: date,
                        completedAt: .now,
                        source: source,
                        completedCount: Int(value.rounded()),
                        value: value,
                        habit: habit
                    )
                )
            }
        }
    }
}

private enum TodayCreateHabitRoute: Identifiable {
    case today(Weekday)
    
    var id: String {
        switch self {
        case .today(let weekday):
            return "today-\(weekday.rawValue)"
        }
    }
}


#Preview {
    TodayView()
}
