//
//  TodayHabitComponent.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 27/04/26.
//

import SwiftUI

struct TodayHabitComponent: View {
    let habit: Habit
    let isCompleted: Bool
    var activeExperiment: HabitExperiment?
    var referenceDate: Date = .now
    let onToggle: () -> Void
    
    private var category: HabitCategory {
        self.habit.displayCategory
    }
    
    var body: some View {
        HStack(spacing: 12) {
            IconComponent(
                icon: category.icon,
                color: category.color
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(AppFont.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                self.onToggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(self.isCompleted ? AppColor.accent : AppColor.surface)
                        .frame(width: 35, height: 35)
                        .overlay {
                            Circle()
                                .stroke(
                                    self.isCompleted ? AppColor.accent : AppColor.subtleText.opacity(0.18),
                                    lineWidth: 1
                                )
                        }
                    if self.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var subtitle: String {
        guard let activeExperiment else {
            if habit.trackingKind == .quantity {
                return "\(habit.targetPerSessionText) · \(habit.scheduleSummaryText)"
            }

            return "\(category.displayTitle) · \(habit.scheduleSummaryText) · racha \(habit.displayStreak())d"
        }

        if activeExperiment.needsReview(reference: referenceDate) {
            return "Prueba lista para revisar en Insights"
        }

        if let suggestedHourText = activeExperiment.suggestedHourText {
            return "Prueba · \(suggestedHourText)"
        }

        return "Prueba activa · \(activeExperiment.daySummary)"
    }
}


#Preview {
    TodayHabitComponent(
        habit: Habit(
            title: "Tender cama",
            category: .personal,
            targetDaysPerWeek: 3,
            activeDaysOfWeek: [.monday, .tuesday, .wednesday]
        ),
        isCompleted: false,
        onToggle: {}
    )
}
