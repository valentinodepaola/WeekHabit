//
//  CustomTabBar.swift
//  WeekHabit
//
//  Created by Valentino De Paola Gallardo on 22/04/26.
//

import SwiftUI

struct CustomTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace

    @Binding var selectedTab: Int

    let tabs: [TabItems] = [.today, .week, .insights]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tabs.indices, id: \.self) { index in
                TabBarItem(
                    icon: tabs[index].icon,
                    text: tabs[index].description,
                    isSelected: selectedTab == index,
                    namespace: selectionNamespace
                ) {
                    selectTab(index)
                }
            }
        }
        .padding(7)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tabBarFill)
                .shadow(color: shadowColor, radius: 24, x: 0, y: 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .background {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [
                        backgroundColor.opacity(0),
                        backgroundColor.opacity(colorScheme == .dark ? 0.92 : 0.96),
                        backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 128)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private func selectTab(_ index: Int) {
        guard selectedTab != index else { return }

        withAnimation(selectionAnimation) {
            selectedTab = index
        }
    }

    private var selectionAnimation: Animation {
        if reduceMotion {
            return .easeOut(duration: 0.18)
        }

        return .spring(response: 0.34, dampingFraction: 0.74, blendDuration: 0.12)
    }

    private var tabBarFill: AnyShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(AppColor.surface.opacity(0.9))
            : AnyShapeStyle(.ultraThinMaterial)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.72)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.35)
            : AppColor.strongText.opacity(0.12)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? AppColor.bgDark : AppColor.bgLight
    }
}

enum TabItems: String {
    case today
    case week
    case insights

    var description: String {
        switch self {
        case .today:
            return "Hoy"
        case .week:
            return "Semana"
        case .insights:
            return "Insights"
        }
    }

    var icon: String {
        switch self {
        case .today:
            return "sun.max"
        case .week:
            return "calendar"
        case .insights:
            return "align.vertical.bottom.fill"
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppColor.bgLight.ignoresSafeArea()
        CustomTabBar(selectedTab: .constant(0))
    }
}
