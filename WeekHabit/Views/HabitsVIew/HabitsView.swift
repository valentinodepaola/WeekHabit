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
            VStack() {
                HStack {
                    Text("Hábitos")
                        .font(AppFont.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CircleButtonIcon(
                        icon: "plus"
                    ) {
                        isShowingCreateHabit = true
                    }
                    
                }
                .padding(.horizontal)
                .padding(.top, 15)
                Spacer()
                
                if habits.isEmpty {
                    EmptyStateView {
                        isShowingCreateHabit = true
                    }
                }
                
                Spacer()
                
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

