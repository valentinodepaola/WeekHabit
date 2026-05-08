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
        if isCompleted {
            completedRow
        } else {
            pendingCard
        }
    }

    private var pendingCard: some View {
        HStack(alignment: .center, spacing: 16) {
            completionButton

            VStack(alignment: .leading, spacing: 5) {
                Text(habit.title)
                    .font(.system(size: 17, weight: .bold, design: .default))
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                subtitle
            }

            Spacer(minLength: 10)

            pendingAccessory
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
    }

    private var completedRow: some View {
        HStack(alignment: .center, spacing: 16) {
            completionButton

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.title)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundStyle(AppColor.mutedText)
                    .strikethrough(true, color: AppColor.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)

                Text(completionDetail)
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
    }

    private var completionButton: some View {
        Button {
            onToggle()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isCompleted ? AppColor.accent : AppColor.surface)
                    .frame(width: 29, height: 29)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                isCompleted ? AppColor.accent : Color(hex: "#d7c8ad"),
                                lineWidth: 1
                            )
                    }

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? "Desmarcar \(habit.title)" : "Marcar \(habit.title)")
    }

    @ViewBuilder
    private var subtitle: some View {
        if let trimmedCue {
            cueLine(trimmedCue)
        } else if let experimentSubtitle {
            Text(experimentSubtitle)
                .font(.system(size: 13, weight: .semibold, design: .serif).italic())
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(2)
        } else {
            Text(scheduleFallbackText)
                .font(.system(size: 13, weight: .semibold, design: .serif).italic())
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(2)
        }
    }

    private func cueLine(_ cue: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColor.accent)

            Text(cue)
                .font(.system(size: 13, weight: .semibold, design: .serif).italic())
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var pendingAccessory: some View {
        if let reminderTimeText {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color(hex: "#eadcc4"))
                    .frame(width: 1, height: 34)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(reminderTimeText)
                        .font(AppFont.formSectionText)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.accent)
                        .monospacedDigit()

                    Text("CUE")
                        .font(AppFont.formSectionText2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.mutedText)
                        .tracking(0.9)
                }
            }
        } else {
            Image(systemName: habit.iconName)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(habit.habitColor)
                .frame(width: 34, height: 34)
        }
    }

    private var trimmedCue: String? {
        guard let cue = habit.cue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cue.isEmpty else {
            return nil
        }

        return cue
    }

    private var scheduleFallbackText: String {
        if habit.trackingKind == .quantity {
            return habit.targetPerSessionText
        }

        return "La señal todavía se está formando"
    }

    private var reminderTimeText: String? {
        guard habit.isReminderEnabled, let reminderTime = habit.reminderTime else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: reminderTime)
    }

    private var completionDetail: String {
        let valueText = quantityCompletionText
        let base = "\(completionTimeText) · \(completionSourceText)"
        guard let valueText else { return base }
        return "\(base) · \(valueText)"
    }

    private var completionTimeText: String {
        guard let date = entryForReference?.completedAt else {
            return "Hoy"
        }

        let formatter = DateFormatter()
        formatter.calendar = AppCalendar.current
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var completionSourceText: String {
        switch entryForReference?.source {
        case .focusSession:
            return "sesión de ritmo"
        case .manual:
            return "marca manual"
        case .today, .none:
            return "marca confiable"
        }
    }

    private var quantityCompletionText: String? {
        guard habit.trackingKind == .quantity else { return nil }
        let value = Habit.formattedQuantity(habit.totalValue(on: referenceDate))
        let unit = habit.unitDisplayText
        return unit.isEmpty ? value : "\(value) \(unit)"
    }

    private var entryForReference: HabitEntry? {
        habit.entries
            .filter { AppCalendar.isSameDay($0.date, referenceDate) }
            .sorted {
                ($0.completedAt ?? $0.date) > ($1.completedAt ?? $1.date)
            }
            .first
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
    VStack(spacing: 16) {
        TodayHabitComponent(
            habit: Habit(
                title: "Planear mi día",
                cue: "Después del café de la mañana",
                iconName: "calendar",
                colorHex: "#c45f36",
                targetDaysPerWeek: 3,
                activeDaysOfWeek: [.monday, .tuesday, .wednesday],
                isReminderEnabled: true,
                reminderTime: .now
            ),
            isCompleted: false,
            onToggle: {}
        )

        TodayHabitComponent(
            habit: Habit(
                title: "Tender la cama",
                cue: "Después de despertar",
                iconName: "checkmark",
                colorHex: "#c45f36",
                targetDaysPerWeek: 7,
                activeDaysOfWeek: Set(Weekday.ordered),
                scheduleKind: .daily
            ),
            isCompleted: true,
            onToggle: {}
        )
    }
    .padding()
    .background(AppColor.bgLight)
}
