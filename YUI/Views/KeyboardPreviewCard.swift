import SwiftUI

struct KeyboardPreviewCard: View {

    static let preferredHeight: CGFloat = 214


    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize


    private let candidates = ["Y 键盘", "智能", "自己的键盘", "你好", "大"]
    private let symbolColumn = ["?", ",", "。", "!"]
    private let letterRows = [
        ["@#", "ABC", "DEF"],
        ["GHI", "JKL", "MNO"],
        ["PQRS", "TUV", "WXYZ"]
    ]
    private let functionColumn: [PreviewKey] = [
        .symbol("delete.left"),
        .text("换行"),
        .symbol("return")
    ]

    var body: some View {
        GlassCard(style: .liquid, cornerRadius: Theme.panelCornerRadius) {
            VStack(alignment: .leading, spacing: 14) {
                keyboard
            }
            .padding(16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("键盘预览，静态演示")
        .accessibilityValue("候选栏：\(candidates.joined(separator: "、"))；九宫格字母键与符号键，不可输入")
    }

    private var keyboard: some View {
        VStack(spacing: 8) {
            candidateBar

            HStack(alignment: .top, spacing: 6) {
                VStack(spacing: 6) {
                    ForEach(symbolColumn, id: \.self) { symbol in
                        KeyCap(text: symbol, height: 30, compact: true)
                    }
                }
                .frame(width: 46)

                VStack(spacing: 6) {
                    ForEach(letterRows, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(row, id: \.self) { key in
                                KeyCap(text: key, height: 40)
                            }
                        }
                    }
                }

                VStack(spacing: 6) {
                    ForEach(functionColumn) { key in
                        switch key {
                        case .text(let text):
                            KeyCap(text: text, height: 40, compact: true)
                        case .symbol(let name):
                            KeyCap(symbol: name, height: 40)
                        }
                    }
                }
                .frame(width: 62)
            }

            HStack(spacing: 6) {
                KeyCap(text: "符号", height: 38, compact: true)
                KeyCap(text: "123", height: 38, compact: true)
                KeyCap(text: "", height: 38, isSpace: true)
                KeyCap(text: "英", height: 38, compact: true)
            }
        }
    }

    private var candidateBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(candidates.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(.system(size: 13, weight: index == 0 ? .semibold : .regular, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)

                if index < candidates.count - 1 {
                    Rectangle()
                        .fill(.primary.opacity(0.12))
                        .frame(width: 1, height: 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.white.opacity(colorScheme == .dark ? 0.10 : 0.55))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(.white.opacity(colorScheme == .dark ? 0.08 : 0.35), lineWidth: 0.6)
        }
    }
}

enum PreviewKey: Identifiable {
    case text(String)
    case symbol(String)

    var id: String {
        switch self {
        case .text(let value): return "text-\(value)"
        case .symbol(let value): return "symbol-\(value)"
        }
    }
}

struct KeyCap: View {

    @Environment(\.colorScheme) private var colorScheme

    var text: String? = nil
    var symbol: String? = nil
    var height: CGFloat = 40
    var compact: Bool = false
    var isSpace: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(.white.opacity(colorScheme == .dark ? 0.14 : 0.62))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(.white.opacity(colorScheme == .dark ? 0.10 : 0.40), lineWidth: 0.6)
            }
            .overlay {
                if let text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: compact ? 11 : 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 2)
                }
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.85))
                }
            }
            .frame(height: height)
            .frame(maxWidth: isSpace ? CGFloat.infinity : nil)
    }
}

#Preview {
    KeyboardPreviewCard().padding()
}
