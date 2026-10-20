//
//  TodayHabitGroup.swift
//  WeekHabit
//
//  Grupo de filas de Hoy: cada sección de hábitos se lee como una sola tarjeta con
//  separadores. Cada hábito sigue siendo su propia fila de la lista, porque las acciones
//  al deslizar solo funcionan así; el grupo lo dibuja el fondo de cada fila.
//

import SwiftUI

/// Lugar de una fila dentro de su grupo: decide qué esquinas se redondean y si lleva
/// separador arriba.
enum TodayGroupPosition {
    case only
    case first
    case middle
    case last

    init(index: Int, count: Int) {
        switch (index, count) {
        case (_, ...1): self = .only
        case (0, _): self = .first
        case (count - 1, _): self = .last
        default: self = .middle
        }
    }

    var roundsTop: Bool { self == .only || self == .first }
    var roundsBottom: Bool { self == .only || self == .last }
    var hasSeparator: Bool { self == .middle || self == .last }
}

/// Tono del grupo: el fondo de los completados es un poco más apagado que el de los pendientes.
enum TodayGroupTone {
    case standard
    case muted

    var fill: Color {
        switch self {
        case .standard: return AppColor.bgElevated
        case .muted: return AppColor.bgElevated.opacity(0.72)
        }
    }

}

enum TodayGroupLayout {
    /// Dónde empieza el separador: después de la zona de toque de la casilla, para que
    /// la línea quede bajo el texto, como en las listas de iOS.
    static let separatorLeading: CGFloat = AppSpacing.xs + 44 + AppSpacing.xs

    /// En iPad las filas son las mismas; la lista solo se limita a un ancho cómodo de leer.
    static let maxListWidth: CGFloat = 640
}

extension View {
    /// Fila de un hábito dentro de su grupo. El espacio después del grupo va en la última
    /// fila, porque entre filas del mismo grupo no hay aire.
    func todayGroupedRow(_ position: TodayGroupPosition, tone: TodayGroupTone = .standard) -> some View {
        listRowInsets(
            EdgeInsets(
                top: 0,
                leading: AppSpacing.l,
                bottom: position.roundsBottom ? AppSpacing.m : 0,
                trailing: AppSpacing.l
            )
        )
        .listRowSeparator(.hidden)
        .listRowBackground(TodayGroupRowBackground(position: position, tone: tone))
    }
}

/// El tramo de tarjeta que le toca a una fila. Queda fijo mientras la fila se desliza
/// para mostrar sus acciones.
private struct TodayGroupRowBackground: View {
    let position: TodayGroupPosition
    let tone: TodayGroupTone

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: position.roundsTop ? AppRadius.l : 0,
                bottomLeadingRadius: position.roundsBottom ? AppRadius.l : 0,
                bottomTrailingRadius: position.roundsBottom ? AppRadius.l : 0,
                topTrailingRadius: position.roundsTop ? AppRadius.l : 0
            )
            .fill(tone.fill)

            // Borde sólido: cada fila dibuja su tramo y donde dos se tocan se enciman;
            // con un color translúcido esa unión se vería como una marca más oscura.
            TodayGroupRowBorder(position: position, radius: AppRadius.l)
                .stroke(AppColor.divider, lineWidth: 1)

            if position.hasSeparator {
                Rectangle()
                    .fill(AppColor.divider)
                    .frame(height: 1)
                    .padding(.leading, TodayGroupLayout.separatorLeading)
            }
        }
        .padding(.horizontal, AppSpacing.l)
        .padding(.bottom, position.roundsBottom ? AppSpacing.m : 0)
        .accessibilityHidden(true)
    }
}

/// Borde del grupo repartido entre sus filas: los lados siempre, y arriba o abajo solo en
/// la primera y la última, para que el contorno se lea continuo.
private struct TodayGroupRowBorder: Shape {
    let position: TodayGroupPosition
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: 0.5, dy: 0.5)
        var path = Path()

        if position == .only {
            path.addRoundedRect(in: r, cornerSize: CGSize(width: radius, height: radius), style: .circular)
            return path
        }

        if position.roundsBottom {
            // Última fila: baja por la derecha, rodea las esquinas de abajo y sube por la izquierda.
            path.move(to: CGPoint(x: r.maxX, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
            path.addArc(tangent1End: CGPoint(x: r.maxX, y: r.maxY), tangent2End: CGPoint(x: r.maxX - radius, y: r.maxY), radius: radius)
            path.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
            path.addArc(tangent1End: CGPoint(x: r.minX, y: r.maxY), tangent2End: CGPoint(x: r.minX, y: r.maxY - radius), radius: radius)
            path.addLine(to: CGPoint(x: r.minX, y: r.minY))
        } else if position.roundsTop {
            // Primera fila: sube por la izquierda, rodea las esquinas de arriba y baja por la derecha.
            path.move(to: CGPoint(x: r.minX, y: r.maxY))
            path.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
            path.addArc(tangent1End: CGPoint(x: r.minX, y: r.minY), tangent2End: CGPoint(x: r.minX + radius, y: r.minY), radius: radius)
            path.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
            path.addArc(tangent1End: CGPoint(x: r.maxX, y: r.minY), tangent2End: CGPoint(x: r.maxX, y: r.minY + radius), radius: radius)
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        } else {
            // Fila de en medio: solo los dos lados.
            path.move(to: CGPoint(x: r.minX, y: r.minY))
            path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            path.move(to: CGPoint(x: r.maxX, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        }
        return path
    }
}

#Preview {
    List {
        ForEach(0 ..< 3, id: \.self) { index in
            Text("Pendiente \(index + 1)")
                .font(AppFont.bodyEmphasis)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.leading, TodayGroupLayout.separatorLeading)
                .todayGroupedRow(TodayGroupPosition(index: index, count: 3))
        }

        Text("Completado")
            .font(AppFont.bodyEmphasis)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.leading, TodayGroupLayout.separatorLeading)
            .todayGroupedRow(.only, tone: .muted)
    }
    .listStyle(.plain)
    .listRowSpacing(0)
    .scrollContentBackground(.hidden)
    .background(AppColor.bgCanvas)
}
