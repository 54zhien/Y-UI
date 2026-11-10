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

struct SearchFieldBar: View {

    @Binding var query: String
    let placeholder: String
    let history: SearchHistory
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if !history.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(history.items, id: \.self) { term in
                            chip(term)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .frame(height: 34)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: $query)
                    .font(Theme.rounded(.footnote))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { history.add(query) }

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("清空搜索")
                }

                Button(action: exitSearch) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("退出搜索")
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
            }
            .padding(.horizontal, 18)
        }
        .padding(.bottom, 8)
    }

    private func chip(_ term: String) -> some View {
        HStack(spacing: 4) {
            Button {
                query = term
                history.add(term)
            } label: {
                Text(term)
                    .font(Theme.rounded(.caption))
                    .lineLimit(1)
                    .padding(.leading, 10)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("搜索 \(term)")

            Button {
                history.remove(term)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 22, height: 22)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除历史 \(term)")
            .padding(.trailing, 4)
        }
        .glassEffect(.regular, in: .capsule)
    }

    private func exitSearch() {
        history.add(query)
        query = ""
        onExit()
    }
}
