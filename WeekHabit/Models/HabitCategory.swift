//
//  HabitCategory.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 25/04/26.
//
import SwiftUI

enum HabitCategory: String, CaseIterable {
    case health
    case work
    case personal
    case learning
    
    var title: String {
        switch self {
        case .health: return "Health"
        case .work: return "Work"
        case .personal: return "Personal"
        case .learning: return "Learning"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .learning: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return Color(hex: "#7fa774")
        case .work: return Color(hex: "#8b7fb0")
        case .personal: return Color(hex: "#c89046")
        case .learning: return Color(hex: "#5c89a8")
        }
    }
    
    static var allCases: [HabitCategory] {
        return [.health, .work, .personal, .learning]
    }

}
