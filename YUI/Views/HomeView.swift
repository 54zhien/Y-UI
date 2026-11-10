import SwiftUI

struct HomeView: View {

    @State private var model = HomeModel()

    private let dockReserve: CGFloat = 132
    private let edgeFade: CGFloat = 44

    var body: some View {
        @Bindable var model = model

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

                BottomDock(model: model, containerSize: proxy.size, safeArea: proxy.safeAreaInsets)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .sheet(item: $model.activeSheet) { route in
            DemoSheet(route: route)
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
