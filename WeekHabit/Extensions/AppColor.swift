//
//  AppColor.swift
//  WeekHabit
//
//  Brand palette. Add new tokens here instead of inlining `Color(hex:)`.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppColor {
    static let accent       = Color(hex: "#c45f36")
    static let accentSoft   = adaptive(light: "#ead8bf", dark: "#3a201a")
    static let strongText   = adaptive(light: "#211d19", dark: "#f5eee6")
    static let mutedText    = adaptive(light: "#7a6d59", dark: "#c9bfb1")
    static let subtleText   = adaptive(light: "#a99b83", dark: "#8b8175")
    static let surface      = adaptive(light: "#fffdf8", dark: "#211b18")
    static let surfaceMuted = adaptive(light: "#eee6d7", dark: "#2a231f")
    static let bgLight      = adaptive(light: "#f8f1e6", dark: "#181312")
    static let bgDark       = Color(hex: "#121010")
    static let lowPurple    = adaptive(light: "#eae4f4", dark: "#30293b")
    static let highPurple   = adaptive(light: "#7065d4", dark: "#b8a8df")

    // Row actions
    static let editAction        = Color(hex: "#5c89a8")
    static let destructiveAction = Color(hex: "#c4423a")

    private static func adaptive(light: String, dark: String) -> Color {
        #if canImport(UIKit)
        Color(UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? dark : light)
        })
        #else
        Color(hex: light)
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(hex: String) {
        let hex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat

        switch hex.count {
        case 6:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            opacity = 1
        case 8:
            red = CGFloat((value & 0xFF000000) >> 24) / 255
            green = CGFloat((value & 0x00FF0000) >> 16) / 255
            blue = CGFloat((value & 0x0000FF00) >> 8) / 255
            opacity = CGFloat(value & 0x000000FF) / 255
        default:
            red = 0
            green = 0
            blue = 0
            opacity = 1
        }

        self.init(red: red, green: green, blue: blue, alpha: opacity)
    }
}
#endif
