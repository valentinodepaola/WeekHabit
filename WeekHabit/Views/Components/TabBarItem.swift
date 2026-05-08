//
//  TabBarItem.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct TabBarItem: View {
    var icon: String
    var text: String
    var isSelected: Bool
    var namespace: Namespace.ID
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColor.strongText)
                        .matchedGeometryEffect(id: "tab-selection", in: namespace)
                }

                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 20 : 19, weight: isSelected ? .semibold : .regular))
                        .symbolEffect(.bounce, value: isSelected)

                    Text(text)
                        .font(.system(size: 10.5, weight: isSelected ? .bold : .semibold, design: .default))
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
                .foregroundStyle(isSelected ? AppColor.surface : AppColor.mutedText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, minHeight: 58)
        }
        .buttonStyle(TabBarPressStyle())
        .accessibilityLabel(text)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TabBarPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

#Preview {
    TabBarItemPreview()
}

private struct TabBarItemPreview: View {
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 6) {
            TabBarItem(
                icon: "calendar",
                text: "Semana",
                isSelected: true,
                namespace: namespace
            ) { }

            TabBarItem(
                icon: "align.vertical.bottom.fill",
                text: "Insights",
                isSelected: false,
                namespace: namespace
            ) { }
        }
        .padding()
        .background(AppColor.bgLight)
    }
}
