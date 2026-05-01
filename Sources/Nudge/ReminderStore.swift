import Foundation

struct AppState: Codable {
    var reminders: [Reminder] = []
    var quietHours: QuietHours? = nil
    var paused: Bool = false
}

/// Reads and writes app state to ~/Library/Application Support/Nudge/state.json.
final class ReminderStore {
    private let url: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Nudge", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("state.json")
    }

    func load() -> AppState {
        guard let data = try? Data(contentsOf: url) else { return AppState() }
        return (try? decoder.decode(AppState.self, from: data)) ?? AppState()
    }

    func save(_ state: AppState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
