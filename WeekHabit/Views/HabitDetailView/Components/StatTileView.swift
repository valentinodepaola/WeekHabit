//
//  StatTileView.swift
//  WeekHabit
//

import SwiftUI

struct StatTileView: View {
    let caption: String
    let value: String
    let footer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(AppFont.formSectionText2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.subtleText)

            Text(value)
                .font(AppFont.subtitle)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.strongText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(footer)
                .font(AppFont.formSectionText2)
                .foregroundStyle(AppColor.mutedText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}

#Preview {
    HStack {
        StatTileView(caption: "ESTA SEMANA", value: "3/5", footer: "60% de meta")
        StatTileView(caption: "REFERENCIA", value: "8", footer: "tu marca para volver")
    }
    .padding()
    .background(AppColor.bgLight)
}
