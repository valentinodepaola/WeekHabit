//
//  HabitAppearanceEditor.swift
//  WeekHabit
//

import SwiftUI

struct HabitAppearanceEditor: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedIconName: String
    @Binding var selectedColorHex: String

    @State private var mode: AppearanceEditorMode = .icons
    @State private var searchText = ""

    private var selectedColor: Color {
        HabitAppearance.color(for: selectedColorHex)
    }

    var body: some View {
        AppBackground {
            VStack(alignment: .leading, spacing: 16) {
                HabitAppearanceEditorHeader(
                    selectedIconName: selectedIconName,
                    selectedColor: selectedColor,
                    onClose: { dismiss() }
                )

                Picker("", selection: $mode) {
                    ForEach(AppearanceEditorMode.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .icons {
                    HabitIconBrowser(
                        selectedIconName: $selectedIconName,
                        selectedColor: selectedColor,
                        searchText: $searchText
                    )
                } else {
                    HabitColorGrid(selectedColorHex: $selectedColorHex)
                }
            }
            .padding(16)
        }
    }
}
