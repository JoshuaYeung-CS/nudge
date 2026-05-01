import Foundation

struct QuietHours: Codable, Equatable {
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    func isActive(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let now = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute
        if start == end { return false }
        if start < end {
            return now >= start && now < end
        }
        // Wraps midnight (e.g. 22:00 → 08:00).
        return now >= start || now < end
    }

    var description: String {
        String(format: "%02d:%02d–%02d:%02d", startHour, startMinute, endHour, endMinute)
    }

    /// Parses "22:00-08:00" or "22:00 - 08:00".
    static func parse(_ raw: String) -> QuietHours? {
        let cleaned = raw.replacingOccurrences(of: " ", with: "")
        let parts = cleaned.split(separator: "-")
        guard parts.count == 2 else { return nil }
        guard let start = parseTime(String(parts[0])), let end = parseTime(String(parts[1])) else { return nil }
        return QuietHours(startHour: start.0, startMinute: start.1, endHour: end.0, endMinute: end.1)
    }

    private static func parseTime(_ s: String) -> (Int, Int)? {
        let parts = s.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), (0..<24).contains(h),
              let m = Int(parts[1]), (0..<60).contains(m)
        else { return nil }
        return (h, m)
    }
}
