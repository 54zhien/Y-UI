//
//  HomeModel.swift
//  YUI
//
//  首页的纯内存演示状态：面板顺序、隐藏集合、编辑模式、战争模式开关、
//  以及当前弹出的占位说明页。按需求不做任何持久化。
//

import Foundation
import Observation

@Observable
final class HomeModel {

    /// 当前展示的面板（顺序即网格顺序）。
    var panels: [PanelItem] = PanelItem.defaults

    /// 被隐藏的面板，可在编辑模式下重新添加。
    var hiddenPanels: [PanelItem] = []

    /// 管理模式（抖动 + 排序 + 隐藏/恢复）。
    var isEditing: Bool = false

    /// 战争模式演示状态，仅本地模拟，不影响任何真实功能。
    var warModeEnabled: Bool = false

    /// 当前弹出的占位说明页。
    var activeSheet: DemoSheetRoute?

    // MARK: - 编辑模式

    func toggleEditing() {
        isEditing.toggle()
    }

    // MARK: - 隐藏 / 恢复

    func hide(_ item: PanelItem) {
        guard let index = panels.firstIndex(where: { $0.id == item.id }) else { return }
        panels.remove(at: index)
        hiddenPanels.append(item)
    }

    func restore(_ item: PanelItem) {
        guard let index = hiddenPanels.firstIndex(where: { $0.id == item.id }) else { return }
        hiddenPanels.remove(at: index)
        // 恢复到列表末尾，保证结果可预期（参考图 4 的「管理」语义）。
        panels.append(item)
    }

    // MARK: - 排序

    func move(from source: Int, to destination: Int) {
        guard panels.indices.contains(source), panels.indices.contains(destination), source != destination else { return }
        let item = panels.remove(at: source)
        panels.insert(item, at: destination)
    }

    func moveUp(_ item: PanelItem) {
        guard let index = panels.firstIndex(where: { $0.id == item.id }), index > 0 else { return }
        panels.swapAt(index, index - 1)
    }

    func moveDown(_ item: PanelItem) {
        guard let index = panels.firstIndex(where: { $0.id == item.id }), index < panels.count - 1 else { return }
        panels.swapAt(index, index + 1)
    }

    func canMoveUp(_ item: PanelItem) -> Bool {
        guard let index = panels.firstIndex(where: { $0.id == item.id }) else { return false }
        return index > 0
    }

    func canMoveDown(_ item: PanelItem) -> Bool {
        guard let index = panels.firstIndex(where: { $0.id == item.id }) else { return false }
        return index < panels.count - 1
    }

    // MARK: - 战争模式

    func toggleWarMode() {
        warModeEnabled.toggle()
    }
}
