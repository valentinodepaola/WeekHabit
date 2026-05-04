//
//  HabitAppearance.swift
//  WeekHabit
//

import SwiftUI

enum HabitAppearance {
    static let defaultIconName = "sparkles"
    static let defaultColorHex = "#c2573c"

    static let iconNames: [String] = [
        "sparkles",
        "heart.fill",
        "figure.walk",
        "drop.fill",
        "moon.fill",
        "sun.max.fill",
        "book.fill",
        "pencil",
        "brain.head.profile",
        "briefcase.fill",
        "checklist",
        "flame.fill",
        "leaf.fill",
        "fork.knife",
        "dumbbell.fill",
        "music.note",
        "paintbrush.fill",
        "timer",
        "bed.double.fill",
        "star.fill"
    ]

    static let colorHexes: [String] = [
        "#c2573c",
        "#7fa774",
        "#5c89a8",
        "#8b7fb0",
        "#c89046",
        "#d66b7d",
        "#4f9a8b",
        "#6f7fc8",
        "#b86f3d",
        "#5e8c61"
    ]

    static func color(for hex: String) -> Color {
        Color(hex: hex)
    }
}

enum LegacyHabitArea: String, Codable {
    case health
    case work
    case personal
    case learning

    var iconName: String {
        switch self {
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .learning: return "book.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .health: return "#7fa774"
        case .work: return "#8b7fb0"
        case .personal: return "#c89046"
        case .learning: return "#5c89a8"
        }
    }
}
