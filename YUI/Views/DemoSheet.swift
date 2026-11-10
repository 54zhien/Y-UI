//
//  DemoSheet.swift
//  YUI
//
//  面板 / 设置 / 搜索的占位说明页。明确标注「演示占位」，
//  不模拟真实功能，不写入任何数据。
//

import SwiftUI

enum DemoSheetRoute: Identifiable, Hashable {
    case panel(PanelItem)
    case settings
    case search

    var id: String {
        switch self {
        case .panel(let item): return "panel-\(item.id)"
        case .settings: return "settings"
        case .search: return "search"
        }
    }

    var title: String {
        switch self {
        case .panel(let item): return item.title
        case .settings: return "设置"
        case .search: return "搜索"
        }
    }
}

struct DemoSheet: View {

    let route: DemoSheetRoute

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DiffuseBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch route {
                        case .panel(let item):
                            panelContent(item)
                        case .settings:
                            settingsContent
                        case .search:
                            searchContent
                        }

                        demoNote
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(route.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - 面板

    private func panelContent(_ item: PanelItem) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 18, weight: .medium))
                    Text(item.title)
                        .font(Theme.rounded(.headline, weight: .bold))
                }

                Text(item.value)
                    .font(Theme.rounded(.title3, weight: .semibold))

                Text(item.detail)
                    .font(Theme.rounded(.footnote))
                    .foregroundStyle(.secondary)

                Divider().opacity(0.4)

                Text("打开后的设置项属于演示占位：不会读写任何偏好，也不会影响系统或键盘扩展。")
                    .font(Theme.rounded(.footnote))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - 设置

    private var settingsContent: some View {
        GlassCard {
            VStack(spacing: 0) {
                settingsRow(title: "主题", value: "PureGlass", symbol: "paintpalette")
                Divider().opacity(0.35)
                settingsRow(title: "外观", value: "跟随系统", symbol: "circle.lefthalf.filled")
                Divider().opacity(0.35)
                settingsRow(title: "声音与触感", value: "演示占位", symbol: "waveform")
                Divider().opacity(0.35)
                settingsRow(title: "输入与手势", value: "演示占位", symbol: "textformat.size")
                Divider().opacity(0.35)
                settingsRow(title: "隐私与省电", value: "演示占位", symbol: "checkmark.shield")
            }
            .padding(.horizontal, 4)
        }
    }

    private func settingsRow(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 22)
                .foregroundStyle(.secondary)
            Text(title)
                .font(Theme.rounded(.subheadline))
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.rounded(.footnote))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityHint("演示占位，不可操作")
    }

    // MARK: - 搜索

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("搜索面板、主题、词库")
                    .font(Theme.rounded(.subheadline))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("搜索框，演示占位")
            .accessibilityHint("不连接真实搜索")

            Text("这里只展示搜索入口的视觉样式，不提供输入与结果。")
                .font(Theme.rounded(.footnote))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 统一说明

    private var demoNote: some View {
        Text("演示占位：本页面用于核对布局与材料，没有真实数据与业务逻辑。")
            .font(Theme.rounded(.caption))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    DemoSheet(route: .settings)
}
