//
//  TodayEmptyStateView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 30/04/26.
//

import SwiftUI

struct TodayEmptyStateView: View {
    
    var iconColor: Color = AppColor.highPurple
    var fillColor: Color = AppColor.accentSoft
    var insideCirculeColor: Color = AppColor.lowPurple
    let weekdayName: String
    let tomorrowHabitsCount: Int
    var onAddHabitForToday: () -> Void
    
    private var text1: Text {
        Text("Hoy toca")
            .font(AppFont.subtitle)
    }
    
    private var text2: Text {
        Text("descansar")
            .font(AppFont.subtitle.italic())
            .foregroundStyle(AppColor.accent)
        
    }
    
    private var text3: Text {
        Text("No hay hábitos programados para los \(weekdayName). El descanso también construye semana.")
            .font(AppFont.body2)
            .foregroundStyle(AppColor.mutedText)
    }

    private var tomorrowSummary: String {
        switch tomorrowHabitsCount {
        case 0:
            return "Sin hábitos programados"
        case 1:
            return "1 hábito te espera"
        default:
            return "\(tomorrowHabitsCount) hábitos te esperan"
        }
    }
    
    var body: some View {
        VStack(spacing: 28) {
            EmptyStateIcon(
                iconColor: iconColor,
                fillColor: fillColor,
                insideCirculeColor: insideCirculeColor,
                icon: "moon"
            )

            VStack(spacing: 15) {
                text1 + Text(" ") + text2

                text3
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            tomorrowCard

            Button {
                onAddHabitForToday()
            } label: {
                Text("Añadir un hábito para hoy")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                    .underline()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Añadir un hábito para hoy")
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var tomorrowCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "sun.max")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color(hex: "#7ab06d"))
                .frame(width: 52, height: 52)
                .background(Color(hex: "#e9f5e3"))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))

            VStack(alignment: .leading, spacing: 2) {
                Text("MAÑANA")
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.subtleText)

                Text(tomorrowSummary)
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(AppColor.strongText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 26)
        .frame(maxWidth: 345)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(AppColor.subtleText.opacity(0.12), lineWidth: 1)
        }
    }
}


#Preview {
    TodayEmptyStateView(
        weekdayName: "martes",
        tomorrowHabitsCount: 3
    ) { }
}
