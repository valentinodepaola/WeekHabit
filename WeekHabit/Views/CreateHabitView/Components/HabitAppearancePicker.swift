//
//  HabitAppearancePicker.swift
//  WeekHabit
//

import SwiftUI

struct HabitAppearancePicker: View {
    @Binding var selectedIconName: String
    @Binding var selectedColorHex: String

    private let iconColumns = [
        GridItem(.adaptive(minimum: 46), spacing: 10)
    ]

    private let colorColumns = [
        GridItem(.adaptive(minimum: 38), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Apariencia")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                IconComponent(
                    icon: selectedIconName,
                    color: HabitAppearance.color(for: selectedColorHex)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Icono y color")
                        .font(AppFont.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.strongText)

                    Text("Así se verá el hábito en la app")
                        .font(AppFont.formSectionText2)
                        .foregroundStyle(AppColor.subtleText)
                }

                Spacer()
            }
            .padding(12)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

            LazyVGrid(columns: iconColumns, spacing: 10) {
                ForEach(HabitAppearance.iconNames, id: \.self) { iconName in
                    Button {
                        selectedIconName = iconName
                    } label: {
                        Image(systemName: iconName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(selectedIconName == iconName ? .white : HabitAppearance.color(for: selectedColorHex))
                            .frame(width: 46, height: 46)
                            .background(selectedIconName == iconName ? HabitAppearance.color(for: selectedColorHex) : AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .stroke(selectedIconName == iconName ? Color.clear : AppColor.subtleText.opacity(0.14), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(columns: colorColumns, spacing: 10) {
                ForEach(HabitAppearance.colorHexes, id: \.self) { colorHex in
                    let color = HabitAppearance.color(for: colorHex)

                    Button {
                        selectedColorHex = colorHex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 34, height: 34)

                            if selectedColorHex == colorHex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 42, height: 42)
                        .overlay {
                            Circle()
                                .stroke(color.opacity(selectedColorHex == colorHex ? 0.55 : 0), lineWidth: 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    HabitAppearancePicker(
        selectedIconName: .constant(HabitAppearance.defaultIconName),
        selectedColorHex: .constant(HabitAppearance.defaultColorHex)
    )
    .padding()
}
