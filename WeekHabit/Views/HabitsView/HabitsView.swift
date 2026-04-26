//
//  HabitsView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI
import SwiftData

struct HabitsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var isShowingCreateHabit: Bool = false

    var emptyState: Bool = true
    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                HStack {
                    Text("Hábitos")
                        .font(AppFont.title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    IconButton(icon: "plus", style: .circle) {
                        isShowingCreateHabit = true
                    }

                }
                .padding(.horizontal)
                .padding(.top, 15)

                if habits.isEmpty {
                    Spacer()

                    EmptyStateView {
                        isShowingCreateHabit = true
                    }

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(habits) { habit in
                                HabitCard(habit: habit) { }
                            }
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingCreateHabit) {
                CreateHabitView()
            }
        }
    }
}

#Preview {
    HabitsView()
}
