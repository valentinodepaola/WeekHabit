//
//  TabBarItem.swift
//  WeekHabit
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
                    RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                        .fill(AppColor.accentMuted)
                        .matchedGeometryEffect(id: "tab-selection", in: namespace)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                .stroke(AppColor.accent.opacity(0.18), lineWidth: 1)
                        }
                }

                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 21 : 20, weight: isSelected ? .semibold : .regular))
                        .symbolEffect(.bounce, value: isSelected)

                    Text(text)
                        .font(AppFont.micro)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
                .foregroundStyle(isSelected ? AppColor.accent : AppColor.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(TabBarPressStyle())
        .accessibilityLabel(text)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TabBarPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(AppMotion.respectful(AppMotion.snap, reduceMotion), value: configuration.isPressed)
    }
}

#Preview {
    TabBarItemPreview()
}

private struct TabBarItemPreview: View {
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: AppSpacing.s) {
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
        .background(AppColor.bgCanvas)
    }
}
