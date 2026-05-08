//
//  WHDayBadge.swift
//  WeekHabit
//
//  Badge de día: letra inicial + estado. Reemplaza DayColumn ad-hoc cuando
//  WeekView se migre. También usado por selectores de schedule en
//  CreateHabitView.
//

import SwiftUI

struct WHDayBadge: View {
    let initial: String
    var isSelected: Bool = false
    var isToday: Bool = false
    var isCompleted: Bool = false
    var size: CGFloat = 36
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                Text(initial)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(textColor)
                if isCompleted {
                    Circle()
                        .strokeBorder(AppColor.success, lineWidth: 2)
                }
            }
            .frame(width: size, height: size)
            .overlay(todayMarker)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    @ViewBuilder
    private var todayMarker: some View {
        if isToday && !isSelected && !isCompleted {
            Circle()
                .strokeBorder(AppColor.accent, lineWidth: 1.5)
        }
    }

    private var backgroundColor: Color {
        if isSelected { return AppColor.accent }
        if isCompleted { return AppColor.success.opacity(0.15) }
        return AppColor.bgElevated
    }

    private var textColor: Color {
        if isSelected { return Color.white }
        if isCompleted { return AppColor.success }
        return AppColor.textSecondary
    }
}
