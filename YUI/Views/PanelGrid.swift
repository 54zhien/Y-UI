import SwiftUI
import UniformTypeIdentifiers

struct PanelGrid: View {

    let model: HomeModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var dragging: PanelItem?

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
            ForEach(model.filteredPanels) { item in
                PanelTile(item: item, model: model, isEditing: model.isEditing)
                    .modifier(EditOnlyDrag(item: item, enabled: model.isEditing, dragging: $dragging))
                    .onDrop(
                        of: [UTType.text],
                        delegate: PanelDropDelegate(model: model, item: item, dragging: $dragging)
                    )
            }
        }
        .animation(.snappy, value: model.panels)
    }
}

struct EditOnlyDrag: ViewModifier {

    let item: PanelItem
    let enabled: Bool
    @Binding var dragging: PanelItem?

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            draggable(content)
        } else {
            content
        }
    }

    private func draggable(_ content: Content) -> some View {
        content
            .opacity(dragging?.id == item.id ? 0 : 1)
            .onDrag {
                dragging = item
                return NSItemProvider(object: item.id as NSString)
            } preview: {
                VStack(alignment: .leading, spacing: 6) {
                    Label(item.title, systemImage: item.symbol)
                        .font(Theme.rounded(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(item.value)
                        .font(Theme.rounded(.headline, weight: .semibold))
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
    }
}

struct PanelDropDelegate: DropDelegate {

    let model: HomeModel
    let item: PanelItem
    @Binding var dragging: PanelItem?

    func dropEntered(info: DropInfo) {
        guard let dragging,
              dragging.id != item.id,
              let from = model.panels.firstIndex(where: { $0.id == dragging.id }),
              let to = model.panels.firstIndex(where: { $0.id == item.id })
        else { return }

        withAnimation(.snappy) {
            model.move(from: from, to: to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

struct PanelTile: View {

    let item: PanelItem
    let model: HomeModel
    let isEditing: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let controlReserve: CGFloat = 44

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
    }

    private var editableCard: some View {
        ZStack(alignment: .topTrailing) {
            cardContent(showsEditRow: true)
            hideButton
                .padding(6)
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
        .accessibilityAction(named: Text("隐藏面板")) {
            withAnimation(.snappy) { model.hide(item) }
        }
    }

    private var hideButton: some View {
        Button {
            withAnimation(.snappy) { model.hide(item) }
        } label: {
            Image(systemName: "minus")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
                }
        }
        .buttonStyle(.plain)
        .frame(width: Theme.minHitSize, height: Theme.minHitSize)
        .contentShape(Circle())
        .accessibilityLabel("隐藏\(item.title)")
    }

    private func cardContent(showsEditRow: Bool) -> some View {
        GlassCard(style: .liquid, cornerRadius: Theme.panelCornerRadius) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 22, height: 22)
                    Text(item.title)
                        .font(Theme.rounded(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(wrapsText ? 2 : 1)
                    Spacer(minLength: 0)
                }
                .padding(.trailing, showsEditRow ? controlReserve : 0)

                Text(item.value)
                    .font(Theme.rounded(.headline, weight: .semibold))
                    .lineLimit(wrapsText ? 3 : 1)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item.detail)
                    .font(Theme.rounded(.caption2))
                    .foregroundStyle(.secondary)
                    .lineLimit(wrapsText ? 3 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HiddenPanelsBar: View {

    let model: HomeModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("已隐藏")
                .font(Theme.rounded(.footnote, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(model.hiddenPanels.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .medium))
                            .frame(width: 22)
                        Text(item.title)
                            .font(Theme.rounded(.subheadline))
                        Spacer(minLength: 8)
                        Button {
                            withAnimation(.snappy) { model.restore(item) }
                        } label: {
                            Text("恢复")
                                .font(Theme.rounded(.caption, weight: .semibold))
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .accessibilityLabel("重新添加\(item.title)")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if index < model.hiddenPanels.count - 1 {
                        Divider().padding(.leading, 46)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.24))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
        }
    }
}
