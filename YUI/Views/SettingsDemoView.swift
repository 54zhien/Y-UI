import SwiftUI

struct SettingsDemoView: View {

    @State private var history = SearchHistory(seed: ["外观", "输入", "词库"])
    @State private var query = ""
    @State private var isSearching = false
    @Namespace private var searchNamespace
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
                    group {
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
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isSearching {
                SearchFieldBar(query: $query, placeholder: "搜索设置", history: history) {
                    withAnimation(.snappy) { isSearching = false }
                }
                .matchedGeometryEffect(id: "settingsSearch", in: searchNamespace)
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("设置")
                .font(Theme.rounded(.headline, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("关闭设置")

                Spacer()

                if !isSearching {
                    Button {
                        withAnimation(.snappy) { isSearching = true }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .matchedGeometryEffect(id: "settingsSearch", in: searchNamespace)
                    .accessibilityLabel("搜索设置")
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 6)
    }

    private func group<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
            )
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
