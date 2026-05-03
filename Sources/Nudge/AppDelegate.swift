import AppKit

private struct SnoozeRequest {
    let id: UUID
    let minutes: Int
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let engine = ReminderEngine()
    private let store = ReminderStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let initial = store.load()
        engine.setReminders(initial.reminders)
        engine.quietHours = initial.quietHours
        engine.paused = initial.paused
        engine.onChange = { [weak self] in
            guard let self else { return }
            self.persist()
            self.rebuildMenu()
            self.refreshStatusIcon()
        }
        engine.start()

        rebuildMenu()
        refreshStatusIcon()

        // Tick the icon every minute so the quiet-hours overlay flips on/off
        // without the user opening the menu.
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshStatusIcon()
        }
    }

    // MARK: - Status icon

    private func refreshStatusIcon() {
        guard let button = statusItem.button else { return }
        let symbol: String
        if engine.paused {
            symbol = "bell.slash"
        } else if engine.quietHours?.isActive() == true {
            symbol = "moon"
        } else {
            symbol = "bell"
        }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Nudge")
        button.image?.isTemplate = true
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

        let pauseTitle = engine.paused ? "Resume all" : "Pause all"
        menu.addItem(NSMenuItem(title: pauseTitle, action: #selector(togglePauseAll), keyEquivalent: ""))

        menu.addItem(quietHoursItem())

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
        var suffix = "every \(reminder.intervalDescription)"
        if let snooze = reminder.snoozedUntil, snooze > Date() {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            suffix = "snoozed until \(f.string(from: snooze))"
        }
        let item = NSMenuItem(
            title: "\(mark) \(reminder.message) — \(suffix)",
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

        for minutes in [15, 30, 60] {
            let snooze = NSMenuItem(
                title: "Snooze \(minutes)m",
                action: #selector(snoozeReminder(_:)),
                keyEquivalent: ""
            )
            snooze.representedObject = SnoozeRequest(id: reminder.id, minutes: minutes)
            snooze.target = self
            submenu.addItem(snooze)
        }

        submenu.addItem(.separator())

        let delete = NSMenuItem(title: "Delete", action: #selector(deleteReminder(_:)), keyEquivalent: "")
        delete.representedObject = reminder.id
        delete.target = self
        submenu.addItem(delete)

        item.submenu = submenu
        return item
    }

    private func quietHoursItem() -> NSMenuItem {
        let title: String
        if let q = engine.quietHours {
            let active = q.isActive() ? " (active)" : ""
            title = "Quiet hours: \(q.description)\(active)"
        } else {
            title = "Quiet hours: off"
        }

        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        submenu.addItem(NSMenuItem(title: "Set…", action: #selector(setQuietHours), keyEquivalent: ""))
        if engine.quietHours != nil {
            let disable = NSMenuItem(title: "Disable", action: #selector(disableQuietHours), keyEquivalent: "")
            submenu.addItem(disable)
        }
        for sub in submenu.items where sub.target == nil && sub.action != nil {
            sub.target = self
        }
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

    @objc private func snoozeReminder(_ sender: NSMenuItem) {
        guard let req = sender.representedObject as? SnoozeRequest else { return }
        var current = engine.reminders
        guard let index = current.firstIndex(where: { $0.id == req.id }) else { return }
        current[index].snoozedUntil = Date().addingTimeInterval(TimeInterval(req.minutes) * 60)
        engine.setReminders(current)
    }

    @objc private func togglePauseAll() {
        engine.setPaused(!engine.paused)
    }

    @objc private func setQuietHours() {
        let alert = NSAlert()
        alert.messageText = "Quiet hours"
        alert.informativeText = "Format: HH:MM-HH:MM (24h). Wraps midnight if end is earlier than start."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = engine.quietHours?.description.replacingOccurrences(of: "–", with: "-") ?? "22:00-08:00"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard let parsed = QuietHours.parse(field.stringValue) else { return }
        engine.setQuietHours(parsed)
    }

    @objc private func disableQuietHours() {
        engine.setQuietHours(nil)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Nudge"
        alert.informativeText = "Silent menu-bar reminders for macOS."
        alert.runModal()
    }

    // MARK: - Persistence

    private func persist() {
        store.save(AppState(
            reminders: engine.reminders,
            quietHours: engine.quietHours,
            paused: engine.paused
        ))
    }
}
