//
//  AppColor.swift
//  WeekHabit
//
//  Brand palette. Add new tokens here instead of inlining `Color(hex:)`.
//

import SwiftUI

enum AppColor {
    static let accent       = Color(hex: "#c2573c")
    static let accentSoft   = Color(hex: "#f3d9cf")
    static let strongText   = Color(hex: "#1c1812")
    static let mutedText    = Color(hex: "#6b6458")
    static let subtleText   = Color(hex: "#a8a091")
    static let surface      = Color.white
    static let surfaceMuted = Color(hex: "#fbf7f0")
    static let bgLight      = Color(hex: "#f5f1ea")
    static let bgDark       = Color(hex: "#121010")
    static let lowPurple    = Color(hex: "#eae4f4")
    static let highPurple   = Color(hex: "#8b7fb0")

    // Row actions
    static let editAction        = Color(hex: "#5c89a8")
    static let destructiveAction = Color(hex: "#c4423a")
}
