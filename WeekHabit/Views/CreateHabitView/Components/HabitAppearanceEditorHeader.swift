//
//  HabitAppearanceEditorHeader.swift
//  WeekHabit
//

import SwiftUI

struct HabitAppearanceEditorHeader: View {
    let selectedIconName: String
    let selectedColor: Color
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            IconComponent(icon: selectedIconName, color: selectedColor)

            VStack(alignment: .leading, spacing: 3) {
                Text("Apariencia")
                    .font(AppFont.subtitle3)
                    .foregroundStyle(AppColor.strongText)

                Text("Elige cómo se identifica este hábito")
                    .font(AppFont.formSectionText2)
                    .foregroundStyle(AppColor.subtleText)
            }

            Spacer()

            IconButton(icon: "xmark", style: .circle, action: onClose)
        }
    }
}
