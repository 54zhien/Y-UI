//
//  BottomDock.swift
//  YUI
//
//  底部悬浮控件（相当于一条导航栏）：左设置圆钮、中间战争模式胶囊、右搜索圆钮。
//
//  尺寸与间距依据 Apple HIG：
//  - 触控目标不小于 44×44pt，因此圆形控件取 44–46pt，不再放大到 56pt；
//  - 三个控件按同一条导航栏排布，间距统一 8pt（HIG 未给硬数字，8pt 是系统级常用值），
//    中间胶囊撑满两侧剩余宽度，不再用大段 Spacer 把它们拉开。
//
//  圆形控件的圆心尽量对齐屏幕底部圆角圆心：内边距取「圆角近似值 − 控件半径」，
//  再按安全区域与窄屏夹紧。玻璃效果使用系统 Liquid Glass API。
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

    /// 窄屏用 44pt（HIG 最小触控目标），常规屏 46pt。
    private var controlHeight: CGFloat {
        containerSize.width < 380 ? 44 : 46
    }

    /// 窄屏收小左右内边距，给三控件留出余量。
    private var isNarrow: Bool {
        containerSize.width < 380
    }

    /// 辅助功能字号下隐藏标题文字，只保留图标与开关状态。
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
        let alignmentInset = corner - controlHeight / 2
        let sideInset = max(8, min(alignmentInset, 30))
        let bottomInset = safeArea.bottom > 0 ? max(6, min(alignmentInset, 30)) : 14

        // 胶囊宽度直接按容器算，不依赖 HStack 的弹性分配：
        // 整条栏 = 左右圆钮 + 两个 8pt 间距 + 胶囊，胶囊吃掉剩余全部宽度。
        let capsuleWidth = max(
            0,
            containerSize.width - sideInset * 2 - controlHeight * 2 - controlSpacing * 2
        )

        HStack(spacing: controlSpacing) {
            circleButton(symbol: "gearshape", label: "设置") {
                model.activeSheet = .settings
            }

            warModeCapsule
                .frame(width: capsuleWidth)

            circleButton(symbol: "magnifyingglass", label: "搜索") {
                model.activeSheet = .search
            }
        }
        .padding(.horizontal, sideInset)
        .padding(.bottom, bottomInset)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 圆形按钮（44–46pt 触控目标）

    private func circleButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .frame(width: controlHeight, height: controlHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
        .accessibilityHint("打开演示占位页面")
    }

    // MARK: - 战争模式胶囊（撑满两侧剩余宽度）

    private var warModeCapsule: some View {
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
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: controlHeight)
        }
        .buttonStyle(.plain)
        // 先把按钮撑满可用宽度，再把玻璃画在撑满后的 frame 上，
        // 否则玻璃只会包住内容本身，看起来仍是中间一小块。
        .frame(maxWidth: .infinity)
        .frame(height: controlHeight)
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
