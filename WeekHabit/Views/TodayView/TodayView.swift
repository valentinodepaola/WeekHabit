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

    private var referenceDate: Date {
        Date()
    }
    
    private var todayHabits: [Habit] {
        habits.filter { habit in
            habit.isActive(on: referenceDate)
        }
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
    
    private var topStreakHabit: (habit: Habit, streak: Int)? {
        habits.map {
            ($0, $0.currentStreak(reference: referenceDate))
        }
        .max(by: { $0.1 < $1.1})
        .flatMap { $0.1 > 0 ? $0 : nil }
    }
    
    var body: some View {
        AppBackground {
            ScrollView() {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Buenos días")
                        .font(AppFont.title)

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
                        Text("Martes")
                            .font(AppFont.body2)
                            .foregroundStyle(AppColor.mutedText)
                    }
                    
                    ForEach(todayHabits) { habit in
                        TodayHabitComponent(
                            habit: habit,
                            isCompleted: habit.isCompleted(on: referenceDate)
                        ) {
                            toggleCompletion(for: habit)
                        }
                    }
                    
                    if let top = topStreakHabit {
                        LongestStreakBanner(
                            habitTitle: top.habit.title,
                            streakDays: top.streak
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }

    private func toggleCompletion(for habit: Habit) {
        let entriesForToday = habit.entries.filter {
            AppCalendar.isSameDay($0.date, referenceDate)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            if entriesForToday.isEmpty {
                let entry = HabitEntry(date: referenceDate, habit: habit)
                modelContext.insert(entry)
            } else {
                entriesForToday.forEach { entry in
                    modelContext.delete(entry)
                }
            }
        }
    }
}


#Preview {
    TodayView()
}
