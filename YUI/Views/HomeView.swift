import SwiftUI

struct HomeView: View {

    @State private var model = HomeModel()
    @State private var warPath: [WarRoute] = []
    @Namespace private var warNamespace
    @Namespace private var searchNamespace
    @State private var searchHistory = SearchHistory()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dockReserve: CGFloat = 132
    private let edgeFade: CGFloat = 44

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $warPath) {
            GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                DiffuseBackground()

                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader("当前键盘")
                        KeyboardPreviewCard()

                        SectionHeader("你的设置")
                        PanelGrid(model: model)

                        if model.isEditing {
                            HiddenPanelsBar(model: model)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        manageButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, dockReserve)
                }
                .scrollIndicators(.hidden)
                .blur(radius: model.isSearchingHome ? 12 : 0)
                .animation(.snappy, value: model.isSearchingHome)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: min(0.5, edgeFade / max(proxy.size.height, 1))),
                            .init(color: .black, location: max(0.5, 1 - edgeFade / max(proxy.size.height, 1))),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                BottomDock(
                    model: model,
                    containerSize: proxy.size,
                    safeArea: proxy.safeAreaInsets,
                    warNamespace: warNamespace,
                    searchNamespace: searchNamespace,
                    searchHistory: searchHistory,
                    onOpenWarMode: { warPath.append(.war) },
                    onOpenSettings: { warPath.append(.settings) }
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: WarRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(item: $model.activeSheet) { route in
            DemoSheet(route: route)
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
                view.navigationTransition(.zoom(sourceID: WarRoute.settingsSourceID, in: searchNamespace))
            }
        }
    }
    private var manageButton: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.snappy) {
                    model.toggleEditing()
                }
            } label: {
                Text(model.isEditing ? "完成" : "管理")
                    .font(Theme.rounded(.footnote, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .frame(minHeight: 44)
                    .contentShape(.capsule)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .accessibilityLabel(model.isEditing ? "完成编辑" : "管理面板")
            .accessibilityHint(
                model.isEditing
                    ? "退出编辑模式"
                    : "进入编辑模式，可拖动或上移下移排序、隐藏面板，并重新添加"
            )

            Spacer()
        }
        .padding(.top, 2)
    }
}

#Preview("浅色") {
    HomeView()
        .preferredColorScheme(.light)
}

#Preview("深色") {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("大字号") {
    HomeView()
        .dynamicTypeSize(.xxxLarge)
}

enum WarRoute: Hashable {
    case war
    case settings
    static let warSourceID = "warCapsule"
    static let settingsSourceID = "gearButton"
}
