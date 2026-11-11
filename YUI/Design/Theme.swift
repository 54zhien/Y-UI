import SwiftUI

enum Theme {

    static let controlSize: CGFloat = 48

    static let controlIconSize: CGFloat = 20

    static let dockControlSize: CGFloat = 60

    static let dockIconSize: CGFloat = 26

    static let searchControlSize: CGFloat = 44

    static let historyChipHeight: CGFloat = 36

    static let minHitSize: CGFloat = 44

    static let fadeHeight: CGFloat = 96

    static let screenPadding: CGFloat = 18

    static let cardCornerRadius: CGFloat = 26

    static let panelCornerRadius: CGFloat = 28

    static func screenCornerRadius(for size: CGSize) -> CGFloat {
        let width = size.width
        if width >= 700 { return 20 }
        if width >= 420 { return 55 }
        if width >= 390 { return 47 }
        return 39
    }

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

extension Color {

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
