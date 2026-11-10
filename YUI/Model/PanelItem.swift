//
//  PanelItem.swift
//  YUI
//
//  首页「你的设置」两列面板入口的静态演示数据。
//  所有文案与数字均为占位演示内容，不代表真实功能。
//

import Foundation

struct PanelItem: Identifiable, Hashable {

    let id: String
    let title: String
    let value: String
    let detail: String
    let symbol: String

    static let defaults: [PanelItem] = [
        PanelItem(id: "theme", title: "主题", value: "PureGlass", detail: "5 套 · 跟随系统", symbol: "paintpalette"),
        PanelItem(id: "appearance", title: "外观", value: "原生", detail: "白 · 纯净", symbol: "sun.max"),
        PanelItem(id: "sound", title: "声音与触感", value: "震动开 · 按键音", detail: "强度 82% · 音量 40%", symbol: "waveform"),
        PanelItem(id: "input", title: "输入与手势", value: "Y 全拼", detail: "纠错开 · 滑行关", symbol: "hand.draw"),
        PanelItem(id: "toolbar", title: "工具栏", value: "3 个工具", detail: "剪贴板、笔记、表情", symbol: "wrench.and.screwdriver"),
        PanelItem(id: "extensions", title: "扩展", value: "3 个扩展", detail: "快捷动作 1 个", symbol: "puzzlepiece.extension"),
        PanelItem(id: "lexicon", title: "词库", value: "万象 Base v3", detail: "词库和语言模型", symbol: "books.vertical"),
        PanelItem(id: "community", title: "社区", value: "装了 2 个", detail: "主题、扩展、表情包", symbol: "globe"),
        PanelItem(id: "privacy", title: "隐私与省电", value: "上传纠错和统计", detail: "省电关", symbol: "checkmark.shield"),
        PanelItem(id: "stats", title: "输入统计", value: "今天 118 字", detail: "每日趋势和常用词", symbol: "chart.bar.xaxis")
    ]
}
