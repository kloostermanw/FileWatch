//
//  ViewController.swift
//  FileWatch
//
//  Created by Wiebe Kloosterman on 27/03/2021.
//

import Cocoa

// MARK: - Light/dark-aware colors

/// Popover chrome colors that resolve per appearance. macOS provides the popover's
/// translucent material; these are the subtle fills layered on top of it.
private enum SettingsPalette {
    static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
    }
    static let cardBG      = dynamic(light: NSColor(white: 0, alpha: 0.03), dark: NSColor(white: 1, alpha: 0.05))
    static let fieldBG     = dynamic(light: NSColor(white: 1, alpha: 0.90), dark: NSColor(white: 1, alpha: 0.06))
    static let divider     = dynamic(light: NSColor(white: 0, alpha: 0.09), dark: NSColor(white: 1, alpha: 0.10))
    static let rowHover    = dynamic(light: NSColor(white: 0, alpha: 0.05), dark: NSColor(white: 1, alpha: 0.06))
    static let badgeBG     = dynamic(light: NSColor(white: 0, alpha: 0.06), dark: NSColor(white: 1, alpha: 0.09))
    static let fieldBorder = dynamic(light: NSColor(white: 0, alpha: 0.13), dark: NSColor(white: 1, alpha: 0.13))
}

/// Resolves a (possibly dynamic) color to a `CGColor` for a specific appearance —
/// `CALayer` colors don't auto-adapt to light/dark the way `NSColor` drawing does.
private func resolvedCGColor(_ color: NSColor, _ appearance: NSAppearance) -> CGColor {
    let saved = NSAppearance.current
    NSAppearance.current = appearance
    defer { NSAppearance.current = saved }
    return color.cgColor
}

// MARK: - Reusable views

/// A button that tints on hover — used for the row delete control so it stays quiet
/// until the pointer is over it, then turns red.
final class HoverTintButton: NSButton {
    var normalTint: NSColor = .tertiaryLabelColor { didSet { if !hovering { contentTintColor = normalTint } } }
    var hoverTint: NSColor = .systemRed
    private var hovering = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero,
                                       options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                                       owner: self))
    }
    override func mouseEntered(with event: NSEvent) { hovering = true; contentTintColor = hoverTint }
    override func mouseExited(with event: NSEvent)  { hovering = false; contentTintColor = normalTint }
}

/// A rounded activity badge. Grey at zero / paused, accent-tinted when there is activity.
final class PillView: NSView {
    private let label = NSTextField(labelWithString: "")
    private var active = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 9
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    required init?(coder: NSCoder) { fatalError("not supported") }

    func configure(text: String, active: Bool) {
        label.stringValue = text
        self.active = active
        applyColors()
    }
    private func applyColors() {
        let bg = active ? NSColor.controlAccentColor.withAlphaComponent(0.20) : SettingsPalette.badgeBG
        layer?.backgroundColor = resolvedCGColor(bg, effectiveAppearance)
        label.textColor = active ? .controlAccentColor : .secondaryLabelColor
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyColors()
    }
}

/// One folder in the watch list: enable checkbox, folder glyph, name + full path,
/// activity pill, and a hover-revealed delete button.
final class DirectoryRowView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("DirectoryRowView")

    let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    let folderIcon = NSImageView()
    let nameLabel = NSTextField(labelWithString: "")
    let pathLabel = NSTextField(labelWithString: "")
    let pill = PillView()
    let trash = HoverTintButton()
    private let topDivider = NSBox()
    private var hovering = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        folderIcon.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        folderIcon.contentTintColor = .controlAccentColor
        folderIcon.imageScaling = .scaleProportionallyUpOrDown

        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.textColor = .labelColor

        pathLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        pathLabel.textColor = .tertiaryLabelColor
        pathLabel.lineBreakMode = .byTruncatingHead   // keep the meaningful tail visible

        trash.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Remove")
        trash.imagePosition = .imageOnly
        trash.isBordered = false
        trash.contentTintColor = .tertiaryLabelColor
        trash.alphaValue = 0.55

        topDivider.boxType = .custom
        topDivider.borderWidth = 0
        topDivider.fillColor = SettingsPalette.divider
        topDivider.translatesAutoresizingMaskIntoConstraints = false

        let textStack = NSStackView(views: [nameLabel, pathLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 1
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        pathLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let rowStack = NSStackView(views: [checkbox, folderIcon, textStack, pill, trash])
        rowStack.orientation = .horizontal
        rowStack.alignment = .centerY
        rowStack.spacing = 10
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        for pinned in [checkbox, folderIcon, pill, trash] {
            pinned.setContentHuggingPriority(.required, for: .horizontal)
            pinned.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        addSubview(rowStack)
        addSubview(topDivider)
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 11),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            rowStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            folderIcon.widthAnchor.constraint(equalToConstant: 17),
            folderIcon.heightAnchor.constraint(equalToConstant: 17),
            trash.widthAnchor.constraint(equalToConstant: 24),
            trash.heightAnchor.constraint(equalToConstant: 24),

            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: 1),
        ])
    }
    required init?(coder: NSCoder) { fatalError("not supported") }

    func configure(dict: [String: String], showTopDivider: Bool) {
        let path = dict["directory"] ?? ""
        nameLabel.stringValue = Self.displayName(for: path)
        pathLabel.stringValue = Self.tildePath(path)

        let enabled = dict["enable"] == "1"
        checkbox.state = enabled ? .on : .off

        let count = Int(dict["count"] ?? "0") ?? 0
        pill.configure(text: enabled ? "\(count)" : "—", active: enabled && count > 0)

        nameLabel.alphaValue = enabled ? 1 : 0.45
        folderIcon.alphaValue = enabled ? 1 : 0.45
        topDivider.isHidden = !showTopDivider
    }

    /// Best-effort human name for a watched path: the repo folder if the path lives
    /// under a `repos/` dir, otherwise the last segment that isn't a generic container.
    static func displayName(for path: String) -> String {
        let comps = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        guard !comps.isEmpty else { return path }
        if let i = comps.firstIndex(of: "repos"), i + 1 < comps.count { return comps[i + 1] }
        let generic: Set<String> = ["src", "logs", "log", "storage", "public", "app",
                                     "application", "var", "www", "vhosts"]
        return comps.reversed().first { !generic.contains($0.lowercased()) } ?? comps.last ?? path
    }

    static func tildePath(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }

    // Subtle hover background + reveal the delete button.
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero,
                                       options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                                       owner: self))
    }
    override func mouseEntered(with event: NSEvent) { setHover(true) }
    override func mouseExited(with event: NSEvent)  { setHover(false) }
    private func setHover(_ on: Bool) {
        hovering = on
        trash.animator().alphaValue = on ? 1 : 0.55
        applyHoverColor()
    }
    private func applyHoverColor() {
        layer?.backgroundColor = resolvedCGColor(hovering ? SettingsPalette.rowHover : .clear, effectiveAppearance)
    }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        topDivider.fillColor = SettingsPalette.divider
        applyHoverColor()
    }
}

/// Root view that forwards light/dark switches to the controller so layer-backed
/// chrome can be re-tinted (`NSViewController` has no appearance-change hook).
final class AppearanceForwardingView: NSView {
    var onAppearanceChange: (() -> Void)?
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}

// MARK: - Controller

class ViewController: NSViewController {

    let objUserDefaults = UserDefaults(suiteName: "FileWatch.kloosterman.eu")
    var arrDirectory: [[String: String]] = [["directory": "/tmp", "count": "0", "enable": "1", "local": "/", "remote": "/"]]

    var selectedRow = 0

    /// Set by `AppDelegate.showSettings` so Cancel / Save can close the popover.
    weak var popover: NSPopover?

    private let rowHeight: CGFloat = 48
    private let contentWidth: CGFloat = 396

    private let directoryTableView = NSTableView()
    private let summaryLabel = NSTextField(labelWithString: "")
    private let remoteField = NSTextField(string: "")
    private let localField = NSTextField(string: "")

    private var listCard: NSView!
    private var listHeight: NSLayoutConstraint!
    private var styledBoxes: [NSView] = []   // layer-backed views to re-tint on appearance change

    // MARK: View construction

    override func loadView() {
        let root = AppearanceForwardingView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 400))
        root.onAppearanceChange = { [weak self] in self?.restyleBoxes() }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            root.widthAnchor.constraint(equalToConstant: contentWidth),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -12),
        ])

        func fullWidth(_ v: NSView) { v.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }

        // Header: "Monitored folders" + summary
        summaryLabel.font = .systemFont(ofSize: 11, weight: .medium)
        summaryLabel.textColor = .tertiaryLabelColor
        summaryLabel.alignment = .right
        let header = NSStackView(views: [caption("Monitored folders"), spacer(), summaryLabel])
        header.orientation = .horizontal
        header.alignment = .firstBaseline
        stack.addArrangedSubview(header)
        fullWidth(header)

        // Folder list card
        listCard = makeListCard()
        stack.addArrangedSubview(listCard)
        fullWidth(listCard)
        listHeight = listCard.heightAnchor.constraint(equalToConstant: rowHeight)
        listHeight.isActive = true

        // Add button
        let add = NSButton(title: "Add folder to monitor…",
                           image: NSImage(systemSymbolName: "plus", accessibilityDescription: nil) ?? NSImage(),
                           target: self, action: #selector(addDirectory))
        add.imagePosition = .imageLeading
        add.bezelStyle = .rounded
        stack.addArrangedSubview(add)
        fullWidth(add)

        // Mapping section
        let mappingDivider = hairline()
        stack.addArrangedSubview(mappingDivider)
        fullWidth(mappingDivider)

        stack.addArrangedSubview(caption("Path mapping"))

        let help = NSTextField(wrappingLabelWithString:
            "Log messages reference paths on the remote server. FileWatch rewrites the remote prefix to your local checkout so file links open on your Mac.")
        help.font = .systemFont(ofSize: 11)
        help.textColor = .secondaryLabelColor
        stack.addArrangedSubview(help)
        fullWidth(help)

        let remoteGroup = mappingField(label: "Remote path prefix", tag: "from", field: remoteField)
        stack.addArrangedSubview(remoteGroup)
        fullWidth(remoteGroup)

        let localGroup = mappingField(label: "Local path prefix", tag: "to", field: localField)
        stack.addArrangedSubview(localGroup)
        fullWidth(localGroup)

        // Footer
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancel.bezelStyle = .rounded
        let save = NSButton(title: "Save mapping", target: self, action: #selector(saveMapping))
        save.bezelStyle = .rounded
        save.keyEquivalent = "\r"   // default (accent) button
        let footer = NSStackView(views: [spacer(), cancel, save])
        footer.orientation = .horizontal
        footer.spacing = 9
        stack.addArrangedSubview(footer)
        fullWidth(footer)

        self.view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let stored = objUserDefaults?.value(forKey: "directory") as? [[String: String]] {
            arrDirectory = stored
        }

        directoryTableView.reloadData()
        refreshList()

        if !arrDirectory.isEmpty {
            directoryTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
        loadMapping(for: selectedRow)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        restyleBoxes()
    }

    // MARK: Builders

    private func caption(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text.uppercased())
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .tertiaryLabelColor
        return l
    }

    private func spacer() -> NSView {
        let v = NSView()
        v.setContentHuggingPriority(.init(1), for: .horizontal)
        v.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        return v
    }

    private func hairline() -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.borderWidth = 0
        box.fillColor = SettingsPalette.divider
        box.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return box
    }

    private func makeListCard() -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 9
        card.layer?.borderWidth = 0.5
        card.layer?.masksToBounds = true
        styledBoxes.append(card)

        directoryTableView.headerView = nil
        directoryTableView.backgroundColor = .clear
        directoryTableView.rowHeight = rowHeight
        directoryTableView.intercellSpacing = .zero
        directoryTableView.gridStyleMask = []
        directoryTableView.selectionHighlightStyle = .regular
        directoryTableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        directoryTableView.delegate = self
        directoryTableView.dataSource = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        column.resizingMask = .autoresizingMask
        directoryTableView.addTableColumn(column)

        let scroll = NSScrollView()
        scroll.documentView = directoryTableView
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: card.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),
        ])
        return card
    }

    private func mappingField(label: String, tag: String, field: NSTextField) -> NSView {
        let labelCell = NSTextField(labelWithString: label)
        labelCell.font = .systemFont(ofSize: 11, weight: .semibold)
        labelCell.textColor = .secondaryLabelColor

        let tagCell = NSTextField(labelWithString: tag.uppercased())
        tagCell.font = .systemFont(ofSize: 10, weight: .bold)
        tagCell.textColor = .tertiaryLabelColor
        tagCell.setContentHuggingPriority(.required, for: .horizontal)

        field.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.lineBreakMode = .byTruncatingHead
        field.cell?.isScrollable = true

        let inner = NSStackView(views: [tagCell, field])
        inner.orientation = .horizontal
        inner.alignment = .centerY
        inner.spacing = 7
        inner.translatesAutoresizingMaskIntoConstraints = false

        let box = NSView()
        box.wantsLayer = true
        box.layer?.cornerRadius = 7
        box.layer?.borderWidth = 0.5
        styledBoxes.append(box)
        box.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: box.topAnchor, constant: 7),
            inner.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -7),
            inner.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 10),
            inner.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -10),
        ])

        let group = NSStackView(views: [labelCell, box])
        group.orientation = .vertical
        group.alignment = .leading
        group.spacing = 5
        box.widthAnchor.constraint(equalTo: group.widthAnchor).isActive = true
        return group
    }

    private func restyleBoxes() {
        let appearance = view.effectiveAppearance
        for box in styledBoxes {
            box.layer?.borderColor = resolvedCGColor(SettingsPalette.fieldBorder, appearance)
            let fill = box === listCard ? SettingsPalette.cardBG : SettingsPalette.fieldBG
            box.layer?.backgroundColor = resolvedCGColor(fill, appearance)
        }
    }

    // MARK: State

    private func persist() {
        objUserDefaults?.setValue(arrDirectory, forKey: "directory")
    }

    /// Reloads the table, refreshes the summary, and sizes the list card.
    private func refreshList() {
        directoryTableView.reloadData()
        let active = arrDirectory.filter { $0["enable"] == "1" }.count
        let folderWord = arrDirectory.count == 1 ? "folder" : "folders"
        summaryLabel.stringValue = "\(arrDirectory.count) \(folderWord) · \(active) active"
        let visibleRows = max(1, min(arrDirectory.count, 6))
        listHeight.constant = CGFloat(visibleRows) * rowHeight
    }

    private func loadMapping(for row: Int) {
        guard row >= 0 && row < arrDirectory.count else {
            remoteField.stringValue = ""
            localField.stringValue = ""
            return
        }
        remoteField.stringValue = arrDirectory[row]["remote"] ?? ""
        localField.stringValue = arrDirectory[row]["local"] ?? ""
    }

    /// Restarts directory monitoring with the current set of enabled paths.
    private func restartMonitoring() {
        var monitor = DirectoryMonitor.shared
        monitor.setPaths()
        monitor.stop()
        monitor.start()
    }

    private func closePopover() {
        if let popover { popover.performClose(nil) } else { view.window?.performClose(nil) }
    }

    // MARK: Actions

    @objc func addDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        panel.message = "Choose a folder to monitor"

        // FileWatch is an `LSUIElement` agent app, so bring it forward before the
        // modal — otherwise the open panel isn't reliably key and folder selection
        // (and the Open button) behave erratically. Same reason as UpdateAlertPresenter.
        NSApp.activate(ignoringOtherApps: true)

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // Watching a broad folder (/, /Users, home, ~/Library, system dirs) means
        // watching a huge, constantly-changing subtree — a notification firehose.
        // Warn before accepting one.
        if Self.isBroadPath(url.path), !confirmBroadPath(url.path) { return }

        arrDirectory.append([
            "directory": url.path,
            "count": "0",
            "enable": "1",
            "local": "/",
            "remote": "/",
        ])
        persist()
        refreshList()
        restartMonitoring()

        let newRow = arrDirectory.count - 1
        directoryTableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
    }

    /// True for folders whose subtree is huge and churns constantly, so monitoring
    /// them floods the user with notifications: `/`, any ancestor of the home folder
    /// (`/Users`), the home folder itself, `~/Library`, and common system roots.
    static func isBroadPath(_ rawPath: String) -> Bool {
        var path = rawPath
        while path.count > 1 && path.hasSuffix("/") { path.removeLast() }

        let home = NSHomeDirectory()
        if path == home || path == home + "/Library" { return true }
        // Ancestor of the home folder catches "/" and "/Users".
        if (home + "/").hasPrefix(path + "/") { return true }

        let systemRoots: Set<String> = [
            "/", "/Users", "/Library", "/System", "/Applications", "/Volumes",
            "/private", "/usr", "/etc", "/var", "/opt", "/bin", "/sbin", "/cores",
        ]
        return systemRoots.contains(path)
    }

    /// Returns true if the user chose to add the broad folder anyway.
    private func confirmBroadPath(_ path: String) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Monitor this entire folder?"
        alert.informativeText = """
            \(path) can contain a huge number of files that change constantly \
            (caches, app state, and more). Watching it will flood you with \
            notifications. Choose a specific folder — such as a logs directory — instead.
            """
        alert.addButton(withTitle: "Cancel")       // default (safe)
        alert.addButton(withTitle: "Add Anyway")
        return alert.runModal() == .alertSecondButtonReturn
    }

    @objc func saveMapping() {
        guard selectedRow >= 0 && selectedRow < arrDirectory.count else { return }
        arrDirectory[selectedRow]["local"] = localField.stringValue
        arrDirectory[selectedRow]["remote"] = remoteField.stringValue
        persist()
        closePopover()
    }

    @objc func cancel() {
        closePopover()
    }

    @objc func deleteRow(_ sender: NSButton) {
        let row = directoryTableView.row(for: sender)
        guard row >= 0 && row < arrDirectory.count else { return }
        arrDirectory.remove(at: row)
        persist()
        refreshList()
        restartMonitoring()
    }

    @objc func toggleEnabled(_ sender: NSButton) {
        let row = directoryTableView.row(for: sender)
        guard row >= 0 && row < arrDirectory.count else { return }
        arrDirectory[row]["enable"] = sender.state == .on ? "1" : "0"
        persist()
        refreshList()
        restartMonitoring()
    }
}

// MARK: - Table data source / delegate

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        arrDirectory.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: DirectoryRowView.identifier, owner: self) as? DirectoryRowView
            ?? {
                let v = DirectoryRowView()
                v.identifier = DirectoryRowView.identifier
                return v
            }()
        cell.configure(dict: arrDirectory[row], showTopDivider: row > 0)
        cell.checkbox.target = self
        cell.checkbox.action = #selector(toggleEnabled(_:))
        cell.trash.target = self
        cell.trash.action = #selector(deleteRow(_:))
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedRow = directoryTableView.selectedRow
        loadMapping(for: selectedRow)
    }
}
