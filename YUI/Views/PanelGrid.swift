//
//  PanelGrid.swift
//  YUI
//
//  两列面板入口网格 + 管理模式（抖动、拖动/上移下移排序、隐藏、重新添加）。
//  结构约束：
//  - 非管理模式：整张卡片是一个 Button（点开占位说明页）；
//  - 管理模式：卡片本体不再是 Button，隐藏/上移/下移是各自独立的 Button，
//    不存在 Button 嵌套 Button，也不靠 disabled 外层按钮来屏蔽点击。
//  辅助功能字号下改为单列、文案允许换行；普通字号维持两列。
//

import SwiftUI

// MARK: - 网格

struct PanelGrid: View {

    let model: HomeModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var shakePhase: CGFloat = 0

    private var columns: [GridItem] {
        if dynamicTypeSize >= .accessibility1 {
            return [GridItem(.flexible(), spacing: 12, alignment: .top)]
        }
        return [
            GridItem(.flexible(), spacing: 12, alignment: .top),
            GridItem(.flexible(), spacing: 12, alignment: .top)
        ]
    }

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
                .dropDestination(for: String.self) { identifiers, _ -> Bool in
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 管理模式下给右上角隐藏按钮预留的宽度，避免遮挡标题与数值文字。
    private let controlReserve: CGFloat = 40

    private var wrapsText: Bool {
        dynamicTypeSize >= .accessibility1
    }

    var body: some View {
        Group {
            if isEditing {
                editableCard
            } else {
                Button {
                    model.activeSheet = .panel(item)
                } label: {
                    cardContent(showsEditRow: false)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.title)，\(item.value)，\(item.detail)")
                .accessibilityHint("打开演示占位说明")
            }
        }
        .modifier(ShakeEffect(animatableData: isEditing ? shakePhase : 0))
    }

    // MARK: 管理模式：卡片本体 + 独立控件

    private var editableCard: some View {
        ZStack(alignment: .topTrailing) {
            cardContent(showsEditRow: true)
            hideButton
                .padding(4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.title)面板，编辑中")
    }

    // MARK: 卡片内容（不含任何按钮逻辑）

    private func cardContent(showsEditRow: Bool) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: showsEditRow ? 8 : 0) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 22, height: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(Theme.rounded(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(wrapsText ? nil : 1)
                        Text(item.value)
                            .font(Theme.rounded(.headline, weight: .bold))
                            .lineLimit(wrapsText ? nil : 1)
                            .minimumScaleFactor(wrapsText ? 1 : 0.8)
                        Text(item.detail)
                            .font(Theme.rounded(.caption2))
                            .foregroundStyle(.secondary)
                            .lineLimit(wrapsText ? nil : 1)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(.trailing, showsEditRow ? controlReserve : 0)

                if showsEditRow {
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
                minHeight: showsEditRow ? nil : 92,
                alignment: .topLeading
            )
        }
    }

    // MARK: 编辑控件（独立按钮）

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
