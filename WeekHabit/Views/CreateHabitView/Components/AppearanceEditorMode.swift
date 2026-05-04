//
//  AppearanceEditorMode.swift
//  WeekHabit
//

enum AppearanceEditorMode: String, CaseIterable, Identifiable {
    case icons
    case colors

    var id: String { rawValue }

    var title: String {
        switch self {
        case .icons: return "Iconos"
        case .colors: return "Colores"
        }
    }
}
