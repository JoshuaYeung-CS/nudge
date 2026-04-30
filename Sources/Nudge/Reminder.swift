import Foundation

struct Reminder: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var message: String
    var intervalSeconds: TimeInterval
    var enabled: Bool
    var lastFiredAt: Date?
    var snoozedUntil: Date?

    init(
        id: UUID = UUID(),
        title: String = "Reminder",
        message: String,
        intervalSeconds: TimeInterval,
        enabled: Bool = true,
        lastFiredAt: Date? = nil,
        snoozedUntil: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.intervalSeconds = intervalSeconds
        self.enabled = enabled
        self.lastFiredAt = lastFiredAt
        self.snoozedUntil = snoozedUntil
    }

    /// Human-readable interval like "15m", "1h 30m", "45s".
    var intervalDescription: String {
        let s = Int(intervalSeconds.rounded())
        if s < 60 { return "\(s)s" }
        let m = s / 60
        if m < 60 { return "\(m)m" }
        let h = m / 60
        let rem = m % 60
        return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
    }

    func nextFireDate(from reference: Date) -> Date {
        if let snooze = snoozedUntil, snooze > reference { return snooze }
        let base = lastFiredAt ?? reference
        return base.addingTimeInterval(intervalSeconds)
    }
}

enum IntervalParser {
    /// Parses "30s", "15m", "1h", "1h30m", or a bare number (minutes).
    static func parse(_ raw: String) -> TimeInterval? {
        let s = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !s.isEmpty else { return nil }

        if let bare = Double(s) { return bare * 60 }

        var total: TimeInterval = 0
        var number = ""
        for ch in s {
            if ch.isNumber || ch == "." {
                number.append(ch)
            } else if let n = Double(number) {
                switch ch {
                case "s": total += n
                case "m": total += n * 60
                case "h": total += n * 3600
                default: return nil
                }
                number = ""
            } else {
                return nil
            }
        }
        if !number.isEmpty { return nil } // trailing number with no unit
        return total > 0 ? total : nil
    }
}
