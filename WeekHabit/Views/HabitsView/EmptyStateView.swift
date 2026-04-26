//
//  EmptyStateView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct EmptyStateView: View {
    
    var onCreateHabit: () -> Void
    
    var body: some View {

        EmptyStateIcon()

        VStack(spacing: 25) {
            Text("Tu semana está en blanco")
                .font(AppFont.subtitle)
            (
                Text("Elige un pequeño habito. El cambio empieza con lo que haces ")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.mutedText)
                +
                Text("mañana por la mañana")
                    .font(AppFont.body2)
                    .foregroundStyle(AppColor.accent)
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 50)

            IconButton(
                icon: "plus",
                text: "Crear mi primer hábito",
                style: .pill
            ) {
                self.onCreateHabit()
            }
        }
        .padding(.top, 30)
    }
}

#Preview {
    EmptyStateView(
        onCreateHabit: { }
    )
}
