import Cocoa
import ApplicationServices
import Foundation

// MARK: - Configuration
struct Config {
    var windowWidth: CGFloat = 600
    var windowHeight: CGFloat = 50
    var backgroundColor: NSColor = NSColor(hex: "#2E3440") ?? .darkGray
    var textColor: NSColor = NSColor(hex: "#ECEFF4") ?? .white
    var placeholderColor: NSColor = NSColor(hex: "#4C566A") ?? .gray
    var selectionColor: NSColor = NSColor(hex: "#5E81AC") ?? .blue
    var borderColor: NSColor = NSColor(hex: "#3B4252") ?? .gray
    var borderWidth: CGFloat = 2
    var cornerRadius: CGFloat = 8
    var fontName: String = "Menlo"
    var fontSize: CGFloat = 16
    var maxResults: Int = 10
    var caseSensitive: Bool = false
    var position: String = "center"
    
    static func load() -> Config {
        var config = Config()
        
        // XDG config locations
        let configPaths = [
            ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"].map { "\($0)/yjump/yjump.conf" },
            "\(NSHomeDirectory())/.config/yjump/yjump.conf",
            "\(NSHomeDirectory())/.yjump.conf"
        ].compactMap { $0 }
        
        for path in configPaths {
            if let contents = try? String(contentsOfFile: path, encoding: .utf8) {
                config.parse(contents)
                break
            }
        }
        
        return config
    }
    
    mutating func parse(_ contents: String) {
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            let parts = trimmed.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            
            let key = parts[0]
            let value = parts[1]
            
            switch key {
            case "window_width":
                if let val = Double(value) { windowWidth = CGFloat(val) }
            case "window_height":
                if let val = Double(value) { windowHeight = CGFloat(val) }
            case "background_color":
                if let color = NSColor(hex: value) { backgroundColor = color }
            case "text_color":
                if let color = NSColor(hex: value) { textColor = color }
            case "placeholder_color":
                if let color = NSColor(hex: value) { placeholderColor = color }
            case "selection_color":
                if let color = NSColor(hex: value) { selectionColor = color }
            case "border_color":
                if let color = NSColor(hex: value) { borderColor = color }
            case "border_width":
                if let val = Double(value) { borderWidth = CGFloat(val) }
            case "corner_radius":
                if let val = Double(value) { cornerRadius = CGFloat(val) }
            case "font_name":
                fontName = value
            case "font_size":
                if let val = Double(value) { fontSize = CGFloat(val) }
            case "max_results":
                if let val = Int(value) { maxResults = val }
            case "case_sensitive":
                caseSensitive = value.lowercased() == "true"
            case "position":
                position = value
            default:
                break
            }
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // RGBA
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Window Information
struct WindowInfo {
    let windowNumber: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let windowTitle: String
    let bounds: CGRect
    let workspace: Int
    
    var displayText: String {
        if windowTitle.isEmpty {
            return ownerName
        }
        return "\(ownerName) - \(windowTitle)"
    }
    
    var searchableText: String {
        return displayText.lowercased()
    }
}

// MARK: - Fuzzy Matching
func fuzzyMatch(_ pattern: String, _ text: String, caseSensitive: Bool = false) -> (matches: Bool, score: Int) {
    let patternToSearch = caseSensitive ? pattern : pattern.lowercased()
    let textToSearch = caseSensitive ? text : text.lowercased()
    
    if patternToSearch.isEmpty {
        return (true, 0)
    }
    
    // Simple substring matching - matches any part of the text
    if textToSearch.contains(patternToSearch) {
        // Score based on position (earlier match = higher score)
        if let range = textToSearch.range(of: patternToSearch) {
            let position = textToSearch.distance(from: textToSearch.startIndex, to: range.lowerBound)
            let score = 1000 - position
            return (true, score)
        }
    }
    
    // Fuzzy matching fallback
    var patternIndex = patternToSearch.startIndex
    var score = 0
    var consecutiveMatch = 0
    
    for (_, char) in textToSearch.enumerated() {
        if patternIndex < patternToSearch.endIndex && char == patternToSearch[patternIndex] {
            score += 1 + consecutiveMatch * 5
            consecutiveMatch += 1
            patternIndex = patternToSearch.index(after: patternIndex)
        } else {
            consecutiveMatch = 0
        }
    }
    
    let matches = patternIndex == patternToSearch.endIndex
    return (matches, matches ? score : 0)
}

// MARK: - Window Manager
class WindowManager {
    static func getAllWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return windows
        }
        
        for windowDict in windowList {
            guard let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let windowNumber = windowDict[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = windowDict[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }
            
            let ownerName = windowDict[kCGWindowOwnerName as String] as? String ?? ""
            let windowTitle = windowDict[kCGWindowName as String] as? String ?? ""
            
            // Skip windows without a name and title
            if ownerName.isEmpty && windowTitle.isEmpty {
                continue
            }
            
            // Skip system windows
            if ownerName == "Window Server" || ownerName == "Dock" {
                continue
            }
            
            let bounds = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            
            // Skip windows that are too small (likely not actual windows)
            if bounds.width < 50 || bounds.height < 50 {
                continue
            }
            
            // Note: kCGWindowWorkspace is deprecated, using 0 as default
            let workspace = 0
            
            windows.append(WindowInfo(
                windowNumber: windowNumber,
                ownerPID: ownerPID,
                ownerName: ownerName,
                windowTitle: windowTitle,
                bounds: bounds,
                workspace: workspace
            ))
        }
        
        return windows
    }
    
    static func activateWindow(_ window: WindowInfo) {
        // Get the running application for the window's owner
        let app = NSRunningApplication(processIdentifier: window.ownerPID)
        
        // Activate the application
        app?.activate()
        
        // Use AXUIElement to raise the specific window
        let appElement = AXUIElementCreateApplication(window.ownerPID)
        var windowsRef: AnyObject?
        
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result == .success, let windows = windowsRef as? [AXUIElement] {
            // Try to find and raise the specific window
            for axWindow in windows {
                var titleRef: AnyObject?
                AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
                
                if let title = titleRef as? String, title == window.windowTitle || window.windowTitle.isEmpty {
                    AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, true as CFTypeRef)
                    AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
                    break
                }
            }
        }
    }
}

// MARK: - Custom Text Field
class CustomTextField: NSTextField {
    var config: Config
    
    init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        self.setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupAppearance() {
        self.isBordered = false
        self.isBezeled = false
        self.drawsBackground = false
        self.textColor = config.textColor
        self.font = NSFont(name: config.fontName, size: config.fontSize) ?? NSFont.systemFont(ofSize: config.fontSize)
        self.focusRingType = .none
        
        // Set placeholder color
        if let placeholder = self.placeholderString {
            self.placeholderAttributedString = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: config.placeholderColor,
                    .font: self.font ?? NSFont.systemFont(ofSize: config.fontSize)
                ]
            )
        }
    }
}

// MARK: - Custom Window
class BorderedWindow: NSWindow {
    var config: Config
    
    init(config: Config, height: CGFloat) {
        self.config = config
        
        let contentRect = NSRect(x: 0, y: 0, width: config.windowWidth, height: height)
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = true
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Content View with Border
class BorderedContentView: NSView {
    var config: Config
    
    init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        guard let layer = self.layer else { return }
        
        layer.backgroundColor = config.backgroundColor.cgColor
        layer.cornerRadius = config.cornerRadius
        layer.borderWidth = config.borderWidth
        layer.borderColor = config.borderColor.cgColor
    }
}

// MARK: - UI Components
class SearchWindowController: NSWindowController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var searchField: CustomTextField!
    var tableView: NSTableView!
    var scrollView: NSScrollView!
    var containerView: BorderedContentView!
    
    var allWindows: [WindowInfo] = []
    var filteredWindows: [WindowInfo] = []
    var selectedIndex: Int = 0
    var config: Config
    
    let rowHeight: CGFloat = 30
    let maxVisibleRows: Int = 10
    let padding: CGFloat = 12
    
    init(config: Config) {
        self.config = config
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadWindow() {
        let window = BorderedWindow(config: config, height: config.windowHeight)
        self.window = window
        
        setupUI()
        loadWindows()
        positionWindow(window)
    }
    
    func positionWindow(_ window: NSWindow) {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            
            let x: CGFloat
            let y: CGFloat
            
            if config.position.contains(",") {
                let coords = config.position.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if coords.count == 2,
                   let xVal = Double(coords[0]),
                   let yVal = Double(coords[1]) {
                    x = CGFloat(xVal)
                    y = CGFloat(yVal)
                } else {
                    x = screenRect.midX - windowRect.width / 2
                    y = screenRect.midY - windowRect.height / 2
                }
            } else {
                switch config.position {
                case "top":
                    x = screenRect.midX - windowRect.width / 2
                    y = screenRect.maxY - windowRect.height - 50
                case "bottom":
                    x = screenRect.midX - windowRect.width / 2
                    y = screenRect.minY + 50
                default:
                    x = screenRect.midX - windowRect.width / 2
                    y = screenRect.midY - windowRect.height / 2
                }
            }
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func setupUI() {
        guard let window = self.window else { return }
        
        containerView = BorderedContentView(config: config)
        
        // Search field at top
        searchField = CustomTextField(config: config)
        searchField.placeholderString = "Search windows..."
        searchField.delegate = self
        searchField.frame = NSRect(
            x: padding,
            y: window.frame.height - config.windowHeight + padding,
            width: config.windowWidth - (padding * 2),
            height: config.windowHeight - (padding * 2)
        )
        
        // Table view for results
        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        tableView.rowHeight = rowHeight
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.focusRingType = .none
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WindowColumn"))
        column.width = config.windowWidth - (padding * 2)
        tableView.addTableColumn(column)
        
        // Scroll view
        scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.frame = NSRect(
            x: padding,
            y: padding,
            width: config.windowWidth - (padding * 2),
            height: 0
        )
        
        containerView.addSubview(searchField)
        containerView.addSubview(scrollView)
        
        window.contentView = containerView
        
        // Initial focus
        DispatchQueue.main.async {
            window.makeFirstResponder(self.searchField)
        }
    }
    
    func loadWindows() {
        allWindows = WindowManager.getAllWindows()
        filteredWindows = []
        updateWindowSize()
    }
    
    func updateWindowSize() {
        guard let window = self.window else { return }
        
        let visibleRowCount = min(filteredWindows.count, maxVisibleRows)
        let listHeight = CGFloat(visibleRowCount) * rowHeight
        
        let newHeight = config.windowHeight + listHeight + (filteredWindows.isEmpty ? 0 : padding)
        
        var frame = window.frame
        let oldHeight = frame.height
        frame.size.height = newHeight
        frame.origin.y += (oldHeight - newHeight)
        
        window.setFrame(frame, display: true, animate: false)
        
        // Update scroll view frame
        scrollView.frame = NSRect(
            x: padding,
            y: padding,
            width: config.windowWidth - (padding * 2),
            height: listHeight
        )
        
        // Update search field frame
        searchField.frame = NSRect(
            x: padding,
            y: newHeight - config.windowHeight + padding,
            width: config.windowWidth - (padding * 2),
            height: config.windowHeight - (padding * 2)
        )
    }
    
    // MARK: - NSTextFieldDelegate
    func controlTextDidChange(_ obj: Notification) {
        filterWindows()
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)):
            if selectedIndex < filteredWindows.count - 1 {
                selectedIndex += 1
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(selectedIndex)
            }
            return true
        case #selector(NSResponder.moveUp(_:)):
            if selectedIndex > 0 {
                selectedIndex -= 1
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(selectedIndex)
            }
            return true
        case #selector(NSResponder.insertNewline(_:)):
            activateSelectedWindow()
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            NSApplication.shared.terminate(nil)
            return true
        default:
            return false
        }
    }
    
    func filterWindows() {
        let searchText = searchField.stringValue
        
        if searchText.isEmpty {
            filteredWindows = []
        } else {
            var scoredWindows: [(window: WindowInfo, score: Int)] = []
            
            for window in allWindows {
                let result = fuzzyMatch(searchText, window.displayText, caseSensitive: config.caseSensitive)
                if result.matches {
                    scoredWindows.append((window, result.score))
                }
            }
            
            scoredWindows.sort { $0.score > $1.score }
            filteredWindows = Array(scoredWindows.prefix(config.maxResults).map { $0.window })
        }
        
        selectedIndex = 0
        tableView.reloadData()
        updateWindowSize()
        
        if !filteredWindows.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    func activateSelectedWindow() {
        guard selectedIndex >= 0 && selectedIndex < filteredWindows.count else {
            NSApplication.shared.terminate(nil)
            return
        }
        
        let window = filteredWindows[selectedIndex]
        WindowManager.activateWindow(window)
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredWindows.count
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("WindowCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        
        if cell == nil {
            cell = NSTableCellView()
            let textField = NSTextField()
            textField.isBordered = false
            textField.isEditable = false
            textField.backgroundColor = .clear
            textField.textColor = config.textColor
            textField.font = NSFont(name: config.fontName, size: config.fontSize - 2) ?? NSFont.systemFont(ofSize: config.fontSize - 2)
            textField.lineBreakMode = .byTruncatingTail
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -8),
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
            
            cell?.identifier = identifier
        }
        
        cell?.textField?.stringValue = filteredWindows[row].displayText
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        selectedIndex = row
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedIndex = tableView.selectedRow
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.selectionHighlightStyle = .regular
        return rowView
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: SearchWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "yjump needs accessibility permissions to switch windows. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
        // Load config
        let config = Config.load()
        
        windowController = SearchWindowController(config: config)
        windowController?.loadWindow()
        windowController?.window?.makeKeyAndOrderFront(nil)
        
        // Ensure window gets focus
        NSApp.activate(ignoringOtherApps: true)
        windowController?.window?.makeKey()
        windowController?.window?.orderFrontRegardless()
        windowController?.window?.makeFirstResponder(windowController?.searchField)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Main
let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Don't show in Dock
let delegate = AppDelegate()
app.delegate = delegate
app.run()
