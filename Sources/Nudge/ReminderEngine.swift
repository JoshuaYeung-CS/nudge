import Foundation

/// Owns the live list of reminders and the timer that fires them.
final class ReminderEngine {
    private(set) var reminders: [Reminder] = []
    private var timer: Timer?
    var onChange: (() -> Void)?

    /// How often we wake up to check for due reminders. The actual firing
    /// cadence is per-reminder; this is just the resolution.
    private let tickInterval: TimeInterval = 5

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func setReminders(_ new: [Reminder]) {
        reminders = new
        onChange?()
    }

    private func tick() {
        let now = Date()
        var changed = false
        for index in reminders.indices {
            guard reminders[index].enabled else { continue }
            let nextFire = reminders[index].nextFireDate(from: now)
            if nextFire <= now {
                Notifier.fire(
                    title: reminders[index].title,
                    message: reminders[index].message
                )
                reminders[index].lastFiredAt = now
                reminders[index].snoozedUntil = nil
                changed = true
            }
        }
        if changed { onChange?() }
    }
}
