//
//  MilestoneCelebrationView.swift
//  WeekHabit
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MilestoneCelebrationView: View {
    let habit: Habit
    let milestone: HabitMilestone

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var didEnter = false
    @State private var didPlayHaptic = false
    @State private var shareItem: MilestoneShareItem?

    private var copy: MilestoneCopy {
        milestone.copy(for: habit.direction)
    }

    private var unitLabel: String {
        IdentityReinforcementCopy.milestoneUnitLabel(for: habit)
    }

    private var identityCopy: String {
        IdentityReinforcementCopy.milestoneIdentity(for: habit, milestone: milestone)
    }

    var body: some View {
        AppBackground {
            ZStack(alignment: .topTrailing) {
                ConfettiCanvas(
                    seed: confettiSeed,
                    habitColor: habit.habitColor,
                    reduceMotion: reduceMotion
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: AppSpacing.xl) {
                    Spacer(minLength: AppSpacing.xxl)

                    celebrationCard
                        .scaleEffect(didEnter ? 1 : 0.92)
                        .opacity(didEnter ? 1 : 0)
                        .animation(AppMotion.respectful(AppMotion.celebration, reduceMotion), value: didEnter)

                    Spacer(minLength: AppSpacing.l)

                    actions
                        .padding(.bottom, AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.l)

                closeButton
                    .padding(.top, AppSpacing.s)
                    .padding(.trailing, AppSpacing.l)
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            didEnter = true
            playMilestoneHapticOnce()
            scheduleShareItemRender()
        }
    }

    private var celebrationCard: some View {
        VStack(spacing: AppSpacing.l) {
            ZStack {
                Circle()
                    .fill(habit.habitColor.opacity(0.16))
                    .frame(width: 84, height: 84)

                Image(systemName: habit.iconName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(habit.habitColor)
            }

            VStack(spacing: AppSpacing.s) {
                Text("\(milestone.rawValue)")
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()

                Text(AppFormatters.uppercased(unitLabel))
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.textTertiary)
                    .tracking(0.8)

                Text(identityCopy)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AppSpacing.l)

                Text(habit.title)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.xxl)
        .background(AppColor.bgElevated.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.l, style: .continuous)
                .strokeBorder(habit.habitColor.opacity(0.22), lineWidth: 1)
        }
        .appElevation(.low)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(milestone.rawValue) \(unitLabel), \(identityCopy), \(habit.title)")
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.m) {
            if let shareItem {
                ShareLink(
                    item: shareItem,
                    preview: SharePreview(shareItem.caption, image: shareItem.previewImage)
                ) {
                    MilestonePrimaryButtonLabel(icon: "square.and.arrow.up", title: "Compartir")
                }
                .accessibilityLabel("Compartir hito")
            } else {
                MilestonePrimaryButtonLabel(icon: "square.and.arrow.up", title: "Compartir")
                    .opacity(0.55)
                    .accessibilityLabel("Preparando imagen para compartir")
            }

            Button {
                dismiss()
            } label: {
                Text("Cerrar")
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.s)
            }
            .accessibilityLabel("Cerrar celebración")
        }
        .padding(.horizontal, AppSpacing.l)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 36, height: 36)
                .background(AppColor.bgElevated.opacity(0.85), in: Circle())
        }
        .accessibilityLabel("Cerrar celebración")
    }

    private var confettiSeed: UInt64 {
        let milestoneSeed = UInt64(milestone.rawValue)
        let habitSeed = UInt64(bitPattern: Int64(habit.id.uuidString.hashValue))
        return milestoneSeed &* 1_000 &+ (habitSeed & 0xFFFF)
    }

    private func scheduleShareItemRender() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)

            let card = MilestoneShareCard(habit: habit, milestone: milestone)
                .environment(\.colorScheme, colorScheme)

            let renderer = ImageRenderer(content: card)
            renderer.proposedSize = ProposedViewSize(width: MilestoneShareCard.width, height: MilestoneShareCard.height)
            renderer.scale = 1

            guard let image = renderer.uiImage, let data = image.pngData() else { return }

            shareItem = MilestoneShareItem(
                imageData: data,
                cachedImage: image,
                caption: "\(copy.title) · \(identityCopy)"
            )
        }
    }

    private func playMilestoneHapticOnce() {
        guard !didPlayHaptic else { return }
        didPlayHaptic = true
        AppHaptics.play(.milestoneReached)
    }
}

private struct MilestonePrimaryButtonLabel: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: AppSpacing.s) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(AppFont.bodyEmphasis)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(AppColor.accent)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.capsule, style: .continuous))
    }
}

#Preview {
    MilestoneCelebrationView(
        habit: Habit(
            title: "Leer antes de dormir",
            iconName: "book.fill",
            colorHex: "#5c89a8",
            targetDaysPerWeek: 7,
            activeDaysOfWeek: Set(Weekday.ordered)
        ),
        milestone: .automaticity
    )
}
