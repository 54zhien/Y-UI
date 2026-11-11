import SwiftUI

struct SettingsDemoView: View {

    @State private var history = SearchHistory(seed: ["外观", "输入", "词库"])
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss

    private let placeholders: [WarModeItem] = [
        WarModeItem(id: "s1", title: "演示分组 A", detail: "占位条目，仅演示设置页版式", symbol: "square.grid.2x2", defaultOn: true),
        WarModeItem(id: "s2", title: "演示分组 B", detail: "占位条目，等待真实设置接入", symbol: "slider.horizontal.3", defaultOn: true),
        WarModeItem(id: "s3", title: "演示分组 C", detail: "占位条目，不含业务规则", symbol: "tray", defaultOn: true),
        WarModeItem(id: "s4", title: "演示分组 D", detail: "占位条目，仅用于检查排版与搜索", symbol: "info.circle", defaultOn: true)
    ]

    private var filtered: [WarModeItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return placeholders }
        return placeholders.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.detail.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        ZStack {
            DiffuseBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    container {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                            row(item)
                            if index < filtered.count - 1 {
                                Divider().padding(.leading, 52)
                            }
                        }
                    }

                    if filtered.isEmpty {
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
                    placeholder: "搜索设置",
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
            Text("设置")
                .font(Theme.rounded(.headline, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            HStack {
                glassCircle(symbol: "xmark", label: "关闭设置") {
                    dismiss()
                }
                Spacer()
                if !isSearching {
                    glassCircle(symbol: "magnifyingglass", label: "搜索设置") {
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

    private func container<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
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

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
