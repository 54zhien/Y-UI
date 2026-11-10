import SwiftUI

struct BottomDock: View {

    let model: HomeModel
    let containerSize: CGSize
    var safeArea: EdgeInsets = EdgeInsets()

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let controlSpacing: CGFloat = 8

    private var glassHeight: CGFloat {
        containerSize.width < 380 ? 44 : 46
    }

    private var isNarrow: Bool {
        containerSize.width < 380
    }

    private var usesAccessibilityText: Bool {
        dynamicTypeSize >= .accessibility1
    }

    private var showsCapsuleTitle: Bool {
        !isNarrow && !usesAccessibilityText
    }

    var body: some View {
        let corner = Theme.screenCornerRadius(for: containerSize)

        let alignmentInset = corner - glassHeight / 2
        let sideInset = max(8, min(alignmentInset, 30))
        let bottomInset = safeArea.bottom > 0 ? max(6, min(alignmentInset, 30)) : 14

        let capsuleWidth = max(
            0,
            containerSize.width - sideInset * 2 - glassHeight * 2 - controlSpacing * 2
        )

        HStack(spacing: controlSpacing) {
            circleButton(symbol: "gearshape", label: "设置") {
                model.activeSheet = .settings
            }

            warModeCapsule(width: capsuleWidth)

            circleButton(symbol: "magnifyingglass", label: "搜索") {
                model.activeSheet = .search
            }
        }
        .padding(.horizontal, sideInset)
        .padding(.bottom, bottomInset)
        .frame(maxWidth: .infinity)
    }

    private func circleButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .frame(width: glassHeight, height: glassHeight)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
        .accessibilityHint("打开演示占位页面")
    }

    private func warModeCapsule(width: CGFloat) -> some View {
        Button {
            withAnimation(.snappy) {
                model.toggleWarMode()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: model.warModeEnabled ? "shield.lefthalf.filled" : "shield")
                    .font(.system(size: 14, weight: .semibold))

                if showsCapsuleTitle {
                    Text("战争模式")
                        .font(Theme.rounded(.footnote, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text(model.warModeEnabled ? "开" : "关")
                    .font(Theme.rounded(.footnote, weight: .bold))
                    .foregroundStyle(model.warModeEnabled ? Color.green : Color.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: glassHeight)
        }
        .buttonStyle(.plain)
        .frame(width: width, height: glassHeight)
        .contentShape(.capsule)
        .glassEffect(warModeGlass, in: .capsule)
        .accessibilityLabel("战争模式")
        .accessibilityValue(model.warModeEnabled ? "开" : "关")
        .accessibilityHint("切换战争模式演示状态，仅模拟，不改变真实网络或特效")
    }

    private var warModeGlass: Glass {
        model.warModeEnabled
            ? .regular.tint(Color.orange.opacity(0.32)).interactive()
            : .regular.interactive()
    }
}

#Preview("常规") {
    ZStack {
        DiffuseBackground()
        VStack {
            Spacer()
            BottomDock(
                model: HomeModel(),
                containerSize: CGSize(width: 402, height: 874),
                safeArea: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
            )
        }
    }
}

#Preview("窄屏") {
    ZStack {
        DiffuseBackground()
        VStack {
            Spacer()
            BottomDock(
                model: HomeModel(),
                containerSize: CGSize(width: 375, height: 667),
                safeArea: EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
            )
        }
    }
}

#Preview("辅助功能字号") {
    ZStack {
        DiffuseBackground()
        VStack {
            Spacer()
            BottomDock(
                model: HomeModel(),
                containerSize: CGSize(width: 402, height: 874),
                safeArea: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
            )
        }
    }
    .dynamicTypeSize(.accessibility3)
}
