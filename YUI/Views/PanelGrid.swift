import SwiftUI

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

struct PanelTile: View {

    let item: PanelItem
    let model: HomeModel
    let isEditing: Bool
    var shakePhase: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    private var editableCard: some View {
        ZStack(alignment: .topTrailing) {
            cardContent(showsEditRow: true)
            hideButton
                .padding(4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.title)面板，编辑中")
    }

    private func cardContent(showsEditRow: Bool) -> some View {
        GlassCard(style: .liquid) {
            VStack(alignment: .leading, spacing: showsEditRow ? 8 : 0) {
                VStack(alignment: .leading, spacing: 4) {

                    HStack(spacing: 8) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 17, weight: .medium))
                            .frame(width: 22, height: 22)
                            .accessibilityHidden(true)

                        Text(item.title)
                            .font(Theme.rounded(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(wrapsText ? nil : 1)

                        Spacer(minLength: 0)
                    }

                    Text(item.value)
                        .font(Theme.rounded(.headline, weight: .bold))
                        .lineLimit(wrapsText ? nil : 1)
                        .minimumScaleFactor(wrapsText ? 1 : 0.8)
                    Text(item.detail)
                        .font(Theme.rounded(.caption2))
                        .foregroundStyle(.secondary)
                        .lineLimit(wrapsText ? nil : 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

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

    private var hideButton: some View {
        editButton("eye.slash", label: "隐藏\(item.title)") {
            model.hide(item)
        }
    }

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
