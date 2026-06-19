//
//  UrgePeakHoursCard.swift
//  WeekHabit
//

import SwiftUI

struct UrgePeakHoursCard: View {
    let insight: UrgePeakHourInsight
    let buckets: [UrgeHourBucket]

    private var maxCount: Int {
        max(buckets.map(\.count).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            HStack(alignment: .top, spacing: AppSpacing.m) {
                Image(systemName: "waveform.path.ecg")
                    .font(AppFont.iconMedium)
                    .foregroundStyle(AppColor.warning)
                    .frame(width: 42, height: 42)
                    .background(AppColor.warning.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("PICO DE IMPULSO")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textTertiary)

                    Text(insight.window.displayText)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(insight.contextText)
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            hourlyBars
        }
        .insightCard()
    }

    private var hourlyBars: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack(alignment: .bottom, spacing: AppSpacing.xs) {
                ForEach(buckets) { bucket in
                    RoundedRectangle(cornerRadius: AppRadius.xs, style: .continuous)
                        .fill(color(for: bucket))
                        .frame(height: barHeight(for: bucket))
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(bucket.hour):00, \(bucket.count) impulsos")
                }
            }
            .frame(height: 76, alignment: .bottom)

            HStack {
                Text("0")
                Spacer()
                Text("6")
                Spacer()
                Text("12")
                Spacer()
                Text("18")
                Spacer()
                Text("24")
            }
            .font(AppFont.micro)
            .foregroundStyle(AppColor.textTertiary)
        }
    }

    private func barHeight(for bucket: UrgeHourBucket) -> CGFloat {
        8 + CGFloat(bucket.count) / CGFloat(maxCount) * 68
    }

    private func color(for bucket: UrgeHourBucket) -> Color {
        guard bucket.count > 0 else { return AppColor.divider.opacity(0.55) }
        return bucket.hour == insight.window.startHour ? AppColor.warning : AppColor.warning.opacity(0.34)
    }
}

#Preview {
    UrgePeakHoursCard(
        insight: UrgePeakHourInsight(
            window: HourWindow(startHour: 15, count: 4),
            totalCount: 8,
            habits: []
        ),
        buckets: (0..<24).map { UrgeHourBucket(hour: $0, count: $0 == 15 ? 4 : ($0 % 5 == 0 ? 1 : 0)) }
    )
    .padding()
    .background(AppColor.bgCanvas)
}
