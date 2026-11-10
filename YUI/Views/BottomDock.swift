import SwiftUI

struct BottomDock: View {

    @Bindable var model: HomeModel
    var containerSize: CGSize
    var safeArea: EdgeInsets
    var warNamespace: Namespace.ID
    var searchNamespace: Namespace.ID
    var searchHistory: SearchHistory
    var onOpenWarMode: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    @State private var didLongPress = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let controlSpacing: CGFloat = 8

    private var glassHeight: CGFloat {
        usesAccessibilityText ? 50 : 44
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

    private var capsuleWidth: CGFloat {
        if usesAccessibilityText { return 150 }
        return isNarrow ? 112 : 132
    }

    var body: some View {
        let corner = Theme.screenCornerRadius(for: containerSize)

        let alignmentInset = corner - glassHeight / 2
        let sideInset = max(8, min(alignmentInset, 30))
        let bottomInset = safeArea.bottom > 0 ? max(6, min(alignmentInset, 30)) : 14

        HStack(spacing: 0) {
            circleButton(symbol: "gearshape", label: "设置", offsetX: gearOffset) {
                onOpenSettings()
            }
            .matchedTransitionSource(id: WarRoute.settingsSourceID, in: searchNamespace)

            Spacer(minLength: controlSpacing)

            warModeCapsule(width: capsuleWidth)
                .matchedTransitionSource(id: WarRoute.warSourceID, in: warNamespace)
                .offset(x: gearOffset)

            Spacer(minLength: controlSpacing)

            if model.isSearchingHome {
                SearchFieldBar(query: $model.homeQuery, placeholder: "搜索面板", history: searchHistory) {
                    withAnimation(.snappy) {
                        model.homeQuery = ""
                        model.isSearchingHome = false
                    }
                }
                .matchedGeometryEffect(id: "homeSearch", in: searchNamespace)
            } else {
                circleButton(symbol: "magnifyingglass", label: "搜索") {
                    withAnimation(.snappy) {
                        model.homeQuery = ""
                        model.isSearchingHome = true
                    }
                }
                .matchedGeometryEffect(id: "homeSearch", in: searchNamespace)
            }
        }
        .padding(.horizontal, sideInset)
        .padding(.bottom, bottomInset)
        .frame(maxWidth: .infinity)
    }

    private var gearOffset: CGFloat {
        model.isSearchingHome ? -containerSize.width * 0.62 : 0
    }

    private func circleButton(
        symbol: String,
        label: String,
        offsetX: CGFloat = 0,
        isSettingsSource: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .frame(width: glassHeight, height: glassHeight)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .offset(x: offsetX)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
        .accessibilityHint("打开演示占位页面")
    }

    private func warModeCapsule(width: CGFloat) -> some View {
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
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                didLongPress = true
                onOpenWarMode()
            }
        )
        .accessibilityLabel("战争模式")
        .accessibilityAction(named: Text("展开战争模式设置")) {
            onOpenWarMode()
        }
        .accessibilityValue(model.warModeEnabled ? "开" : "关")
        .accessibilityHint("切换战争模式演示状态，仅模拟，不改变真实网络或特效")
    }

    private var warModeGlass: Glass {
        model.warModeEnabled
            ? .regular.tint(Color.orange.opacity(0.32)).interactive()
            : .regular.interactive()
    }
}
