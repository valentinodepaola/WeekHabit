//
//  EmptyStateView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        
        EmptyStateIcon()
        
        VStack(spacing: 25) {
            Text("Tu semana está en blanco")
                .font(AppFont.subtitle)
            (
                Text("Elige un pequeño habito. El cambio empieza con lo que haces ")
                    .font(AppFont.body2)
                    .foregroundStyle(Color(hex: "#6b6458"))
                +
                Text("mañana por la mañana")
                    .font(AppFont.body2)
                    .foregroundStyle(Color(hex: "#c2573c"))
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 50)
            
            ButtonWithIcon(
                icon: "plus",
                text: "Crear mi primer hábito"
            ){
                //falta accion.
            }
        }
        .padding(.top, 30)
    }
}

#Preview {
    EmptyStateView()
}
