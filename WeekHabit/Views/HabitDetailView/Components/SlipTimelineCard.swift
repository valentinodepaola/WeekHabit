//
//  SlipTimelineCard.swift
//  WeekHabit
//

import SwiftUI

struct SlipTimelineCard: View {
    let habit: Habit

    private var slips: [HabitEntry] {
        habit.slipEntries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("SLIPS")
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.6)

                Spacer()

                if !slips.isEmpty {
                    Text("\(slips.count)")
                        .font(AppFont.label)
                        .foregroundStyle(AppColor.warning)
                        .monospacedDigit()
                }
            }

            if slips.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppSpacing.s) {
                    ForEach(slips) { slip in
                        slipRow(slip)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColor.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .appElevation(.low)
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "leaf")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.success)
                .frame(width: 30, height: 30)
                .background(AppColor.success.opacity(0.12))
                .clipShape(Circle())

            Text("Cuando registres un slip, aparecerá aquí como contexto para entender patrones sin castigarte.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }

    private func slipRow(_ slip: HabitEntry) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.warning)
                .frame(width: 30, height: 30)
                .background(AppColor.warning.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(dateText(for: slip))
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)

                if let trigger = slip.slipTrigger {
                    Text(trigger.title)
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                } else {
                    Text("Slip registrado")
                        .font(AppFont.bodyEmphasis)
                        .foregroundStyle(AppColor.textPrimary)
                }

                if let context = trimmedContext(for: slip) {
                    Text(context)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.m)
        .background(AppColor.bgSunken.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous))
    }

    private func trimmedContext(for slip: HabitEntry) -> String? {
        let trimmed = slip.slipContext?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func dateText(for slip: HabitEntry) -> String {
        let moment = slip.completedAt ?? slip.date
        return AppFormatters.string(from: moment, format: "d MMM, HH:mm")
    }
}

#Preview {
    SlipTimelineCard(
        habit: Habit(
            title: "No fumar",
            iconName: "lungs.fill",
            colorHex: "#7fa869",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered),
            direction: .break
        )
    )
    .padding()
    .background(AppColor.bgCanvas)
}
