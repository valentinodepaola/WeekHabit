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
        VStack(alignment: .leading, spacing: 6) {
            Text(monthYearLabel)
                .font(AppFont.captionApp)
                .fontWeight(.bold)
                .tracking(1.4)
                .foregroundStyle(AppColor.mutedText)

            HStack(alignment: .center, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Semana \(weekNumber)")
                        .font(.system(size: 27, weight: .bold, design: .default))
                        .foregroundStyle(AppColor.strongText)

                    Text(statusText)
                        .font(.system(size: 17, weight: .semibold, design: .serif).italic())
                        .foregroundStyle(AppColor.mutedText)
                        .lineLimit(1)
                }
                .minimumScaleFactor(0.86)

                Spacer()

                if weekOffset != 0 {
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            weekOffset = 0
                        }
                    } label: {
                        Text("Hoy")
                            .font(AppFont.formSectionText)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
                    }
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
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 20)
    }

    private var statusText: String {
        if weekOffset == 0 { return "en curso" }
        if weekOffset == -1 { return "semana pasada" }
        return "hace \(abs(weekOffset)) semanas"
    }
}

private func navButton(systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColor.strongText)
            .frame(width: 40, height: 40)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
            }
    }
    .buttonStyle(.plain)
}
