//
//  OnboardingStep.swift
//  WeekHabit
//

enum OnboardingStep: Int, CaseIterable {
    case intro
    case smallStart
    case weeklyRhythm
    case notifications
    case starterHabit

    var showsProgress: Bool {
        self != .intro
    }

    var progressIndex: Int {
        max(0, rawValue - 1)
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    static var progressCount: Int {
        allCases.filter(\.showsProgress).count
    }
}
