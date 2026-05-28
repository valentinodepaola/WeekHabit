//
//  OnboardingSizeScreen.swift
//  WeekHabit
//

import SwiftUI

struct OnboardingSizeScreen: View {
    @Binding var sizeText: String
    @FocusState private var isFocused: Bool

    let onContinue: () -> Void
    let onSkip: () -> Void

    private let suggestions = [
        "5 min al día",
        "2 veces por semana",
        "3 días por semana",
        "una vez por semana"
    ]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                headlineText

                Text("Los hábitos que duran empiezan más pequeños de lo que parece razonable.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xl)

            LazyVGrid(columns: columns, spacing: AppSpacing.s) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: { sizeText = suggestion }) {
                        Text(suggestion)
                            .font(AppFont.callout)
                            .foregroundStyle(sizeText == suggestion ? .white : AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, AppSpacing.m)
                            .padding(.vertical, AppSpacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                                    .fill(sizeText == suggestion ? AppColor.accent : AppColor.bgSunken)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.m)

            TextField(
                "O escribe tu versión mínima...",
                text: $sizeText,
                axis: .vertical
            )
            .font(AppFont.body)
            .foregroundStyle(AppColor.textPrimary)
            .lineLimit(2...4)
            .focused($isFocused)
            .padding(AppSpacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.m, style: .continuous)
                    .fill(AppColor.bgSunken)
            )
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            WHButton(title: "Continuar", variant: .primary, action: onContinue)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.s)

            Button("Omitir", action: onSkip)
                .font(AppFont.label)
                .foregroundStyle(AppColor.textTertiary)
                .padding(.bottom, AppSpacing.xxl)
        }
    }

    private var headlineText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Empezar")
                .font(AppFont.title)
                .foregroundStyle(AppColor.textPrimary)
            Text("lo más pequeño posible")
                .font(AppFont.title.italic())
                .foregroundStyle(AppColor.accent)
        }
    }
}

#Preview {
    AppBackground {
        OnboardingSizeScreen(sizeText: .constant(""), onContinue: {}, onSkip: {})
    }
}
