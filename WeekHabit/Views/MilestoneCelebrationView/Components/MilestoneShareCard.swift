//
//  MilestoneShareCard.swift
//  WeekHabit
//

import CoreTransferable
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct MilestoneShareCard: View {
    static let width: CGFloat = 1080
    static let height: CGFloat = 1350

    let habit: Habit
    let milestone: HabitMilestone

    private var copy: MilestoneCopy {
        milestone.copy(for: habit.direction)
    }

    private var identityCopy: String {
        IdentityReinforcementCopy.milestoneIdentity(for: habit, milestone: milestone)
    }

    var body: some View {
        AppBackground {
            VStack(spacing: 56) {
                Spacer(minLength: 78)

                ZStack {
                    Circle()
                        .fill(habit.habitColor.opacity(0.16))
                        .frame(width: 190, height: 190)

                    Image(systemName: habit.iconName)
                        .font(.system(size: 82, weight: .semibold))
                        .foregroundStyle(habit.habitColor)
                }

                VStack(spacing: 22) {
                    Text("\(milestone.rawValue)")
                        .font(.system(size: 210, weight: .regular, design: .serif))
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()
                        .minimumScaleFactor(0.72)

                    Text(AppFormatters.uppercased(copy.title))
                        .font(.system(size: 34, weight: .medium, design: .default))
                        .foregroundStyle(AppColor.textTertiary)
                        .tracking(2.2)

                    Text(identityCopy)
                        .font(.system(size: 58, weight: .medium, design: .serif))
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 92)
                }

                Text(habit.title)
                    .font(.system(size: 38, weight: .regular, design: .rounded))
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 112)

                Spacer()

                Text("WeekHabit")
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundStyle(AppColor.textTertiary.opacity(0.72))
                    .padding(.bottom, 78)
            }
            .frame(width: Self.width, height: Self.height)
        }
        .frame(width: Self.width, height: Self.height)
    }
}

struct MilestoneShareItem: Transferable {
    let imageData: Data
    let cachedImage: UIImage
    let caption: String

    nonisolated static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            item.imageData
        }
    }

    var previewImage: Image {
        Image(uiImage: cachedImage)
    }
}
