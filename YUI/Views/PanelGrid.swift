import SwiftUI

struct PanelGrid: View {

    let model: HomeModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var phase: DragPhase = .idle
    @State private var draggedID: String?
    @State private var draggedItem: PanelItem?
    @State private var startFrame: CGRect = .zero
    @State private var currentPoint: CGPoint = .zero
    @State private var frames: [String: CGRect] = [:]
    @State private var liftFrames: [String: CGRect] = [:]
    @State private var lastTargetID: String?
    @State private var settleTask: Task<Void, Never>?

    enum DragPhase: Equatable {
        case idle
        case pressing
        case lifted
        case dragging
        case settling
    }

    private let space = "panelGrid"

    private var columns: [GridItem] {
        if dynamicTypeSize >= .accessibility1 {
            return [GridItem(.flexible(), spacing: 12, alignment: .top)]
        }
        return [
            GridItem(.flexible(), spacing: 12, alignment: .top),
            GridItem(.flexible(), spacing: 12, alignment: .top)
        ]
    }

    private var isDraggingActive: Bool {
        phase == .dragging || phase == .lifted || phase == .settling
    }

    var body: some View {
        grid
            .coordinateSpace(name: space)
            .overlay(alignment: .topLeading) {
                if let item = draggedItem, isDraggingActive {
                    mirror(item)
                        .allowsHitTesting(false)
                }
            }
            .onPreferenceChange(PanelFrameKey.self) { value in
                frames = value
            }
            .onChange(of: model.isEditing) { _, editing in
                if !editing { cancelDrag() }
            }
            .onChange(of: model.hiddenPanels) { _, _ in
                cancelDrag()
            }
            .onDisappear { cancelDrag() }
            .animation(.snappy, value: model.panels)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(model.filteredPanels) { item in
                PanelTile(item: item, model: model, isEditing: model.isEditing)
                    .opacity(draggedID == item.id ? 0 : 1)
                    .background {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: PanelFrameKey.self,
                                value: [item.id: proxy.frame(in: .named(space))]
                            )
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: Theme.panelCornerRadius, style: .continuous))
                    .gesture(model.isEditing ? dragGesture(item) : nil)
            }
        }
    }

    private func dragGesture(_ item: PanelItem) -> some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(space)))
            .onChanged { value in
                switch value {
                case .first(true):
                    if phase == .idle {
                        phase = .pressing
                        beginLift(item)
                    }
                case .second(true, let drag):
                    guard let drag else { return }
                    if phase == .lifted {
                        phase = .dragging
                    }
                    currentPoint = drag.location
                    updateTarget(for: drag.location)
                default:
                    break
                }
            }
            .onEnded { _ in
                endDrag()
            }
    }

    private func beginLift(_ item: PanelItem) {
        settleTask?.cancel()
        draggedItem = item
        draggedID = item.id
        liftFrames = frames
        lastTargetID = nil
        startFrame = frames[item.id] ?? .zero
        currentPoint = CGPoint(x: startFrame.midX, y: startFrame.midY)
        withAnimation(.snappy(duration: 0.16)) {
            phase = .lifted
        }
        settleTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if phase == .lifted {
                    withAnimation(.snappy(duration: 0.12)) {
                        phase = .dragging
                    }
                }
            }
        }
    }

    private func updateTarget(for point: CGPoint) {
        guard let itemID = draggedID,
              let currentIndex = model.panels.firstIndex(where: { $0.id == itemID })
        else { return }

        let hit = liftFrames.first { key, rect in
            key != itemID && rect.contains(point)
        }?.key

        guard let hit,
              hit != lastTargetID,
              let targetIndex = model.panels.firstIndex(where: { $0.id == hit }),
              targetIndex != currentIndex
        else { return }

        lastTargetID = hit

        withAnimation(.snappy) {
            model.move(from: currentIndex, to: targetIndex)
        }
    }

    private func endDrag() {
        guard let itemID = draggedID else { return }
        let slot = frames[itemID] ?? startFrame

        if phase == .pressing || phase == .lifted {
            phase = .settling
            withAnimation(.snappy(duration: 0.2)) {
                draggedItem = nil
                draggedID = nil
                phase = .idle
            }
            return
        }

        phase = .settling
        withAnimation(.snappy(duration: 0.22)) {
            currentPoint = CGPoint(x: slot.midX, y: slot.midY)
        }

        settleTask?.cancel()
        settleTask = Task {
            try? await Task.sleep(for: .milliseconds(230))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.14)) {
                    draggedItem = nil
                }
                phase = .idle
                draggedID = nil
            }
        }
    }

    private func cancelDrag() {
        settleTask?.cancel()
        draggedItem = nil
        draggedID = nil
        liftFrames = [:]
        lastTargetID = nil
        phase = .idle
    }

    private func mirror(_ item: PanelItem) -> some View {
        PanelTile(item: item, model: model, isEditing: false)
            .frame(width: max(startFrame.width, 80), height: max(startFrame.height, 60))
            .scaleEffect(phase == .lifted ? 1.04 : 1)
            .shadow(color: .black.opacity(phase == .lifted ? 0.18 : 0.1), radius: phase == .lifted ? 12 : 6, y: 4)
            .offset(
                x: currentPoint.x - startFrame.width / 2,
                y: currentPoint.y - startFrame.height / 2
            )
    }
}

struct PanelFrameKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
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
                .highPriorityGesture(TapGesture())
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
                        .font(.system(size: Theme.controlIconSize, weight: .medium))
                        .frame(width: 24, height: 24)
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
                            .font(.system(size: Theme.controlIconSize, weight: .medium))
                            .frame(width: 24)
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
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.3))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
            }
        }
    }
}
