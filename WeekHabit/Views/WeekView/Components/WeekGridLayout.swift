//
//  WeekGridLayout.swift
//  WeekHabit
//
//  Contrato de alineación de la matriz semanal. El strip de días y las celdas
//  de cada fila reparten 7 columnas flexibles con el mismo spacing y los
//  mismos insets laterales, así las columnas quedan alineadas verticalmente
//  y la pantalla se lee como un solo calendario.
//

import SwiftUI

enum WeekGridLayout {
    static let accentStripWidth: CGFloat = 4
    static let cellSpacing: CGFloat = AppSpacing.s
    static let cellSize: CGFloat = 34

    /// Inset de las filas dentro de la List.
    static let listHorizontalInset: CGFloat = AppSpacing.l
    /// Padding de la bandeja de celdas respecto del borde de la card.
    static let trayOuterInset: CGFloat = AppSpacing.m
    /// Padding interno de la bandeja alrededor de las celdas.
    static let trayInnerPadding: CGFloat = AppSpacing.s

    /// Distancia del borde de pantalla a la primera/última columna de celdas.
    /// El strip de días usa este mismo inset para alinear sus columnas.
    static var gridHorizontalInset: CGFloat {
        listHorizontalInset + trayOuterInset + trayInnerPadding
    }
}
