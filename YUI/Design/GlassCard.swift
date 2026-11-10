//
//  GlassCard.swift
//  YUI
//
//  卡片容器，提供两种材质：
//  - .material：系统普通半透明 Material（键盘预览卡、示例说明卡）；
//  - .liquid：Liquid Glass 外观（首页面板）。只使用玻璃材质本身，不调用
//    `.interactive()`，所以按下没有液态回弹/放大，只是外观是玻璃。
//

import SwiftUI

enum GlassCardStyle {
    case material
    case liquid
}

struct GlassCard<Content: View>: View {

    var style: GlassCardStyle = .material
    var cornerRadius: CGFloat = Theme.cardCornerRadius
    @ViewBuilder var content: Content

    @Environment(\.colorScheme) private var colorScheme

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    var body: some View {
        switch style {
        case .material:
            content
                .background(.regularMaterial, in: shape)
                .overlay {
                    shape.strokeBorder(
                        .white.opacity(colorScheme == .dark ? 0.10 : 0.35),
                        lineWidth: 0.8
                    )
                }
        case .liquid:
            content
                .glassEffect(.regular, in: shape)
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
