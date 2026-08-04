//
//  TabItems.swift
//  WeekHabit
//

import SwiftUI

/// Modelo de las tabs del shell nativo (`TabView`) en `ContentView`.
/// Provee el título y el ícono SF Symbol de cada tab.
enum TabItems: String {
    case today
    case week
    case insights

    var description: String {
        switch self {
        case .today: return "Hoy"
        case .week: return "Semana"
        case .insights: return "Insights"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .week: return "calendar"
        case .insights: return "align.vertical.bottom.fill"
        }
    }
}
