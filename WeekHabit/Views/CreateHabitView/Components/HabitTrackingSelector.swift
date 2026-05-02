//
//  HabitTrackingSelector.swift
//  WeekHabit
//

import SwiftUI

struct HabitTrackingSelector: View {
    @Binding var trackingKind: HabitTrackingKind

    var body: some View {
        HStack(spacing: 10) {
            HabitOptionButton(
                title: "Check",
                subtitle: "Solo marcar hecho",
                icon: "checkmark.circle.fill",
                isSelected: trackingKind == .check
            ) {
                trackingKind = .check
            }

            HabitOptionButton(
                title: "Cantidad",
                subtitle: "Min, páginas, km...",
                icon: "number.circle.fill",
                isSelected: trackingKind == .quantity
            ) {
                trackingKind = .quantity
            }
        }
    }
}
