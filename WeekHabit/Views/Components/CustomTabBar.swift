//
//  CustomTabBar.swift
//  WeekHabit
//

import SwiftUI

struct CustomTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNamespace

    @Binding var selectedTab: Int

    let tabs: [TabItems] = [.today, .week, .insights]

    var body: some View {
        HStack(spacing: AppSpacing.s) {
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
        .padding(AppSpacing.s)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .fill(tabBarFill)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                }
        }
        .appElevation(.medium)
        .padding(.horizontal, AppSpacing.l)
        .padding(.bottom, AppSpacing.xl)
        .background {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [
                        AppColor.bgCanvas.opacity(0),
                        AppColor.bgCanvas.opacity(colorScheme == .dark ? 0.92 : 0.96),
                        AppColor.bgCanvas
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 128)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
    }

    private func selectTab(_ index: Int) {
        guard selectedTab != index else { return }

        withAnimation(AppMotion.respectful(AppMotion.smooth, reduceMotion)) {
            selectedTab = index
        }
    }

    private var tabBarFill: AnyShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(AppColor.bgElevated.opacity(0.96))
            : AnyShapeStyle(.ultraThinMaterial)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? AppColor.accent.opacity(0.08)
            : AppColor.divider.opacity(0.6)
    }
}

enum TabItems: String {
    case today
    case week
    case insights

    var description: String {
        switch self {
        case .today: return "Hoy"
        case .week: return "Semana"
        case .insights: return "Insights"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .week: return "calendar"
        case .insights: return "align.vertical.bottom.fill"
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppColor.bgCanvas.ignoresSafeArea()
        CustomTabBar(selectedTab: .constant(0))
    }
}
