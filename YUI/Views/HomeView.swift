import SwiftUI

struct HomeView: View {

    @State private var model = HomeModel()
    @State private var path: [WarRoute] = []
    @State private var searchHistory = SearchHistory()
    @State private var progress: CGFloat = 0
    @State private var isKeyboardInput = false
    @State private var keyboardText = ""
    @Namespace private var warNamespace
    @Namespace private var topLeftNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 38

    private let dockReserve: CGFloat = 112
    private let topBarHeight: CGFloat = 60

    private var isObscured: Bool {
        !path.isEmpty || model.isSearchingHome || isKeyboardInput
    }

    private var isCollapsed: Bool {
        progress >= 0.9
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    DiffuseBackground()

                    scroll

                    dockLayer(proxy)

                    topBar


                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomInput
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

    @ViewBuilder
    private var bottomInput: some View {
        if model.isSearchingHome {
            LiquidSearchBar(
                text: $model.homeQuery,
                placeholder: "搜索面板",
                history: searchHistory,
                onExit: {
                    withAnimation(.snappy(duration: 0.3)) {
                        model.homeQuery = ""
                        model.isSearchingHome = false
                    }
                }
            )
        } else if isKeyboardInput {
            LiquidSearchBar(
                text: $keyboardText,
                placeholder: "打几个字试试",
                history: nil,
                onExit: {
                    withAnimation(.snappy) {
                        isKeyboardInput = false
                    }
                }
            )
            .matchedGeometryEffect(id: "keyboardInput", in: topLeftNamespace)
        }
    }

    private func dockLayer(_ proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            BottomDock(
                model: model,
                containerSize: proxy.size,
                safeArea: proxy.safeAreaInsets,
                warNamespace: warNamespace,
                onOpenWarMode: { path.append(.war) },
                onOpenSettings: { path.append(.settings) }
            )
            .offset(y: model.isEditing || isKeyboardInput ? 150 : 0)
            .opacity(model.isEditing || isKeyboardInput ? 0 : 1)
            .allowsHitTesting(!model.isEditing && !isKeyboardInput)
            .animation(.snappy(duration: 0.3), value: model.isEditing)
            .animation(.snappy(duration: 0.3), value: isKeyboardInput)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var scroll: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                if !model.isEditing {
                    titleBlock
                }

                PanelGrid(model: model)

                if model.isEditing {
                    HiddenPanelsBar(model: model)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, dockReserve)
            .animation(.snappy(duration: 0.24), value: isCollapsed)
            .animation(.snappy(duration: 0.24), value: model.isEditing)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .contentMargins(.top, topBarHeight, for: .scrollContent)
        .blur(radius: isObscured ? 18 : 0)
        .animation(.snappy(duration: 0.26), value: isObscured)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
        } action: { _, offset in
            let raw = min(max(offset / 110, 0), 1)
            let eased = raw * raw * (3 - 2 * raw)
            let target = reduceMotion ? (eased > 0.5 ? CGFloat(1) : 0) : eased
            if abs(target - progress) > 0.01 {
                if reduceMotion {
                    progress = target
                } else {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        progress = target
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var titleBlock: some View {
        if !isCollapsed {
            VStack(alignment: .leading, spacing: 18) {
                Text("PureGlass")
                    .font(.system(size: titleSize, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(Double(1 - progress))
                    .blur(radius: progress * 6)
                    .frame(minHeight: Theme.controlSize, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)

                KeyboardPreviewCard()
                    .opacity(Double(1 - progress))
                    .scaleEffect(1 - progress * 0.05, anchor: .topLeading)
                    .accessibilityHidden(progress > 0.5)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            topLeftControl
            Spacer(minLength: 8)
            if !isKeyboardInput {
                manageButton
                    .allowsHitTesting(path.isEmpty)
                    .accessibilityHidden(!path.isEmpty)
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.vertical, 6)
        .frame(height: topBarHeight)
        .frame(maxWidth: .infinity)
        .opacity(path.isEmpty ? 1 : 0)
        .allowsHitTesting(path.isEmpty)
        .accessibilityHidden(!path.isEmpty)
    }

    @ViewBuilder
    private var topLeftControl: some View {
        if model.isEditing {
            exitEditButton
                .matchedGeometryEffect(id: "topLeftControl", in: topLeftNamespace)
        } else if isCollapsed && !isKeyboardInput {
            keyboardCircle
                .matchedGeometryEffect(id: "keyboardInput", in: topLeftNamespace)
        }
    }

    private var keyboardCircle: some View {
        circleButton(symbol: "keyboard", label: "打开键盘输入") {
            withAnimation(.snappy) {
                isKeyboardInput = true
            }
        }
    }

    private var exitEditButton: some View {
        circleButton(symbol: "xmark", label: "退出管理模式") {
            withAnimation(.snappy) {
                model.toggleEditing()
            }
        }
    }

    private var manageButton: some View {
        circleButton(
            symbol: model.isEditing ? "checkmark" : "slider.horizontal.3",
            label: model.isEditing ? "完成编辑" : "管理面板"
        ) {
            withAnimation(.snappy) {
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
