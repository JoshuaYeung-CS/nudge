import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let engine = ReminderEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Nudge")
            button.image?.isTemplate = true
        }

        // Seed a single test reminder until persistence lands.
        engine.setReminders([
            Reminder(title: "Reminder", message: "drink water", intervalSeconds: 15 * 60)
        ])
        engine.onChange = { [weak self] in self?.rebuildMenu() }
        engine.start()
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if engine.reminders.isEmpty {
            let header = NSMenuItem(title: "Nudge — no reminders yet", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
        } else {
            for reminder in engine.reminders {
                let mark = reminder.enabled ? "•" : "○"
                let title = "\(mark) \(reminder.message) — every \(reminder.intervalDescription)"
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "About Nudge", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Nudge", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.target == nil && item.action != nil {
            item.target = self
        }

        statusItem.menu = menu
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Nudge"
        alert.informativeText = "Silent menu-bar reminders for macOS."
        alert.runModal()
    }
}
