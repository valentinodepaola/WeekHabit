//
//  AppRadius.swift
//  WeekHabit
//
//  Corner radius scale. Keep single-use radii local; promote here when shared.
//

import Foundation

enum AppRadius {
    static let small: CGFloat = 10  // chips, day toggles
    static let medium: CGFloat = 12 // cards, badges, text fields
    static let large: CGFloat = 14  // primary CTA
    static let pill: CGFloat = 15   // pill containers, round controls
}
