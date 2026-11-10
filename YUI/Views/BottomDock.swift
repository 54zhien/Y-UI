//
//  BottomDock.swift
//  YUI
//
//  底部悬浮控件：左设置圆形按钮、中间战争模式胶囊、右搜索圆形按钮。
//  圆形控件的圆心尽量对齐屏幕底部圆角圆心：内边距取「圆角近似值 − 控件半径」，
//  再按安全区域与窄屏做夹紧，保证三控件不溢出、不压安全区。
//  玻璃效果使用系统 Liquid Glass API（buttonStyle(.glass) / glassEffect）。
//

import SwiftUI

struct BottomDock: View {

    let model: HomeModel
    let containerSize: CGSize
    var safeArea: EdgeInsets = EdgeInsets()

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - 尺寸策略

    /// 窄屏收小控件，给三控件留出余量。
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

    private var controlHeight: CGFloat {
        isNarrow ? 50 : 56
    }

    // MARK: - 主体

    var body: some View {
        let corner = Theme.screenCornerRadius(for: containerSize)
        // 圆角对齐只是近似：用圆角近似值减控件半径得到圆心内边距，并夹紧到合理范围。
        let alignmentInset = corner - controlHeight / 2
        let sideInset = max(8, min(alignmentInset, 30))
        let bottomInset = safeArea.bottom > 0 ? max(6, min(alignmentInset, 30)) : 14

        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 8) {
                circleButton(symbol: "gearshape", label: "设置") {
                    model.activeSheet = .settings
                }
                .layoutPriority(1)

                Spacer(minLength: 6)

                warModeCapsule
                    .layoutPriority(2)

                Spacer(minLength: 6)

                circleButton(symbol: "magnifyingglass", label: "搜索") {
                    model.activeSheet = .search
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, sideInset)
            .padding(.bottom, bottomInset)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 圆形按钮

    private func circleButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: controlHeight < 56 ? 18 : 20, weight: .medium))
                .frame(width: controlHeight, height: controlHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
        .accessibilityHint("打开演示占位页面")
    }

    // MARK: - 战争模式胶囊

    private var warModeCapsule: some View {
        Button {
            withAnimation(.snappy) {
                model.toggleWarMode()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: model.warModeEnabled ? "shield.lefthalf.filled" : "shield")
                    .font(.system(size: 15, weight: .semibold))

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
            .padding(.horizontal, isNarrow ? 14 : 18)
            .frame(height: controlHeight)
            .frame(minWidth: showsCapsuleTitle ? 128 : 88)
        }
        .buttonStyle(.plain)
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
