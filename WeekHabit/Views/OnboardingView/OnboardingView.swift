//
//  OnboardingView.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 24/04/26.
//

import SwiftUI

struct OnboardingView: View {
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
                            .foregroundStyle(AppColor.accent)
                        Text("Construye habitos que si se sostienen - día a día, sin presión.")
                            .font(AppFont.body2)
                            .foregroundStyle(AppColor.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 60)
                    }
                }
            }
            
            VStack {
                Spacer()
                IconButton(text: "Empezar mi semana", style: .pill) { }
                    .padding()
                Text("Ya tengo una cuenta")
                    .font(AppFont.captionApp)
                    .foregroundStyle(AppColor.subtleText)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
