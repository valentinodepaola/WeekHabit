//
//  SplashScreenAnimationState.swift
//  WeekHabit
//

import CoreGraphics

struct SplashScreenAnimationState {
    var didAppear = false
    var contentIsVisible = false
    var ringProgress: CGFloat = 0.06
    var pulseIsExpanded = false

    mutating func markAppeared() -> Bool {
        guard !didAppear else { return false }
        didAppear = true
        return true
    }

    mutating func applyReducedMotion() {
        contentIsVisible = true
        ringProgress = 1
        pulseIsExpanded = false
    }

    mutating func revealContent() {
        contentIsVisible = true
    }

    mutating func completeRing() {
        ringProgress = 1
    }

    mutating func expandPulse() {
        pulseIsExpanded = true
    }
}
