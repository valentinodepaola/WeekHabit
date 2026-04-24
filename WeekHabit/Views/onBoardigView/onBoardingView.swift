//
//  onBoardingView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
//

import SwiftUI

struct onBoardingView: View {
    var body: some View {
        AppBackground {
            
            ZStack {
                VStack {
                    RippleLogoView()
                    
                    VStack(spacing: 8) {
                        Text("Una semana.")
                            .font(AppFont.title1)
                        Text("Un ritmo.")
                            .font(AppFont.title1.italic())
                            .foregroundStyle(Color(hex: "#c2573c"))
                        Text("Construye habitos que si se sostienen - día a día, sin presión.")
                            .font(AppFont.body2)
                            .foregroundStyle(Color(hex: "#6b6458"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 60)
                    }
                }
            }
            
            VStack {
                Spacer()
                ButtonWithIcon(text: "Empezar mi semana") {
                    print("Empezar mi semana button")
                }
                .padding()
                Text("Ya tengo una cuenta")
                    .font(AppFont.captionApp)
                    .foregroundStyle(Color(hex: "#a8a091"))
                    
            }
        }
    }
}

#Preview {
    onBoardingView()
}
