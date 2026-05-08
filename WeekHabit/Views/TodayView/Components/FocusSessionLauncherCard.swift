//
//  FocusSessionLauncherCard.swift
//  WeekHabit
//

import SwiftUI

struct FocusSessionLauncherCard: View {
    let remainingCount: Int
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColor.accent)
                        .frame(width: 44, height: 44)

                    Image(systemName: "play")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .offset(x: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sesión de ritmo")
                        .font(.system(size: 17, weight: .bold, design: .default))
                        .foregroundStyle(AppColor.surface)

                    Text(detail)
                        .font(AppFont.formSectionText)
                        .foregroundStyle(Color(hex: "#d5c4a8"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.84)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#d5c4a8"))
            }
            .padding(.horizontal, 19)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(AppColor.strongText)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(FocusSessionPressStyle())
        .accessibilityLabel("Iniciar sesión de ritmo")
    }

    private var detail: String {
        if remainingCount == 0 {
            return "Marcar aquí cuenta como evidencia para Insights"
        }

        return "Marcar aquí cuenta como evidencia para Insights"
    }
}

private struct FocusSessionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    FocusSessionLauncherCard(remainingCount: 2) {}
        .padding()
        .background(AppColor.bgLight)
}
