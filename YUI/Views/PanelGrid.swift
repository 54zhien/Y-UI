import SwiftUI

struct PanelGrid: View {

    let model: HomeModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
            ForEach(Array(model.filteredPanels.enumerated()), id: \.element.id) { index, item in
                PanelTile(
                    item: item,
                    model: model,
                    isEditing: model.isEditing,
                    swayIndex: index
                )
                .modifier(
                    EditOnlyReorder(enabled: model.isEditing, payload: item.id) { identifiers in
                        handleDrop(identifiers, onto: item)
                    }
                )
            }
        }
        .animation(.snappy, value: model.panels)
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
    let swayIndex: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swayForward = false

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
        .rotationEffect(.degrees(swayDegrees))
        .animation(swayAnimation, value: swayForward)
        .onChange(of: isEditing) { _, editing in
            if editing, !reduceMotion {
                swayForward.toggle()
            } else {
                swayForward = false
            }
        }
        .onAppear {
            if isEditing, !reduceMotion {
                swayForward = swayIndex % 2 == 0
            }
        }
    }

    private var swayDegrees: Double {
        guard isEditing else { return 0 }
        return swayForward ? swayAmplitude : -swayAmplitude
    }

    private var swayAmplitude: Double {
        0.42 + Double(swayIndex % 3) * 0.12
    }

    private var swayDuration: Double {
        0.92 + Double(swayIndex % 4) * 0.21
    }

    private var swayAnimation: Animation? {
        guard isEditing, !reduceMotion else { return nil }
        return .easeInOut(duration: swayDuration)
            .repeatForever(autoreverses: true)
            .delay(Double(swayIndex % 5) * 0.08)
    }

    private var editableCard: some View {
        ZStack(alignment: .topTrailing) {
            cardContent(showsEditRow: true)
            hideButton
                .padding(4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text("上移")) {
            if model.canMoveUp(item) {
                withAnimation(.snappy) { model.moveUp(item) }
            }
        }
        .accessibilityAction(named: Text("下移")) {
            if model.canMoveDown(item) {
                withAnimation(.snappy) { model.moveDown(item) }
            }
        }
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
                .background(Circle().fill(.regularMaterial))
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
                }
        }
        .buttonStyle(.plain)
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

#Preview("网格") {
    ScrollView {
        PanelGrid(model: HomeModel()).padding()
    }
}
