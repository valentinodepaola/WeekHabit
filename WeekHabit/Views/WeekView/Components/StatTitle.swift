//
//  StatTitle.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 01/05/26.
//
import SwiftUI

struct StatTile: View {
    
    let label: String
    let value: String
    var detail: String? = nil
    var detailColor: Color = AppColor.mutedText

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(label)
                .font(AppFont.formSectionText2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.mutedText)
                .tracking(1.1)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 23, weight: .semibold, design: .default))
                    .foregroundStyle(value == "—" ? AppColor.subtleText : AppColor.strongText)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                if let detail {
                    Text(detail)
                        .font(AppFont.formSectionText2)
                        .fontWeight(.bold)
                        .foregroundStyle(detailColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(AppColor.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(Color(hex: "#e8dcc8"), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }
}
