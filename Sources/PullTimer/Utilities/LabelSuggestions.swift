import Foundation

struct LabelChip: Identifiable, Equatable {
    let title: String
    var duration: TimeInterval?
    var id: String { title.lowercased() }
}

enum LabelSuggestions {
    static let presets = ["Focus", "Break", "Call", "Email", "Lunch", "Walk"]

    /// Recent titled timers first (with their last duration), then unused presets.
    static func chips(from items: [TimerItem], limit: Int = 6) -> [LabelChip] {
        var seen = Set<String>()
        var result: [LabelChip] = []

        for item in items.reversed() {
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let key = title.lowercased()
            guard seen.insert(key).inserted else { continue }
            result.append(LabelChip(title: title, duration: item.duration))
            if result.count >= 4 { break }
        }

        for preset in presets {
            guard seen.insert(preset.lowercased()).inserted else { continue }
            result.append(LabelChip(title: preset, duration: nil))
            if result.count >= limit { break }
        }
        return result
    }
}
