import SwiftUI

struct BottomDock: View {

    @Bindable var model: HomeModel
    var containerSize: CGSize
    var safeArea: EdgeInsets
    var warNamespace: Namespace.ID
    var searchHistory: SearchHistory
    var onOpenWarMode: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    @State private var didLongPress = false

    private let spacing: CGFloat = 8

    private var sideInset: CGFloat {
        let corner = Theme.screenCornerRadius(for: containerSize)
        let alignment = corner - Theme.controlSize / 2
        return max(10, min(alignment, 30))
    }

    private var bottomInset: CGFloat {
        safeArea.bottom > 0 ? max(8, min(sideInset, 28)) : 16
    }

    private var capsuleWidth: CGFloat {
        let available = containerSize.width - sideInset * 2 - Theme.controlSize * 2 - spacing * 2
        return min(max(available * 0.4, 100), 148)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            dockRow
                .offset(x: model.isSearchingHome ? -(containerSize.width + Theme.controlSize * 2) : 0)
                .allowsHitTesting(!model.isSearchingHome)
                .accessibilityHidden(model.isSearchingHome)
                .animation(.snappy(duration: 0.34), value: model.isSearchingHome)

            if model.isSearchingHome {
                LiquidSearchBar(
                    text: $model.homeQuery,
                    placeholder: "搜索面板",
                    history: searchHistory,
                    onExit: {
                        withAnimation(.snappy(duration: 0.34)) {
                            model.homeQuery = ""
                            model.isSearchingHome = false
                        }
                    }
                )
                .transition(.opacity)
                .padding(.bottom, bottomInset)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dockRow: some View {
        HStack(spacing: 0) {
            circle(symbol: "gearshape", label: "设置") {
                onOpenSettings()
            }
            .matchedTransitionSource(id: WarRoute.settingsSourceID, in: warNamespace)

            Spacer(minLength: spacing)

            warCapsule

            Spacer(minLength: spacing)

            circle(symbol: "magnifyingglass", label: "搜索") {
                withAnimation(.snappy(duration: 0.34)) {
                    model.homeQuery = ""
                    model.isSearchingHome = true
                }
            }
        }
        .padding(.horizontal, sideInset)
        .padding(.bottom, bottomInset)
        .frame(maxWidth: .infinity)
    }

    private func circle(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    private var warCapsule: some View {
        Button {
            if didLongPress {
                didLongPress = false
            } else {
                withAnimation(.snappy) {
                    model.toggleWarMode()
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: model.warModeEnabled ? "shield.lefthalf.filled" : "shield")
                    .font(.system(size: 20, weight: .medium))

                Text("战争模式")
                    .font(Theme.rounded(.footnote, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(model.warModeEnabled ? "开" : "关")
                    .font(Theme.rounded(.footnote, weight: .bold))
                    .foregroundStyle(model.warModeEnabled ? Color.green : Color.secondary)
                    .contentTransition(.opacity)
            }
            .padding(.horizontal, 14)
            .frame(width: capsuleWidth, height: Theme.controlSize)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(warModeGlass, in: .capsule)
        .matchedTransitionSource(id: WarRoute.warSourceID, in: warNamespace)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                didLongPress = true
                onOpenWarMode()
            }
        )
        .accessibilityLabel("战争模式")
        .accessibilityValue(model.warModeEnabled ? "开" : "关")
        .accessibilityHint("轻点切换状态，长按展开战争模式设置")
        .accessibilityAction(named: Text("展开战争模式设置")) {
            onOpenWarMode()
        }
    }

    private var warModeGlass: Glass {
        model.warModeEnabled
            ? .regular.tint(Color.orange.opacity(0.28)).interactive()
            : .regular.interactive()
    }
}
