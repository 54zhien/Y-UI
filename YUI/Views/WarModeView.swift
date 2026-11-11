import SwiftUI

struct WarModeView: View {

    @Bindable var model: HomeModel
    @State private var settings = WarModeSettings()
    @State private var query = ""
    @State private var isSearching = false
    @State private var history = SearchHistory()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DiffuseBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    masterSection

                    ForEach(settings.groups(matching: query)) { group in
                        section(group)
                    }

                    if settings.groups(matching: query).isEmpty {
                        Text("没有匹配的项目")
                            .font(Theme.rounded(.footnote))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .blur(radius: isSearching ? 16 : 0)
            .animation(.snappy(duration: 0.26), value: isSearching)
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isSearching {
                LiquidSearchBar(
                    text: $query,
                    placeholder: "搜索战争模式项目",
                    history: history,
                    onExit: {
                        withAnimation(.snappy) {
                            isSearching = false
                            query = ""
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("战争模式")
                .font(Theme.rounded(.headline, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            HStack {
                glassCircle(symbol: "xmark", label: "关闭战争模式设置") {
                    dismiss()
                }
                Spacer()
                if !isSearching {
                    glassCircle(symbol: "magnifyingglass", label: "搜索项目") {
                        withAnimation(.snappy) { isSearching = true }
                    }
                }
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.vertical, 6)
    }

    private func glassCircle(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: Theme.controlSize, height: Theme.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }

    private var masterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("总开关")
                .font(Theme.rounded(.footnote, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            container {
                HStack(spacing: 12) {
                    Image(systemName: model.warModeEnabled ? "shield.lefthalf.filled" : "shield")
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 26, height: 22)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("战争模式")
                            .font(Theme.rounded(.subheadline, weight: .semibold))
                        Text("停掉联网和特效，只留打字")
                            .font(Theme.rounded(.caption))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Toggle("", isOn: $model.warModeEnabled)
                        .labelsHidden()
                        .accessibilityLabel("战争模式总开关")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
    }

    private func section(_ group: WarModeGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.title)
                .font(Theme.rounded(.footnote, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            container {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                    row(item)
                    if index < group.items.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }

    private func row(_ item: WarModeItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 26, height: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Theme.rounded(.subheadline, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.detail)
                    .font(Theme.rounded(.caption))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: settings.binding(for: item.id))
                .labelsHidden()
                .accessibilityLabel(item.title)
                .accessibilityHint(item.detail)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func container<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.26))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
        }
    }
}
