import Foundation
import Observation

@Observable
final class HomeModel {

    var panels: [PanelItem] = PanelItem.defaults

    var hiddenPanels: [PanelItem] = []

    var isEditing: Bool = false

    var warModeEnabled: Bool = false

    var isSearchingHome: Bool = false

    var homeQuery: String = ""

    var filteredPanels: [PanelItem] {
        let trimmed = homeQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return panels }
        return panels.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.value.localizedCaseInsensitiveContains(trimmed)
                || $0.detail.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var activeSheet: DemoSheetRoute?

    func toggleEditing() {
        isEditing.toggle()
    }

    func hide(_ item: PanelItem) {
        guard let index = panels.firstIndex(where: { $0.id == item.id }) else { return }
        panels.remove(at: index)
        hiddenPanels.append(item)
    }

    func restore(_ item: PanelItem) {
        guard let index = hiddenPanels.firstIndex(where: { $0.id == item.id }) else { return }
        hiddenPanels.remove(at: index)

        panels.append(item)
    }

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

    func toggleWarMode() {
        warModeEnabled.toggle()
    }
}
