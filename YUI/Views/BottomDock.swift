//
//  BottomDock.swift
//  YUI
//
//  底部悬浮控件（一条导航栏）：左设置圆钮、中间战争模式胶囊、右搜索圆钮。
//
//  尺寸与间距依据 Apple HIG：
//  - 触控目标不小于 44×44pt，圆钮玻璃外轮廓与胶囊玻璃外轮廓都用同一个高度；
//  - 三控件统一 8pt 间距，胶囊宽度按容器显式算出，吃掉两侧剩余宽度。
//
//  玻璃一律用 .glassEffect 直接画在「外轮廓 = 目标尺寸」的视图上，
//  不再用 .buttonStyle(.glass)（它的玻璃会比 frame 内缩，导致胶囊与圆钮高度对不上）。
//

import SwiftUI

struct BottomDock: View {

    let model: HomeModel
    let containerSize: CGSize
    var safeArea: EdgeInsets = EdgeInsets()

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 控件之间与控件内部的统一间距（8pt，系统级常用值，HIG 未给硬性数字）。
    private let controlSpacing: CGFloat = 8

    // MARK: - 尺寸策略

    /// 玻璃外轮廓高度：窄屏 44pt（HIG 最小触控目标），常规 46pt。圆钮与胶囊共用。
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

    // MARK: - 主体

    var body: some View {
        let corner = Theme.screenCornerRadius(for: containerSize)
        // 圆角对齐只是近似：用圆角近似值减控件半径得到圆心内边距，并夹紧到合理范围。
        let alignmentInset = corner - glassHeight / 2
        let sideInset = max(8, min(alignmentInset, 30))
        let bottomInset = safeArea.bottom > 0 ? max(6, min(alignmentInset, 30)) : 14

        // 整条栏 = 左右圆钮 + 两个 8pt 间距 + 胶囊，胶囊吃掉剩余全部宽度。
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

    // MARK: - 圆形按钮（玻璃外轮廓 = 44/46pt 圆）

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

    // MARK: - 战争模式胶囊（玻璃外轮廓高度与圆钮严格一致）

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
