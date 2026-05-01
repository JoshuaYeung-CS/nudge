import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let engine = ReminderEngine()
    private let store = ReminderStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Nudge")
            button.image?.isTemplate = true
        }

        let initial = store.load()
        engine.setReminders(initial.reminders)
        engine.onChange = { [weak self] in
            guard let self else { return }
            self.persist()
            self.rebuildMenu()
        }
        engine.start()
        rebuildMenu()
    }

    // MARK: - Menu

    private func rebuildMenu() {
        let menu = NSMenu()

        if engine.reminders.isEmpty {
            let header = NSMenuItem(title: "No reminders yet", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
        } else {
            for reminder in engine.reminders {
                menu.addItem(reminderItem(for: reminder))
            }
        }

        menu.addItem(.separator())

        let addItem = NSMenuItem(title: "Add reminder…", action: #selector(addReminder), keyEquivalent: "n")
        menu.addItem(addItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "About Nudge", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Nudge", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.target == nil && item.action != nil {
            item.target = self
        }

        statusItem.menu = menu
    }

    private func reminderItem(for reminder: Reminder) -> NSMenuItem {
        let mark = reminder.enabled ? "•" : "○"
        let item = NSMenuItem(
            title: "\(mark) \(reminder.message) — every \(reminder.intervalDescription)",
            action: nil,
            keyEquivalent: ""
        )

        let submenu = NSMenu()

        let toggle = NSMenuItem(
            title: reminder.enabled ? "Pause" : "Resume",
            action: #selector(toggleReminder(_:)),
            keyEquivalent: ""
        )
        toggle.representedObject = reminder.id
        toggle.target = self
        submenu.addItem(toggle)

        let edit = NSMenuItem(title: "Edit…", action: #selector(editReminder(_:)), keyEquivalent: "")
        edit.representedObject = reminder.id
        edit.target = self
        submenu.addItem(edit)

        submenu.addItem(.separator())

        let delete = NSMenuItem(title: "Delete", action: #selector(deleteReminder(_:)), keyEquivalent: "")
        delete.representedObject = reminder.id
        delete.target = self
        submenu.addItem(delete)

        item.submenu = submenu
        return item
    }

    // MARK: - Actions

    @objc private func addReminder() {
        guard let result = InputDialog.reminder() else { return }
        var current = engine.reminders
        current.append(Reminder(
            title: result.title,
            message: result.message,
            intervalSeconds: result.interval
        ))
        engine.setReminders(current)
    }

    @objc private func toggleReminder(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        var current = engine.reminders
        guard let index = current.firstIndex(where: { $0.id == id }) else { return }
        current[index].enabled.toggle()
        if current[index].enabled {
            // Reset the clock so resuming doesn't fire instantly.
            current[index].lastFiredAt = Date()
        }
        engine.setReminders(current)
    }

    @objc private func editReminder(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        var current = engine.reminders
        guard let index = current.firstIndex(where: { $0.id == id }) else { return }
        guard let result = InputDialog.reminder(prefilling: current[index]) else { return }
        current[index].title = result.title
        current[index].message = result.message
        current[index].intervalSeconds = result.interval
        engine.setReminders(current)
    }

    @objc private func deleteReminder(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        var current = engine.reminders
        current.removeAll { $0.id == id }
        engine.setReminders(current)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Nudge"
        alert.informativeText = "Silent menu-bar reminders for macOS."
        alert.runModal()
    }

    // MARK: - Persistence

    private func persist() {
        store.save(AppState(reminders: engine.reminders))
    }
}
