//
//  HabitIconBrowser.swift
//  WeekHabit
//

import SwiftUI

struct HabitIconBrowser: View {
    @Binding var selectedIconName: String
    let selectedColor: Color
    @Binding var searchText: String

    private let columns = [
        GridItem(.adaptive(minimum: 48), spacing: 10)
    ]

    private var filteredIconGroups: [HabitIconGroup] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return HabitAppearance.iconGroups }

        return HabitAppearance.iconGroups.compactMap { group in
            if group.title.localizedCaseInsensitiveContains(query) {
                return group
            }

            let icons = group.iconNames.filter { $0.localizedCaseInsensitiveContains(query) }
            guard !icons.isEmpty else { return nil }

            return HabitIconGroup(id: group.id, title: group.title, iconNames: icons)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HabitIconSearchField(searchText: $searchText)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(filteredIconGroups) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.title)
                                .font(AppFont.formSectionText)
                                .foregroundStyle(AppColor.mutedText)
                                .textCase(.uppercase)

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(group.iconNames, id: \.self) { iconName in
                                    HabitIconOptionButton(
                                        iconName: iconName,
                                        isSelected: selectedIconName == iconName,
                                        selectedColor: selectedColor
                                    ) {
                                        selectedIconName = iconName
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 18)
            }
        }
    }
}
