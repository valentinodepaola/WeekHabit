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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconComponent(
                icon: habit.iconName,
                color: habit.habitColor
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(AppFont.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)

                if let trimmedCue {
                    cueLine(trimmedCue)
                }

                if let experimentSubtitle {
                    Text(experimentSubtitle)
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.mutedText)
                        .lineLimit(1)
                } else if shouldShowScheduleFallback {
                    Text(scheduleFallbackText)
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.mutedText)
                        .lineLimit(1)
                }
            }
            
            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                streakIndicator

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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func cueLine(_ cue: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(habit.habitColor)

            Text(cue)
                .font(AppFont.formSectionText2)
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(2)
        }
        .padding(.top, 1)
    }

    private var trimmedCue: String? {
        guard let cue = habit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }

        return cue
    }

    private var trimmedNote: String? {
        guard let note = habit.note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !note.isEmpty else {
            return nil
        }

        return note
    }

    private var shouldShowScheduleFallback: Bool {
        trimmedCue == nil
    }

    private var scheduleFallbackText: String {
        if habit.trackingKind == .quantity {
            return habit.targetPerSessionText
        }

        return "Diario"
    }

    private var streakIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))

            Text("\(streakCount)")
                .font(AppFont.formSectionText)
                .monospacedDigit()
        }
        .foregroundStyle(streakColor)
        .accessibilityLabel(streakAccessibilityLabel)
    }

    private var streakCount: Int {
        habit.displayStreak(reference: referenceDate)
    }

    private var streakAccessibilityLabel: String {
        streakCount == 0
            ? "Listo para volver a empezar"
            : "\(streakCount) días seguidos"
    }

    private var streakColor: Color {
        streakCount > 0 ? .orange : AppColor.subtleText
    }

    private var experimentSubtitle: String? {
        guard let activeExperiment else { return nil }

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
            cue: "Después de servirme el café de la mañana",
            iconName: "sparkles",
            colorHex: "#c89046",
            targetDaysPerWeek: 3,
            activeDaysOfWeek: [.monday, .tuesday, .wednesday]
        ),
        isCompleted: false,
        onToggle: {}
    )
}
