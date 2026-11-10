//
//  GlassCard.swift
//  YUI
//
//  系统普通半透明 Material 玻璃卡片。按需求刻意使用 Material，
//  不使用 Liquid Glass，以便和底部悬浮的玻璃控件区分层级。
//

import SwiftUI

struct GlassCard<Content: View>: View {

    var cornerRadius: CGFloat = Theme.cardCornerRadius
    @ViewBuilder var content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        .white.opacity(colorScheme == .dark ? 0.10 : 0.35),
                        lineWidth: 0.8
                    )
            }
    }
}

/// 小节标题（例如「当前键盘」「你的设置」）。
struct SectionHeader: View {

    private let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(Theme.rounded(.footnote, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .accessibilityAddTraits(.isHeader)
    }
}
