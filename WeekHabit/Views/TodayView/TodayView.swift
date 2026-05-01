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
            habit.isActive(on: referenceDate)
        }
    }
    
    private var tomorrowDate: Date {
        AppCalendar.current.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
    }
    
    private var tomorrowHabitsCount: Int {
        habits.filter { habit in
            habit.isActive(on: tomorrowDate)
        }.count
    }

    private var completedTodayCount: Int {
        todayHabits.filter { habit in
            habit.isCompleted(on: referenceDate)
        }.count
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
                        isCompleted: habit.isCompleted(on: referenceDate),
                        activeExperiment: experiments.activeExperiment(
                            for: habit.id,
                            reference: referenceDate
                        ),
                        referenceDate: referenceDate
                    ) {
                        toggleCompletion(for: habit)
                    }
                }

                if let top = habits.topStreakHabit(reference: referenceDate) {
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
        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            if entriesForToday.isEmpty {
                let entry = HabitEntry(date: referenceDate, completedAt: .now, habit: habit)
                modelContext.insert(entry)
            } else {
                entriesForToday.forEach { entry in
                    modelContext.delete(entry)
                }
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
