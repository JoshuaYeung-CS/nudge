import AppKit

enum InputDialog {
    struct Result {
        var title: String
        var message: String
        var interval: TimeInterval
    }

    /// Shows a modal NSAlert with text fields for title, message, and interval.
    /// Returns nil if cancelled or the interval cannot be parsed.
    static func reminder(prefilling existing: Reminder? = nil) -> Result? {
        let alert = NSAlert()
        alert.messageText = existing == nil ? "New reminder" : "Edit reminder"
        alert.informativeText = "Interval examples: 30s, 15m, 1h, 1h30m"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleField = labeledField(label: "Title", placeholder: "Reminder", initial: existing?.title ?? "Reminder")
        let messageField = labeledField(label: "Message", placeholder: "drink water", initial: existing?.message ?? "")
        let intervalField = labeledField(
            label: "Interval",
            placeholder: "15m",
            initial: existing.map { intervalString(seconds: $0.intervalSeconds) } ?? "15m"
        )

        for row in [titleField.row, messageField.row, intervalField.row] {
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalToConstant: 320).isActive = true
        }

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 110))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        alert.accessoryView = container
        alert.window.initialFirstResponder = messageField.field

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return nil }

        let title = titleField.field.stringValue.trimmingCharacters(in: .whitespaces)
        let message = messageField.field.stringValue.trimmingCharacters(in: .whitespaces)
        guard !message.isEmpty else { return nil }
        guard let interval = IntervalParser.parse(intervalField.field.stringValue) else { return nil }

        return Result(
            title: title.isEmpty ? "Reminder" : title,
            message: message,
            interval: interval
        )
    }

    private static func labeledField(label: String, placeholder: String, initial: String) -> (row: NSView, field: NSTextField) {
        let lbl = NSTextField(labelWithString: label)
        lbl.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = .secondaryLabelColor
        lbl.setContentHuggingPriority(.required, for: .horizontal)

        let field = NSTextField()
        field.placeholderString = placeholder
        field.stringValue = initial
        field.font = NSFont.systemFont(ofSize: 13)

        let row = NSStackView(views: [lbl, field])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .firstBaseline
        lbl.widthAnchor.constraint(equalToConstant: 64).isActive = true
        return (row, field)
    }

    private static func intervalString(seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded())
        if s % 3600 == 0 { return "\(s / 3600)h" }
        if s % 60 == 0 { return "\(s / 60)m" }
        return "\(s)s"
    }
}
