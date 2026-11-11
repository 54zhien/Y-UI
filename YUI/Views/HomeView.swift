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

    private var isObscured: Bool {
        !path.isEmpty || model.isSearchingHome || isKeyboardInput
    }

    private var isCollapsed: Bool {
        progress > 0.5
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    DiffuseBackground()

                    scroll

                    topBar

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
                        .offset(y: model.isEditing ? 150 : 0)
                        .opacity(model.isEditing ? 0 : 1)
                        .allowsHitTesting(!model.isEditing)
                        .animation(.snappy(duration: 0.3), value: model.isEditing)
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
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
        }
    }

    private var scroll: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                header

                if !model.isEditing {
                    previewCard
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                PanelGrid(model: model)

                if model.isEditing {
                    HiddenPanelsBar(model: model)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 10)
            .padding(.bottom, dockReserve)
            .animation(.snappy, value: model.isEditing)
        }
        .scrollIndicators(.hidden)
        .blur(radius: isObscured ? 18 : 0)
        .animation(.snappy(duration: 0.26), value: isObscured)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
        } action: { _, offset in
            let raw = min(max(offset / 96, 0), 1)
            let target = reduceMotion ? (raw > 0.5 ? CGFloat(1) : 0) : raw
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
    private var header: some View {
        if !model.isEditing {
            Text("PureGlass")
                .font(.system(size: titleSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .opacity(Double(1 - progress))
                .blur(radius: progress * 6)
                .frame(minHeight: Theme.controlSize, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var previewCard: some View {
        KeyboardPreviewCard()
            .scaleEffect(1 - progress * 0.06, anchor: .topLeading)
            .opacity(Double(1 - progress))
            .allowsHitTesting(progress < 0.5)
            .accessibilityHidden(progress > 0.5)
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                topLeftControl
                Spacer(minLength: 8)
                manageButton
                    .opacity(Double(1 - progress))
                    .blur(radius: progress * 6)
                    .allowsHitTesting(path.isEmpty && progress < 0.5 && !model.isEditing)
                    .accessibilityHidden(!path.isEmpty || progress >= 0.5 || model.isEditing)
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 6)

            Spacer(minLength: 0)
        }
        .opacity(path.isEmpty ? 1 : 0)
        .allowsHitTesting(path.isEmpty)
        .accessibilityHidden(!path.isEmpty)
    }

    @ViewBuilder
    private var topLeftControl: some View {
        if model.isEditing {
            exitEditButton
                .matchedGeometryEffect(id: "topLeftControl", in: topLeftNamespace)
        } else if isCollapsed {
            keyboardCircle
                .matchedGeometryEffect(id: "topLeftControl", in: topLeftNamespace)
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
