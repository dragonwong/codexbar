import AppKit

struct Window: Decodable {
    let usedPercent: Double?
    let windowDurationMins: Int?
    let resetsAt: Double?
    var remaining: Int? { usedPercent.flatMap { $0.isFinite ? Int(max(0, min(100, 100 - $0)).rounded()) : nil } }
}
struct Snapshot: Decodable {
    let windows: [Window]?
    let fetchedAt: Double?
    let error: String?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    var windows: [Window] = []
    var lastUpdate: Date?
    var error: String?
    var fetching = false
    var timers: [Timer] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // Left click intentionally has no action. Right click offers maintenance only.
        item.button?.target = self
        item.button?.action = #selector(click)
        item.button?.sendAction(on: [.rightMouseUp])
        render()
        refresh()
        timers.append(Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() })
        timers.append(Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in self?.render() })
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wake), name: NSWorkspace.didWakeNotification, object: nil)
    }
    @objc func wake() { refresh() }
    @objc func click() {
        guard NSApp.currentEvent?.type == .rightMouseUp else { return }
        let menu = NSMenu()
        for (title, action) in [(L10n.text("refresh"), #selector(manualRefresh)), (L10n.text("quit"), #selector(quit))] {
            let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
            entry.target = self
            menu.addItem(entry)
        }
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }
    @objc func manualRefresh() { refresh() }
    @objc func quit() { NSApp.terminate(nil) }

    func refresh() {
        guard !fetching else { return }
        fetching = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            process.executableURL = Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("UsageReader")
            var environment = ProcessInfo.processInfo.environment
            environment["CODEXBAR_LANGUAGE"] = L10n.language
            process.environment = environment
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            var result: Snapshot?
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                result = try JSONDecoder().decode(Snapshot.self, from: data)
            } catch { }
            let snapshot = result
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.fetching = false
                if let snapshot = snapshot, snapshot.error == nil, let windows = snapshot.windows, !windows.isEmpty {
                    self.windows = windows
                    self.lastUpdate = Date()
                    self.error = nil
                } else {
                    self.error = snapshot?.error ?? L10n.text("no_quota")
                }
                self.render()
            }
        }
    }
    func resetText(_ window: Window, now: Date) -> String {
        guard let timestamp = window.resetsAt else { return "--" }
        let minutes = Int(ceil((timestamp - now.timeIntervalSince1970) / 60))
        if minutes <= 0 { return L10n.text("awaiting_update") }
        if window.windowDurationMins == 300 {
            return minutes < 60 ? "\(minutes)m" : "\(minutes / 60)h\(minutes % 60)m"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
    func render() {
        let now = Date()
        let short = windows.first { $0.windowDurationMins == 300 }
        let weekly = windows.first { $0.windowDurationMins == 10080 }
        func label(_ name: String, _ window: Window?) -> String {
            guard let window = window else { return "\(name) --" }
            let value = window.remaining.map { "\($0)%" } ?? "--"
            return "\(name) \(value) · \(resetText(window, now: now))"
        }
        let stale = error != nil || lastUpdate.map { now.timeIntervalSince($0) > 180 } != false
        item.button?.title = " " + label("5h", short) + " / " + label(L10n.text("weekly"), weekly) + (stale && !windows.isEmpty ? " ↻" : "")
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        item.button?.image = gauge(stale ? nil : short?.remaining)
        item.button?.imagePosition = .imageLeading
        item.button?.toolTip = error ?? (lastUpdate == nil ? L10n.text("loading") : L10n.text("tooltip"))
        item.button?.setAccessibilityLabel(L10n.text("accessibility") + (item.button?.title ?? ""))
    }
    func gauge(_ remaining: Int?) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            let color: NSColor
            if let value = remaining { color = value > 50 ? .systemGreen : value >= 20 ? .systemOrange : .systemRed }
            else { color = .systemGray }
            color.setStroke()
            color.setFill()
            let arc = NSBezierPath()
            arc.appendArc(withCenter: NSPoint(x: 10, y: 8), radius: 7.5, startAngle: 180, endAngle: 0, clockwise: true)
            arc.lineWidth = 2
            arc.lineCapStyle = .round
            arc.stroke()
            if let value = remaining {
                let angle = Double(180) * (1 - Double(value) / 100) * .pi / 180
                let needle = NSBezierPath()
                needle.move(to: NSPoint(x: 10, y: 8))
                needle.line(to: NSPoint(x: 10 + cos(angle) * 5.5, y: 8 + sin(angle) * 5.5))
                needle.lineWidth = 1.8
                needle.lineCapStyle = .round
                needle.stroke()
            }
            NSBezierPath(ovalIn: NSRect(x: 8.5, y: 6.5, width: 3, height: 3)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }
}
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
