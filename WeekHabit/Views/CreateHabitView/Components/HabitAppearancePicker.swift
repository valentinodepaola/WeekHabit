//
//  HabitAppearancePicker.swift
//  WeekHabit
//

import SwiftUI

struct HabitAppearancePicker: View {
    @Binding var selectedIconName: String
    @Binding var selectedColorHex: String

    @State private var isEditorPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Apariencia")
                .font(AppFont.formSectionText)
                .foregroundStyle(AppColor.mutedText)
                .textCase(.uppercase)

            Button {
                isEditorPresented = true
            } label: {
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

                        Text("Personalizar apariencia")
                            .font(AppFont.formSectionText2)
                            .foregroundStyle(AppColor.subtleText)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("Cambiar")
                            .font(AppFont.formSectionText2)
                            .fontWeight(.semibold)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(HabitAppearance.color(for: selectedColorHex))
                }
            }
            .buttonStyle(.plain)
            .padding(12)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .sheet(isPresented: $isEditorPresented) {
                HabitAppearanceEditor(
                    selectedIconName: $selectedIconName,
                    selectedColorHex: $selectedColorHex
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
