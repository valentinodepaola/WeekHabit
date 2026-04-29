//
//  LongestStreakBanner.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 28/04/26.
//

import SwiftUI

struct LongestStreakBanner: View {
    
    let habitTitle: String
    let streakDays: Int
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 14) {
                Image(systemName: "flame")
                    .font(AppFont.title)
                    .foregroundStyle(.white)
                    .padding()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("RACHA MAS LARGA")
                        .font(AppFont.formSectionText)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(self.habitTitle) · \(self.streakDays) dias 🔥")
                        .font(AppFont.subtitle3)
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            
        }
        .frame(maxWidth: .infinity, minHeight: 75)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(
                    LinearGradient(
                        colors: [AppColor.accent, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

#Preview {
    LongestStreakBanner(
        habitTitle: "Meditar",
        streakDays: 9
    )
}
