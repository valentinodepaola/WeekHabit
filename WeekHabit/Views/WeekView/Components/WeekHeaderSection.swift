//
//  WeekHeaderSection.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//

import SwiftUI

struct WeekHeaderSection: View {
    
    var monthYearLabel: String
    var weekNumber: Int
    @Binding var weekOffset: Int
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(monthYearLabel)
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)

            HStack(spacing: 16) {
                Text("Semana \(weekNumber)")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.strongText)

                Spacer()

                if weekOffset != 0 {
                    Button("Hoy") {
                        withAnimation(.spring(duration: 0.35)) {
                            weekOffset = 0
                        }
                    }
                    .font(AppFont.formSectionText)
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColor.accentSoft, in: Capsule())
                }

                HStack(spacing: 8) {
                    navButton(systemName: "chevron.left") {
                        withAnimation(.spring(duration: 0.35)) {
                            weekOffset -= 1
                        }
                    }

                    navButton(systemName: "chevron.right") {
                        withAnimation(.spring(duration: 0.35)) {
                            weekOffset += 1
                        }
                    }
                    .disabled(weekOffset >= 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }
}

private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColor.strongText)
            .frame(width: 40, height: 40)
            .background(AppColor.surface)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(AppColor.subtleText.opacity(0.12), lineWidth: 1)
            }
    }
    .buttonStyle(.plain)
}
