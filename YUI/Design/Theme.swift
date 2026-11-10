//
//  Theme.swift
//  YUI
//
//  设计令牌（圆角、间距、配色辅助）。全部使用公开 API。
//

import SwiftUI

enum Theme {

    // MARK: - 圆角

    /// 两列面板卡片的圆角。
    static let cardCornerRadius: CGFloat = 26

    /// 顶部通栏卡片（战争模式 / 键盘预览）的圆角。
    static let panelCornerRadius: CGFloat = 28

    // MARK: - 屏幕圆角近似值

    /// 公开 API 不提供屏幕圆角半径，这里按屏幕宽度给出经验估计值，
    /// 用于把底栏圆形控件的圆心尽量对齐到屏幕底部圆角圆心。
    /// 仅供视觉对齐使用，不参与任何布局测量逻辑。
    static func screenCornerRadius(for size: CGSize) -> CGFloat {
        let width = size.width
        if width >= 700 { return 20 }   // iPad 类
        if width >= 420 { return 55 }   // 6.3" / 6.9" 类
        if width >= 390 { return 47 }   // 6.1" 类
        return 39                       // 小屏 / mini
    }

    // MARK: - 字体

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

extension Color {

    /// 便于在代码里写 0xRRGGBB 形式的颜色。
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
