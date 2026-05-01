//
//  WeekEmptyStateCard.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//

import SwiftUI

struct WeekEmptyStateCard: View {
    private var text1: Text {
        Text("Una semana ")
            .font(AppFont.subtitle)
    }

    private var text2: Text {
        Text("por escribir")
            .font(AppFont.subtitle.italic())
            .italic()
            .foregroundStyle(AppColor.accent)
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColor.accentSoft)
                    .frame(width: 64, height: 64)
                Image(systemName: "calendar")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(AppColor.accent)
            }

            text1 + text2

            Text("Aún no hay marcas. La cuadrícula se irá llenando a medida que completes hábitos.")
                .font(AppFont.body2)
                .foregroundStyle(AppColor.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(AppColor.subtleText.opacity(0.12), lineWidth: 1)
        }
    }
}

#Preview {
    WeekEmptyStateCard()
}
