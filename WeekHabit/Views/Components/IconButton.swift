//
//  IconButton.swift
//  WeekHabit
//
//  Brand button shared across screens. Two shapes via `Style`.
//

import SwiftUI

struct IconButton: View {
    enum Style {
        case circle
        case pill
    }

    var icon: String? = nil
    var text: String? = nil
    var style: Style = .pill
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            content
        }
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .circle:
            Image(systemName: icon ?? "circle")
                .font(.system(size: 20).bold())
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(AppColor.accent)
                .clipShape(Circle())
        case .pill:
            HStack {
                if let icon {
                    Image(systemName: icon)
                }
                if let text {
                    Text(text)
                }
            }
            .fontWeight(.bold)
            .frame(width: 270, height: 50)
            .background(AppColor.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
            .padding(.horizontal)
        }
    }

    private var accessibilityLabel: String {
        text ?? icon ?? "Botón"
    }
}

#Preview {
    VStack(spacing: 16) {
        IconButton(icon: "plus", style: .circle) { }
        IconButton(icon: "plus", text: "Crear mi primer hábito", style: .pill) { }
        IconButton(text: "Empezar mi semana", style: .pill) { }
    }
}
