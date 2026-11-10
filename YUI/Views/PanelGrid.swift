//
//  PanelGrid.swift
//  YUI
//
//  两列面板入口网格 + 管理模式（抖动、拖动/上移下移排序、隐藏、重新添加）。
//  拖动排序仅在管理模式下启用；数据只在内存里，退出应用即复原。
//

import SwiftUI

// MARK: - 网格

struct PanelGrid: View {

    let model: HomeModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shakePhase: CGFloat = 0

    private let columns = [
        GridItem(.flexible(), spacing: 12, alignment: .top),
        GridItem(.flexible(), spacing: 12, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(model.panels) { item in
                PanelTile(
                    item: item,
                    model: model,
                    isEditing: model.isEditing,
                    shakePhase: shakePhase
                )
                .modifier(
                    EditOnlyReorder(enabled: model.isEditing, payload: item.id) { identifiers in
                        handleDrop(identifiers, onto: item)
                    }
                )
            }
        }
        .animation(.snappy, value: model.panels)
        .onChange(of: model.isEditing) { _, editing in
            applyShake(editing)
        }
        .onChange(of: reduceMotion) { _, _ in
            applyShake(model.isEditing)
        }
    }

    private func handleDrop(_ identifiers: [String], onto target: PanelItem) -> Bool {
        guard
            let identifier = identifiers.first,
            let source = model.panels.firstIndex(where: { $0.id == identifier }),
            let destination = model.panels.firstIndex(where: { $0.id == target.id }),
            source != destination
        else {
            return false
        }
        withAnimation(.snappy) {
            model.move(from: source, to: destination)
        }
        return true
    }

    /// 开启「减少动态效果」时保持静止，不抖动。
    private func applyShake(_ editing: Bool) {
        guard editing, !reduceMotion else {
            withAnimation(.linear(duration: 0.12)) {
                shakePhase = 0
            }
            return
        }
        shakePhase = 0
        withAnimation(.linear(duration: 0.3).repeatForever(autoreverses: false)) {
            shakePhase = 1
        }
    }
}

// MARK: - 仅在管理模式下允许拖动与放置

/// 非管理模式下完全不挂拖动与放置，避免误触和与滚动/点击手势抢占。
struct EditOnlyReorder: ViewModifier {

    let enabled: Bool
    let payload: String
    let onDrop: ([String]) -> Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .draggable(payload)
                .dropDestination(for: String.self) { identifiers, _ in
                    onDrop(identifiers)
                }
        } else {
            content
        }
    }
}

// MARK: - 单个面板

struct PanelTile: View {

    let item: PanelItem
    let model: HomeModel
    let isEditing: Bool
    var shakePhase: CGFloat

    /// 管理模式下给右上角隐藏按钮预留的宽度，避免遮挡标题与数值文字。
    private let controlReserve: CGFloat = 40

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                if !isEditing {
                    model.activeSheet = .panel(item)
                }
            } label: {
                card
            }
            .buttonStyle(.plain)
            .disabled(isEditing)
            .accessibilityLabel("\(item.title)，\(item.value)，\(item.detail)")
            .accessibilityHint(isEditing ? "编辑模式中，可用上移、下移或隐藏操作" : "打开演示占位说明")

            if isEditing {
                hideButton
                    .padding(4)
            }
        }
        .modifier(ShakeEffect(animatableData: isEditing ? shakePhase : 0))
    }

    // MARK: 卡片

    private var card: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: isEditing ? 8 : 0) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 22, height: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(Theme.rounded(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(item.value)
                            .font(Theme.rounded(.headline, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(item.detail)
                            .font(Theme.rounded(.caption2))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.trailing, isEditing ? controlReserve : 0)

                if isEditing {
                    HStack(spacing: 4) {
                        Spacer(minLength: 0)
                        editButton("chevron.up", label: "上移\(item.title)", enabled: model.canMoveUp(item)) {
                            model.moveUp(item)
                        }
                        editButton("chevron.down", label: "下移\(item.title)", enabled: model.canMoveDown(item)) {
                            model.moveDown(item)
                        }
                    }
                }
            }
            .padding(14)
            .frame(
                maxWidth: .infinity,
                minHeight: isEditing ? nil : 92,
                alignment: .topLeading
            )
        }
    }

    // MARK: 编辑控件

    private var hideButton: some View {
        editButton("eye.slash", label: "隐藏\(item.title)") {
            model.hide(item)
        }
    }

    /// 视觉 30pt 的玻璃圆钮，命中区域扩到 44pt。
    private func editButton(
        _ symbol: String,
        label: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.snappy) {
                action()
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

// MARK: - 已隐藏面板（重新添加）

struct HiddenPanelsBar: View {

    let model: HomeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("已隐藏")

            if model.hiddenPanels.isEmpty {
                Text("没有隐藏的面板")
                    .font(Theme.rounded(.footnote))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(model.hiddenPanels) { item in
                            Button {
                                withAnimation(.snappy) {
                                    model.restore(item)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(item.title)
                                        .font(Theme.rounded(.footnote, weight: .medium))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.capsule)
                            .accessibilityLabel("重新添加\(item.title)")
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

// MARK: - 示例说明

struct DemoNoteCard: View {

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("示例说明")
                    .font(Theme.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("本页是静态界面演示：键盘预览、面板数据与统计数字都是占位内容，不接入真实键盘、网络或业务。编辑模式下的排序、隐藏与重新添加只改内存状态，退出应用即复原。")
                    .font(Theme.rounded(.footnote))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 抖动效果

/// 管理模式下的轻微横向抖动；相位为 0 时完全静止。
struct ShakeEffect: GeometryEffect {

    var travel: CGFloat = 1.8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let angle = Double(animatableData) * Double.pi * 2 * Double(shakesPerUnit)
        let offset = travel * CGFloat(sin(angle))
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

#Preview("网格") {
    ScrollView {
        PanelGrid(model: HomeModel()).padding()
    }
}
