import SwiftUI

@Observable
final class SearchHistory {

    private(set) var items: [String]

    init(seed: [String] = ["天气", "iCloud 同步", "扩展联网"]) {
        items = seed
    }

    func add(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.removeAll { $0 == trimmed }
        items.insert(trimmed, at: 0)
        if items.count > 8 {
            items = Array(items.prefix(8))
        }
    }

    func remove(_ term: String) {
        items.removeAll { $0 == term }
    }
}

struct SearchHistoryRow: View {

    let history: SearchHistory
    @Binding var query: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(history.items, id: \.self) { term in
                    chip(term)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
        }
        .frame(height: Theme.historyChipHeight)
    }

    private func chip(_ term: String) -> some View {
        HStack(spacing: 0) {
            Button {
                query = term
            } label: {
                Text(term)
                    .font(Theme.rounded(.footnote))
                    .lineLimit(1)
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .frame(height: Theme.historyChipHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("搜索 \(term)")

            Button {
                history.remove(term)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 26, height: Theme.historyChipHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除历史 \(term)")
            .padding(.trailing, 8)
        }
        .glassEffect(.regular, in: .capsule)
    }
}

struct LiquidSearchBar: View {

    @Binding var text: String
    let placeholder: String
    var history: SearchHistory?
    let onExit: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 10) {
            if let history {
                SearchHistoryRow(history: history, query: $text)
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)

                    TextField(placeholder, text: $text)
                        .font(Theme.rounded(.footnote))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($focused)
                        .onSubmit { history?.add(text) }

                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("清空搜索")
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: Theme.searchControlSize)
                .glassEffect(.regular.interactive(), in: .capsule)
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
                }

                Button {
                    exit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: Theme.searchControlSize, height: Theme.searchControlSize)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("退出搜索")
            }
            .padding(.horizontal, Theme.screenPadding)
        }
        .padding(.bottom, 8)
        .task {
            try? await Task.sleep(for: .milliseconds(120))
            focused = true
        }
    }

    private func exit() {
        focused = false
        history?.add(text)
        text = ""
        onExit()
    }
}
