//
//  WHCircleButton.swift
//  WeekHabit
//
//  Botón circular secundario de los encabezados: fondo elevado con borde, no acento.
//  Convive con el "+" relleno de acento, que sigue siendo inline en cada header porque es
//  la acción principal de su pantalla.
//

import SwiftUI

struct WHCircleButton: View {
    let systemName: String
    var size: CGFloat = 40
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.375, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .frame(width: size, height: size)
                .background(AppColor.bgElevated)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AppColor.divider, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    HStack(spacing: AppSpacing.s) {
        WHCircleButton(systemName: "questionmark") {}
        WHCircleButton(systemName: "chevron.left") {}
        WHCircleButton(systemName: "chevron.right") {}
    }
    .padding()
    .background(AppColor.bgCanvas)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    HStack(spacing: AppSpacing.s) {
        WHCircleButton(systemName: "questionmark") {}
        WHCircleButton(systemName: "chevron.left") {}
        WHCircleButton(systemName: "chevron.right") {}
    }
    .padding()
    .background(AppColor.bgCanvas)
    .preferredColorScheme(.dark)
}
