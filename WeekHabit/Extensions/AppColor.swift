//
//  AppColor.swift
//  WeekHabit
//
//  Paleta "lounge cálido / papel manila".
//  Modo oscuro prioritario. Modo claro derivado en simetría.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppColor {

    // MARK: - Backgrounds

    /// Fondo principal de pantalla. Café-tinta profundo en oscuro, papel manila en claro.
    static let bgCanvas = adaptive(light: "#f5efe3", dark: "#1a1410")
    /// Superficies elevadas: cards, paneles. Un escalón arriba del canvas.
    static let bgElevated = adaptive(light: "#fffaf0", dark: "#221a14")
    /// Superficies hundidas: inputs, áreas que reciben contenido.
    static let bgSunken = adaptive(light: "#ebe3d3", dark: "#14100c")

    // MARK: - Text

    static let textPrimary = adaptive(light: "#2a1f15", dark: "#f3e9d8")
    static let textSecondary = adaptive(light: "#6b5d4a", dark: "#bcae97")
    static let textTertiary = adaptive(light: "#9c8e7c", dark: "#7d7263")

    // MARK: - Accent (terracotta)

    static let accent = adaptive(light: "#b54d2d", dark: "#e07a4d")
    /// Fondo de chip o estado seleccionado.
    static let accentMuted = adaptive(light: "#f3d9cf", dark: "#3a201a")
    /// Variante intermedia para hover/pressed.
    static let accentSubtle = adaptive(light: "#e6c2b3", dark: "#4d2b22")

    // MARK: - Semantic (tierra, no Material)

    /// Salvia. Cierres, rachas confirmadas.
    static let success = adaptive(light: "#5d8a4a", dark: "#7fa869")
    /// Ámbar suave. Bajos datos, baja confianza.
    static let warning = adaptive(light: "#a8762e", dark: "#d9a35b")
    /// Púrpura tenue. Insights y experimentos.
    static let info = adaptive(light: "#6b5e8e", dark: "#9c8fb8")
    static let infoMuted = adaptive(light: "#eae4f4", dark: "#30293b")

    // MARK: - Structure

    static let divider = adaptive(light: "#e5dccb", dark: "#2e2620")

    // MARK: - Row actions

    static let editAction = adaptive(light: "#5c89a8", dark: "#7ba4c4")
    static let destructiveAction = adaptive(light: "#b54a40", dark: "#d56158")

    // MARK: - Legacy aliases
    // Mantenemos compatibilidad hasta limpieza en Fase 8. No agregar nuevos usos.

    static let strongText = textPrimary
    static let mutedText = textSecondary
    static let subtleText = textTertiary
    static let surface = bgElevated
    static let surfaceMuted = bgCanvas
    static let bgLight = bgCanvas
    static let bgDark = bgCanvas
    static let lowPurple = infoMuted
    static let highPurple = info
    static let accentSoft = accentMuted

    // MARK: - Adaptive helper

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
