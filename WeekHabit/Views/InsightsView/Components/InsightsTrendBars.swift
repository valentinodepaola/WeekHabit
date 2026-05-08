//
//  InsightsTrendBars.swift
//  WeekHabit
//

import SwiftUI

struct InsightsTrendBars: View {
    let values: [Double]

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color(for: index, value: value))
                    .frame(height: barHeight(for: value))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 72, alignment: .bottom)
    }

    private func barHeight(for value: Double) -> CGFloat {
        16 + CGFloat(max(0, min(value, 1))) * 52
    }

    private func color(for index: Int, value: Double) -> Color {
        guard value > 0 else { return AppColor.divider.opacity(0.6) }
        let isRecent = index >= max(values.count - 3, 0)
        return isRecent ? AppColor.accent : AppColor.accent.opacity(0.35)
    }
}

#Preview {
    InsightsTrendBars(values: [0.1, 0.3, 0.2, 0.55, 0.7, 0.4, 0.9])
        .padding()
        .background(AppColor.bgElevated)
}
