//
//  AppFont.swift
//  WeekHabit
//
//  Escala tipográfica disciplinada con voz dual.
//  Serif (New York vía .serif) para display/title/headline — voz contemplativa.
//  Sans rounded (SF Rounded) para body/callout — voz operativa cálida.
//  Sans default para label/micro — voz técnica sobria.
//

import SwiftUI

enum AppFont {

    // MARK: - New scale (8 levels)

    /// 40pt serif — pantallas hito, cierres semanales.
    static let display = Font.system(size: 40, weight: .regular, design: .serif)
    /// 30pt serif — hero de pantalla.
    static let title = Font.system(size: 30, weight: .regular, design: .serif)
    /// 22pt serif medium — sección principal.
    static let headline = Font.system(size: 22, weight: .medium, design: .serif)
    /// 17pt rounded — cuerpo principal.
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    /// 17pt rounded semibold — énfasis.
    static let bodyEmphasis = Font.system(size: 17, weight: .semibold, design: .rounded)
    /// 15pt rounded — captions de card, subtítulos.
    static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
    /// 13pt sans medium — etiquetas, formularios.
    static let label = Font.system(size: 13, weight: .medium, design: .default)
    /// 11pt sans medium — tabs, badges, metadatos.
    static let micro = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Legacy aliases
    // Apuntan al token nuevo más cercano. No agregar nuevos usos —
    // deuda técnica a migrar gradualmente.

    static let title1 = display
    static let subtitle = headline
    static let subtitle2 = bodyEmphasis
    static let subtitle3 = headline
    static let body2 = callout
    static let captionApp = label
    static let formSectionText = label
    static let formSectionText2 = micro
    static let tabBarText = micro
    static let dayLabel = bodyEmphasis
}
