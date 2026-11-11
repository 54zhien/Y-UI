import SwiftUI

struct HomeView: View {

    @State private var model = HomeModel()
    @State private var path: [WarRoute] = []
    @State private var searchHistory = SearchHistory()
    @State private var progress: CGFloat = 0
    @State private var isCollapsed = false
    @State private var isKeyboardInput = false
    @State private var keyboardText = ""
    @State private var isScrolling = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var suppressExpandUntil: Date = .distantPast
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
        min(max(KeyboardPreviewCard.preferredHeight * 0.78, 120), 260)
    }

    private var expandThreshold: CGFloat { 26 }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    DiffuseBackground()

                    ScrollViewReader { reader in
                        scroll(reader: reader)
                            .onAppear { scrollProxy = reader }
                            .safeAreaBar(edge: .top, spacing: 0) {
                                topBar
                            }
                    }

                    if !isKeyboardInput && !model.isSearchingHome {
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
                        .padding(.bottom, proxy.safeAreaInsets.bottom)
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

    private func scroll(reader: ScrollViewProxy) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                Color.clear
                    .frame(height: 0)
                    .id("topAnchor")

                previewSection

                Text("你的设置")
                    .font(Theme.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)
                    .id("settingsTitle")

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
        .scrollEdgeEffectStyle(.soft, for: [.top, .bottom])
        .blur(radius: isObscured ? 18 : 0)
        .animation(.easeInOut(duration: 0.42), value: isObscured)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
        } action: { _, offset in
            updateCollapse(offset)
        }
        .onScrollPhaseChange { _, phase in
            isScrolling = phase == .interacting || phase == .decelerating
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        if !model.isEditing && !isCollapsed {
            KeyboardPreviewCard()
                .opacity(Double(1 - progress))
                .scaleEffect(1 - min(progress, 1) * 0.05, anchor: .topLeading)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            if model.isEditing {
                exitEditButton
            } else if isCollapsed {
                keyboardCircle
                    .matchedGeometryEffect(id: "keyboardInput", in: topLeftNamespace)
            } else {
                Text("PureGlass")
                    .font(.system(size: titleSize, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(minHeight: Theme.controlSize, alignment: .leading)
                    .opacity(Double(1 - progress))
                    .blur(radius: progress * 6)
                    .accessibilityAddTraits(.isHeader)
            }

            Spacer(minLength: 8)

            if !isKeyboardInput {
                manageButton
                    .allowsHitTesting(path.isEmpty)
                    .accessibilityHidden(!path.isEmpty)
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
        let raw = min(max(offset / collapseThreshold, 0), 1)
        let eased = raw * raw * (3 - 2 * raw)

        if !isCollapsed && offset > collapseThreshold {
            if reduceMotion {
                isCollapsed = true
                progress = 1
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                    isCollapsed = true
                    progress = 1
                }
                anchorToSettings()
            }
            return
        }

        if isCollapsed && isScrolling && Date() > suppressExpandUntil && offset < expandThreshold {
            if reduceMotion {
                isCollapsed = false
                progress = 0
            } else {
                withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                    isCollapsed = false
                    progress = 0
                }
                anchorToTop()
            }
            return
        }

        guard !isCollapsed else { return }

        let target = reduceMotion ? (eased > 0.5 ? CGFloat(1) : 0) : eased
        if abs(target - progress) > 0.01 {
            progress = target
        }
    }

    private func anchorToSettings() {
        suppressExpandUntil = Date().addingTimeInterval(0.6)
        DispatchQueue.main.async {
            withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                scrollProxy?.scrollTo("settingsTitle", anchor: .top)
            }
        }
    }

    private func anchorToTop() {
        suppressExpandUntil = Date().addingTimeInterval(0.6)
        DispatchQueue.main.async {
            withAnimation(.spring(duration: 0.45, bounce: 0.08)) {
                scrollProxy?.scrollTo("topAnchor", anchor: .top)
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
