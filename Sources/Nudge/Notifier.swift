import Foundation

/// Sends silent macOS notifications via `osascript display notification`.
///
/// We shell out to osascript instead of using UNUserNotificationCenter so that
/// the executable works correctly even when launched outside an .app bundle
/// (during dev runs via `swift run`). UNUserNotificationCenter requires a
/// signed bundle identifier, which is friction we don't need.
enum Notifier {
    static func fire(title: String, message: String) {
        let safeTitle = escape(title)
        let safeMessage = escape(message)
        let script = "display notification \"\(safeMessage)\" with title \"\(safeTitle)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        do {
            try process.run()
        } catch {
            NSLog("Nudge: failed to fire notification: \(error)")
        }
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
