//
//  DiffuseBackground.swift
//  YUI
//
//  全屏柔和弥散渐变：浅色为冷蓝淡紫（参考图 1），深色为深蓝紫到酒红（参考图 2）。
//  使用公开的 MeshGradient 得到无接缝的弥散效果，不使用私有 API。
//

import SwiftUI

struct DiffuseBackground: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// 3 × 3 网格的锚点，轻微偏移让色块过渡更自然。
    private let points: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.52, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 0.48), SIMD2<Float>(0.46, 0.55), SIMD2<Float>(1.0, 0.5),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.55, 1.0), SIMD2<Float>(1.0, 1.0)
    ]

    /// 浅色：冷蓝 → 淡紫；深色：深蓝紫 → 酒红。
    private var colors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: 0x241B33), Color(hex: 0x2A1F3A), Color(hex: 0x2C1C34),
                Color(hex: 0x30223F), Color(hex: 0x3A2140), Color(hex: 0x4A2340),
                Color(hex: 0x3C1F34), Color(hex: 0x55263C), Color(hex: 0x6B2A3C)
            ]
        }
        return [
            Color(hex: 0xE7EDFB), Color(hex: 0xE3E9FA), Color(hex: 0xEDE6FA),
            Color(hex: 0xE6ECFB), Color(hex: 0xF4F6FD), Color(hex: 0xEBE4F8),
            Color(hex: 0xE9EEFC), Color(hex: 0xF0EFFC), Color(hex: 0xE5E2F5)
        ]
    }

    var body: some View {
        ZStack {
            if reduceTransparency {
                // 降低透明度开启时使用同色系的稳定底色，避免依赖半透明叠加。
                (colorScheme == .dark ? Color(hex: 0x2A1F3A) : Color(hex: 0xEDEFFA))
            } else {
                MeshGradient(width: 3, height: 3, points: points, colors: colors)
            }

            // 一层极淡的高光，让大面积渐变有空气感。
            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.10 : 0.35),
                    Color.white.opacity(0.0)
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 420
            )
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("浅色") {
    DiffuseBackground()
        .preferredColorScheme(.light)
}

#Preview("深色") {
    DiffuseBackground()
        .preferredColorScheme(.dark)
}
