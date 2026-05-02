//
//  SplashScreenMotion.swift
//  WeekHabit
//

import SwiftUI

enum SplashScreenMotion {
    static let reveal = Animation.spring(response: 0.58, dampingFraction: 0.82).delay(0.04)
    static let progress = Animation.easeInOut(duration: 1.28).delay(0.16)
    static let pulse = Animation.easeInOut(duration: 1.55).repeatForever(autoreverses: true)

    static func dayNode(index: Int) -> Animation {
        .spring(response: 0.34, dampingFraction: 0.74).delay(Double(index) * 0.035)
    }

    static func weekStrip(index: Int) -> Animation {
        .easeInOut(duration: 0.22).delay(Double(index) * 0.04)
    }
}
