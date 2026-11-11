import SwiftUI

struct HomeView: View {

    @State private var model = HomeModel()
    @State private var path: [WarRoute] = []
    @State private var searchHistory = SearchHistory()
    @State private var isCollapsed = false
    @State private var collapseProgress: CGFloat = 0
    @State private var isKeyboardInput = false
    @State private var keyboardText = ""
    @Namespace private var warNamespace
    @Namespace private var topLeftNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 38

    private let dockReserve: CGFloat = 128
    private let keyboardGap: CGFloat = 14

    private var isObscured: Bool {
        !path.isEmpty || model.isSearchingHome || isKeyboardInput
    }

    private var collapseThreshold: CGFloat {
        KeyboardPreviewCard.preferredHeight * 0.52
    }

    private var expandThreshold: CGFloat { 26 }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    DiffuseBackground()

                    scroll(screenSize: proxy.size, topInset: proxy.safeAreaInsets.top)
                        .safeAreaBar(edge: .top, spacing: 0) {
                            topBar
                        }

                    if !isKeyboardInput && !model.isSearchingHome {
                        GradientMaskedBlur(edge: .bottom, opaqueFraction: 0.45)
                            .frame(height: 112)
                            .frame(maxWidth: .infinity)
                            .opacity(model.isEditing ? 0 : 1)
                            .allowsHitTesting(false)
                            .ignoresSafeArea(.container, edges: .bottom)

                        BottomDock(
                            model: model,
                            containerSize: proxy.size,
                            safeArea: proxy.safeAreaInsets,
                            warNamespace: warNamespace,
                            onOpenWarMode: { path.append(.war) },
                            onOpenSettings: { path.append(.settings) }
                        )
                        .offset(y: model.isEditing ? 150 : 0)
                        .opacity(model.isEditing ? 0 : 1)
                        .allowsHitTesting(!model.isEditing)
                        .animation(.easeInOut(duration: 0.5), value: model.isEditing)
                    }

                    if model.isSearchingHome || isKeyboardInput {
                        LiquidSearchBar(
                            text: model.isSearchingHome ? $model.homeQuery : $keyboardText,
                            placeholder: model.isSearchingHome ? "搜索面板" : "打几个字试试",
                            history: model.isSearchingHome ? searchHistory : nil,
                            onExit: {
                                withAnimation(.easeInOut(duration: 0.42)) {
                                    if model.isSearchingHome {
                                        model.homeQuery = ""
                                        model.isSearchingHome = false
                                    } else {
                                        isKeyboardInput = false
                                    }
                                }
                            }
                        )
                        .padding(.bottom, keyboardGap)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .navigationDestination(for: WarRoute.self) { route in
                    destination(for: route)
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .sheet(item: $model.activeSheet) { route in
            DemoSheet(route: route)
        }
    }

    private func scroll(screenSize: CGSize, topInset: CGFloat) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 44) {
                if !model.isEditing {
                    KeyboardPreviewCard(morphProgress: collapseProgress)
                        .padding(.top, 28)
                        .visualEffect { content, geometry in
                            let frame = geometry.frame(in: .global)
                            return content
                                .scaleEffect(x: 1 - collapseProgress * 0.72, y: 1 - collapseProgress * 0.76)
                                .offset(
                                    x: collapseProgress * (screenSize.width / 2 - frame.midX),
                                    y: collapseProgress * (topInset + Theme.controlSize / 2 + 6 - frame.midY)
                                )
                        }
                        .opacity(Double(1 - max((collapseProgress - 0.88) / 0.12, 0)))
                        .frame(height: (KeyboardPreviewCard.preferredHeight + 28) * (1 - collapseProgress), alignment: .top)
                        .zIndex(1)
                        .allowsHitTesting(collapseProgress < 0.05)
                }

                Text("你的设置")
                    .font(Theme.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)

                PanelGrid(model: model)

                if model.isEditing {
                    HiddenPanelsBar(model: model)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, dockReserve)
            .animation(.easeInOut(duration: 0.5), value: model.isEditing)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .blur(radius: isObscured ? 18 : 0)
        .animation(.easeInOut(duration: 0.42), value: isObscured)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
        } action: { _, offset in
            guard !model.isEditing else { return }
            updateCollapse(offset)
        }
    }

    private var topBar: some View {
        ZStack {
        HStack(alignment: .center, spacing: 12) {
            if model.isEditing {
                exitEditButton
            } else if collapseProgress > 0 {
                keyboardCircle
                    .matchedGeometryEffect(id: "keyboardInput", in: topLeftNamespace)
                    .opacity(Double(collapseProgress))
            }

            Spacer(minLength: 8)

            if !isKeyboardInput {
                manageButton
                    .allowsHitTesting(path.isEmpty)
                    .accessibilityHidden(!path.isEmpty)
            }
        }
        if !model.isEditing {
            Text("PureGlass")
                .font(.system(size: titleSize - collapseProgress * 18, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .glassEffect(.regular, in: .capsule)
                        .opacity(Double(max((collapseProgress - 0.82) / 0.18, 0)))
                }
                .offset(x: (1 - collapseProgress) * -80)
                .allowsHitTesting(false)
                .accessibilityAddTraits(.isHeader)
        }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .opacity(path.isEmpty ? 1 : 0)
        .allowsHitTesting(path.isEmpty)
        .accessibilityHidden(!path.isEmpty)
    }

    private var keyboardCircle: some View {
        circleButton(symbol: "keyboard", label: "打开键盘输入") {
            withAnimation(.easeInOut(duration: 0.42)) {
                isKeyboardInput = true
            }
        }
    }

    private var exitEditButton: some View {
        circleButton(symbol: "xmark", label: "退出管理模式") {
            withAnimation(.easeInOut(duration: 0.5)) {
                model.toggleEditing()
            }
        }
    }

    private var manageButton: some View {
        circleButton(
            symbol: model.isEditing ? "checkmark" : "slider.horizontal.3",
            label: model.isEditing ? "完成编辑" : "管理面板"
        ) {
            withAnimation(.easeInOut(duration: 0.5)) {
                model.toggleEditing()
            }
        }
    }

    private func circleButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Theme.controlIconSize, weight: .medium))
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    private func updateCollapse(_ offset: CGFloat) {
        let threshold = collapseThreshold
        let fraction = min(max(offset / threshold, 0), 1)
        collapseProgress = reduceMotion ? (offset >= threshold ? 1 : 0) : fraction * fraction * (3 - 2 * fraction)
        if !isCollapsed && offset > collapseThreshold {
            if reduceMotion {
                isCollapsed = true
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                    isCollapsed = true
                }
            }
            return
        }

        if isCollapsed && offset < expandThreshold {
            if reduceMotion {
                isCollapsed = false
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                    isCollapsed = false
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: WarRoute) -> some View {
        switch route {
        case .war:
            let view = WarModeView(model: model)
            if reduceMotion {
                view
            } else {
                view.navigationTransition(.zoom(sourceID: WarRoute.warSourceID, in: warNamespace))
            }
        case .settings:
            let view = SettingsDemoView()
            if reduceMotion {
                view
            } else {
                view.navigationTransition(.zoom(sourceID: WarRoute.settingsSourceID, in: warNamespace))
            }
        }
    }
}

enum WarRoute: Hashable {
    case war
    case settings
    static let warSourceID = "warCapsule"
    static let settingsSourceID = "gearButton"
}

#Preview("浅色") {
    HomeView()
        .preferredColorScheme(.light)
}

#Preview("深色") {
    HomeView()
        .preferredColorScheme(.dark)
}
