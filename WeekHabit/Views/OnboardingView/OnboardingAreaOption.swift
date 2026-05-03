//
//  OnboardingAreaOption.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingAreaOption: Identifiable {
    let category: HabitCategory
    let icon: String
    let color: Color

    var id: HabitCategory { category }
    var title: String { category.displayTitle }

    static let all: [OnboardingAreaOption] = [
        OnboardingAreaOption(category: .health, icon: "heart", color: Color(hex: "#7fa774")),
        OnboardingAreaOption(category: .personal, icon: "brain.head.profile", color: Color(hex: "#8b7fb0")),
        OnboardingAreaOption(category: .learning, icon: "book.closed", color: Color(hex: "#c89046")),
        OnboardingAreaOption(category: .work, icon: "briefcase", color: Color(hex: "#5c89a8"))
    ]
}
