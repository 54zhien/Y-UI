import SwiftUI

struct DiffuseBackground: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var basePoints: [SIMD2<Float>] {
        [
            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.52, 0.0), SIMD2<Float>(1.0, 0.0),
            SIMD2<Float>(0.0, 0.48), SIMD2<Float>(0.46, 0.55), SIMD2<Float>(1.0, 0.5),
            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.55, 1.0), SIMD2<Float>(1.0, 1.0)
        ]
    }

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

    private func points(phase: Float) -> [SIMD2<Float>] {
        var result = basePoints
        let slow = sin(phase)
        let slowCos = cos(phase)
        let drift = sin(phase * 0.73)
        let counter = cos(phase * 0.61)

        result[1].x += 0.04 * Float(drift)
        result[3].y += 0.035 * Float(counter)
        result[4].x += 0.055 * Float(slow)
        result[4].y += 0.03 * Float(slowCos)
        result[5].y += 0.03 * Float(drift)
        result[7].x += 0.045 * Float(counter)
        return result
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10.0, paused: reduceMotion || reduceTransparency)) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let phase = Float(seconds.truncatingRemainder(dividingBy: 32) / 32 * Double.pi * 2)

            ZStack {
                if reduceTransparency {
                    (colorScheme == .dark ? Color(hex: 0x2A1F3A) : Color(hex: 0xEDEFFA))
                } else {
                    MeshGradient(width: 3, height: 3, points: points(phase: reduceMotion ? 0 : phase), colors: colors)
                }

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
