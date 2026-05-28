//
//  OnboardingHabitsScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingHabitsScreen: View {
    @Binding var habitDrafts: [OnboardingHabitDraft]

    let onContinue: () -> Void

    @State private var showingAddSheet = false

    private var canAddMore: Bool { habitDrafts.count < 3 }
    private var isContinueDisabled: Bool { habitDrafts.isEmpty }
    private var addButtonTitle: String {
        habitDrafts.isEmpty ? "Agregar primer hábito" : "Agregar otro hábito"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("Agrega uno o varios hábitos pequeños. Estos serán las acciones que sostienen tu meta cada semana.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)

            ScrollView {
                VStack(spacing: AppSpacing.s) {
                    ForEach($habitDrafts) { $draft in
                        OnboardingHabitDraftRow(draft: $draft) {
                            habitDrafts.removeAll { $0.id == draft.id }
                        }
                    }

                    if canAddMore {
                        addButton
                    }
                }
                .padding(.horizontal, AppSpacing.l)
                .padding(.bottom, AppSpacing.s)
            }
            .scrollIndicators(.hidden)

            WHButton(
                title: "Continuar",
                variant: .primary,
                isDisabled: isContinueDisabled,
                action: onContinue
            )
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxl)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddHabitSheet(
                templates: StarterHabitTemplate.all,
                onSelectTemplate: { template in
                    habitDrafts.append(.from(template))
                },
                onCustom: {
                    habitDrafts.append(OnboardingHabitDraft(title: ""))
                }
            )
        }
    }

    private var addButton: some View {
        Button(action: { showingAddSheet = true }) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.accent)
                Text(addButtonTitle)
                    .font(AppFont.bodyEmphasis)
                    .foregroundStyle(AppColor.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(AppColor.accentMuted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .stroke(AppColor.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Agrega hábitos")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("que sostienen tu meta")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }
}

// MARK: - Sheet para agregar hábito

private struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss

    let templates: [StarterHabitTemplate]
    let onSelectTemplate: (StarterHabitTemplate) -> Void
    let onCustom: () -> Void

    var body: some View {
        AppBackground {
            VStack(spacing: 0) {
                HStack {
                    Text("Elegir hábito")
                        .font(AppFont.headline)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColor.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AppColor.bgSunken))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.m)

                ScrollView {
                    VStack(spacing: AppSpacing.s) {
                        ForEach(templates) { template in
                            Button(action: {
                                onSelectTemplate(template)
                                dismiss()
                            }) {
                                StarterHabitRow(
                                    template: template,
                                    isSelected: false,
                                    onTap: {}
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()
                            .padding(.vertical, AppSpacing.xs)

                        Button(action: {
                            onCustom()
                            dismiss()
                        }) {
                            HStack(spacing: AppSpacing.m) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                        .fill(AppColor.bgSunken)
                                    Image(systemName: "pencil")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                .frame(width: 48, height: 48)

                                Text("Escribir uno propio")
                                    .font(AppFont.bodyEmphasis)
                                    .foregroundStyle(AppColor.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppColor.textTertiary)
                            }
                            .padding(.horizontal, AppSpacing.l)
                            .frame(height: 74)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                    .fill(AppColor.bgElevated)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                    .stroke(AppColor.divider, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppSpacing.l)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

#Preview {
    AppBackground {
        OnboardingHabitsScreen(
            habitDrafts: .constant([]),
            onContinue: {}
        )
    }
}
