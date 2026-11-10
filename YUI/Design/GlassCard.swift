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
