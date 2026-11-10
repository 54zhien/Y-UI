import SwiftUI

struct WarModeItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let defaultOn: Bool
}

struct WarModeGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let items: [WarModeItem]
}

enum WarModeCatalog {

    static let groups: [WarModeGroup] = [
        WarModeGroup(id: "network", title: "联网与服务", items: [
            WarModeItem(id: "community", title: "社区", detail: "不浏览、不下载、不上传，入口藏起来", symbol: "globe", defaultOn: true),
            WarModeItem(id: "icloud", title: "iCloud 同步", detail: "不上传、不拉取，手机里的照常用", symbol: "icloud", defaultOn: true),
            WarModeItem(id: "notice", title: "公告", detail: "不拉新公告和公告图片", symbol: "megaphone", defaultOn: true),
            WarModeItem(id: "feedback", title: "反馈与建议", detail: "不上传，写好的先留在手机里", symbol: "bubble.left", defaultOn: true),
            WarModeItem(id: "crash", title: "崩溃报告上传", detail: "崩溃记录只留在手机里", symbol: "ladybug", defaultOn: true),
            WarModeItem(id: "correction", title: "纠错数据", detail: "不上传，也不拉新参数", symbol: "arrow.triangle.2.circlepath", defaultOn: true),
            WarModeItem(id: "model", title: "模型下载", detail: "已经下好的模型照常用", symbol: "arrow.down.circle", defaultOn: true),
            WarModeItem(id: "scheme", title: "方案下载和更新", detail: "已经下好的方案照常用", symbol: "shippingbox", defaultOn: true),
            WarModeItem(id: "giphy", title: "GIPHY 表情包", detail: "不搜 GIPHY，自己导入的照常用", symbol: "face.smiling", defaultOn: true),
            WarModeItem(id: "ai", title: "AI 接口", detail: "不用远程模型，改用手机本机的", symbol: "lightbulb", defaultOn: true),
            WarModeItem(id: "web", title: "网页链接", detail: "关于页、隐私政策、打开网址、网上搜索藏起来", symbol: "link", defaultOn: true),
            WarModeItem(id: "weather", title: "天气", detail: "不取天气，候选和回车按钮都不显示", symbol: "sun.max", defaultOn: true)
        ]),
        WarModeGroup(id: "extension", title: "扩展与系统", items: [
            WarModeItem(id: "extNet", title: "扩展联网", detail: "扩展发出的请求一律拦下", symbol: "puzzlepiece.extension", defaultOn: true),
            WarModeItem(id: "extNotify", title: "扩展发通知", detail: "不发通知，也不触发快捷指令", symbol: "paperplane", defaultOn: true),
            WarModeItem(id: "voiceLocal", title: "语音只用本机识别", detail: "不走苹果服务器，也不用云端识别", symbol: "mic", defaultOn: true),
            WarModeItem(id: "power", title: "省电模式全开", detail: "省电的 16 项全部打开", symbol: "bolt", defaultOn: true)
        ]),
        WarModeGroup(id: "display", title: "显示与特效", items: [
            WarModeItem(id: "particles", title: "会动的背景和粒子", detail: "背景停住，不飘粒子", symbol: "sparkles", defaultOn: true),
            WarModeItem(id: "keyGlow", title: "按键反光", detail: "不画跟着手指走的光和按键灯光", symbol: "rays", defaultOn: true),
            WarModeItem(id: "refraction", title: "玻璃折射", detail: "玻璃键换成实色，不扭曲背景", symbol: "drop", defaultOn: true),
            WarModeItem(id: "translucency", title: "透光", detail: "按键和背景不再透出光", symbol: "circle.lefthalf.filled", defaultOn: true),
            WarModeItem(id: "smallIcon", title: "会动的小图标", detail: "小图标不动，动图停在第一帧", symbol: "photo", defaultOn: true),
            WarModeItem(id: "toolFade", title: "工具页渐隐模糊", detail: "列表上下不淡出、不糊", symbol: "eye.slash", defaultOn: true),
            WarModeItem(id: "voiceGlow", title: "语音光效", detail: "说话时不亮光", symbol: "waveform", defaultOn: true)
        ]),
        WarModeGroup(id: "motion", title: "交互与动画", items: [
            WarModeItem(id: "pressAnim", title: "按下的动画", detail: "键不鼓起、不回弹，大字直接出", symbol: "hand.tap", defaultOn: true),
            WarModeItem(id: "backgroundPush", title: "背景被手指推开", detail: "手指附近时背景不再被推开、晃动", symbol: "arrow.up.left.and.arrow.down.right", defaultOn: true),
            WarModeItem(id: "candidateAnim", title: "候选、换盘面、变高的动画", detail: "直接换，不做过渡", symbol: "square.stack", defaultOn: true),
            WarModeItem(id: "appMotion", title: "App 里的动效", detail: "图标不变形，切换不做动画", symbol: "cursorarrow", defaultOn: true),
            WarModeItem(id: "pet", title: "键盘宠物", detail: "宠物收起来，不动也不搞破坏", symbol: "heart", defaultOn: true)
        ])
    ]

    static let allItems: [WarModeItem] = groups.flatMap(\.items)
}

@Observable
final class WarModeSettings {

    private var values: [String: Bool] = Dictionary(
        uniqueKeysWithValues: WarModeCatalog.allItems.map { ($0.id, $0.defaultOn) }
    )

    func isOn(_ id: String) -> Bool {
        values[id] ?? false
    }

    func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { self.values[id] ?? false },
            set: { self.values[id] = $0 }
        )
    }

    func groups(matching query: String) -> [WarModeGroup] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return WarModeCatalog.groups }
        return WarModeCatalog.groups.compactMap { group in
            let items = group.items.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.detail.localizedCaseInsensitiveContains(trimmed)
            }
            return items.isEmpty ? nil : WarModeGroup(id: group.id, title: group.title, items: items)
        }
    }
}
