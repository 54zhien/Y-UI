import SwiftUI

private struct HomeScrollKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct EdgeFade: View {

    enum Edge {
        case top
        case bottom
    }

    let edge: Edge

    @Environment(\.colorScheme) private var colorScheme

    private var base: Color {
        colorScheme == .dark ? .black : .white
    }

    private var strongOpacity: Double {
        colorScheme == .dark ? 0.62 : 0.78
    }

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: base.opacity(strongOpacity), location: 0),
                .init(color: base.opacity(strongOpacity * 0.55), location: 0.45),
                .init(color: base.opacity(0), location: 1)
            ],
            startPoint: edge == .top ? .top : .bottom,
            endPoint: edge == .top ? .bottom : .top
        )
        .frame(height: Theme.fadeHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HomeView: View {

    @State private var model = HomeModel()
    @State private var path: [WarRoute] = []
    @State private var searchHistory = SearchHistory()
    @State private var collapse: CGFloat = 0
    @State private var isKeyboardInput = false
    @State private var keyboardText = ""
    @FocusState private var keyboardFocused: Bool
    @Namespace private var warNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 38

    private let dockReserve: CGFloat = 116

    private var isObscured: Bool {
        !path.isEmpty || model.isSearchingHome || isKeyboardInput
    }

    private var showsCollapsedHeader: Bool {
        collapse > 0.55
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            GeometryReader { proxy in
            ZStack(alignment: .top) {
                DiffuseBackground()

                scrollContent

                topLayer

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    EdgeFade(edge: .bottom)
                        .frame(height: Theme.fadeHeight * 0.6)
                        .allowsHitTesting(false)
                    BottomDock(
                        model: model,
                        containerSize: proxy.size,
                        safeArea: EdgeInsets(top: 0, leading: 0, bottom: 34, trailing: 0),
                        warNamespace: warNamespace,
                        searchHistory: searchHistory,
                        onOpenWarMode: { path.append(.war) },
                        onOpenSettings: { path.append(.settings) }
                    )
                }
                .ignoresSafeArea(.container, edges: .bottom)

                if isKeyboardInput {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        LiquidSearchBar(
                            text: $keyboardText,
                            placeholder: "打几个字试试",
                            history: nil,
                            onExit: {
                                keyboardFocused = false
                                withAnimation(.snappy) {
                                    isKeyboardInput = false
                                }
                            }
                        )
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationDestination(for: WarRoute.self) { route in
                destination(for: route)
            }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $model.activeSheet) { route in
            DemoSheet(route: route)
        }
    }


    private var scrollContent: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                headerRow
                previewCard
                PanelGrid(model: model)
                if model.isEditing {
                    HiddenPanelsBar(model: model)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, dockReserve)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: HomeScrollKey.self,
                        value: proxy.frame(in: .named("homeScroll")).minY
                    )
                }
            }
        }
        .coordinateSpace(name: "homeScroll")
        .scrollIndicators(.hidden)
        .onPreferenceChange(HomeScrollKey.self) { value in
            let progress = min(max((12 - value) / 110, 0), 1)
            if abs(progress - collapse) > 0.01 {
                collapse = progress
            }
        }
        .blur(radius: isObscured ? 18 : 0)
        .animation(.snappy(duration: 0.28), value: isObscured)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("PureGlass")
                .font(.system(size: titleSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .opacity(Double(1 - collapse))
                .blur(radius: collapse * 6)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            manageButton
                .opacity(Double(1 - collapse))
                .blur(radius: collapse * 8)
                .allowsHitTesting(!showsCollapsedHeader)
                .accessibilityHidden(showsCollapsedHeader)
        }
        .frame(minHeight: Theme.controlSize)
    }

    private var manageButton: some View {
        Button {
            withAnimation(.snappy) {
                model.toggleEditing()
            }
        } label: {
            Image(systemName: model.isEditing ? "checkmark" : "slider.horizontal.3")
                .font(.system(size: 19, weight: .medium))
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(model.isEditing ? "完成编辑" : "管理面板")
        .accessibilityHint(
            model.isEditing
                ? "退出编辑模式"
                : "进入编辑模式，可长按拖动排序、隐藏面板，并重新添加"
        )
    }

    private var previewCard: some View {
        KeyboardPreviewCard()
            .scaleEffect(1 - collapse * 0.04, anchor: .top)
            .opacity(Double(1 - collapse))
            .allowsHitTesting(collapse < 0.5)
            .accessibilityHidden(showsCollapsedHeader)
    }

    private var topLayer: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                EdgeFade(edge: .top)
                    .frame(height: Theme.fadeHeight * 0.7)

                if showsCollapsedHeader {
                    HStack(spacing: 10) {
                        keyboardCircle
                        Spacer(minLength: 8)
                        manageButton
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 8)
                    .transition(.opacity)
                }
            }
            Spacer(minLength: 0)
        }
        .animation(.snappy(duration: 0.24), value: showsCollapsedHeader)
    }

    private var keyboardCircle: some View {
        Button {
            withAnimation(.snappy) {
                isKeyboardInput = true
            }
        } label: {
            Image(systemName: "keyboard")
                .font(.system(size: 19, weight: .medium))
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("打开键盘输入")
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
