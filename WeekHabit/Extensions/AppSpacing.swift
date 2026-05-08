//
//  AppSpacing.swift
//  WeekHabit
//
//  Escala 4pt. Toda dimensión de padding, gap y margin va por aquí.
//

import Foundation
import CoreGraphics

enum AppSpacing {

    /// 2pt — micro-ajustes.
    static let xxs: CGFloat = 2
    /// 4pt — gap entre icono y texto adyacente.
    static let xs: CGFloat = 4
    /// 8pt — gap interno de chips, separación de elementos próximos.
    static let s: CGFloat = 8
    /// 12pt — gap entre elementos de una card.
    static let m: CGFloat = 12
    /// 16pt — padding lateral estándar de pantalla, gap entre cards.
    static let l: CGFloat = 16
    /// 24pt — separación entre secciones de pantalla.
    static let xl: CGFloat = 24
    /// 32pt — separación de bloques mayores.
    static let xxl: CGFloat = 32
    /// 48pt — separación de hero a contenido.
    static let xxxl: CGFloat = 48
    /// 64pt — espaciado de respiración para narrativas largas.
    static let huge: CGFloat = 64
}
