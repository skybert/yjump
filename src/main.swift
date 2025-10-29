import Cocoa
import ApplicationServices
import Foundation

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
        return "\(ownerName): \(windowTitle)"
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
    private static var cachedWindows: [WindowInfo]?
    private static var cacheTimestamp: Date?
    private static var cacheTimeout: TimeInterval = 2.0
    
    static func setCacheTimeout(_ timeout: TimeInterval) {
        cacheTimeout = timeout
    }
    
    static func getAllWindows(useCache: Bool = true) -> [WindowInfo] {
        // Check cache if enabled
        if useCache, let cached = cachedWindows, let timestamp = cacheTimestamp {
            let elapsed = Date().timeIntervalSince(timestamp)
            if elapsed < cacheTimeout {
                return cached
            }
        }
        
        var windows: [WindowInfo] = []
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return windows
        }
        
        // Group windows by PID for batch AX lookups
        var windowsByPID: [pid_t: [(dict: [String: Any], number: CGWindowID, bounds: CGRect, name: String)]] = [:]
        
        for windowDict in windowList {
            guard let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let windowNumber = windowDict[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = windowDict[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }
            
            let ownerName = windowDict[kCGWindowOwnerName as String] as? String ?? ""
            
            if ownerName.isEmpty || ownerName == "Window Server" || ownerName == "Dock" {
                continue
            }
            
            let bounds = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            
            if bounds.width < 50 || bounds.height < 50 {
                continue
            }
            
            if windowsByPID[ownerPID] == nil {
                windowsByPID[ownerPID] = []
            }
            windowsByPID[ownerPID]?.append((windowDict, windowNumber, bounds, ownerName))
        }
        
        // Process each app's windows
        for (pid, pidWindows) in windowsByPID {
            let ownerName = pidWindows[0].name
            let skipAXLookup = ["Google Chrome", "Safari", "Arc", "Microsoft Edge"]
            
            // Get all AX windows for this app at once
            var axWindowTitles: [CGRect: String] = [:]
            if !skipAXLookup.contains(ownerName) {
                if let axWindows = getAXWindowsForPID(pid: pid) {
                    for (_, title, bounds) in axWindows {
                        axWindowTitles[bounds] = title
                    }
                }
            }
            
            // Match each CG window with AX title
            for (windowDict, windowNumber, cgBounds, _) in pidWindows {
                var windowTitle = windowDict[kCGWindowName as String] as? String ?? ""
                
                // Try to find matching AX window if no title
                if windowTitle.isEmpty && !axWindowTitles.isEmpty {
                    var bestMatch: (title: String, distance: CGFloat, bounds: CGRect)?
                    
                    for (axBounds, title) in axWindowTitles {
                        let distance = boundsDistance(cgBounds, axBounds)
                        if distance < 100 { // Increased tolerance
                            if bestMatch == nil || distance < bestMatch!.distance {
                                bestMatch = (title, distance, axBounds)
                            }
                        }
                    }
                    
                    if let match = bestMatch {
                        windowTitle = match.title
                        // Remove the matched AX window so it won't be reused
                        axWindowTitles.removeValue(forKey: match.bounds)
                    }
                }
                
                windows.append(WindowInfo(
                    windowNumber: windowNumber,
                    ownerPID: pid,
                    ownerName: ownerName,
                    windowTitle: windowTitle,
                    bounds: cgBounds,
                    workspace: 0
                ))
            }
        }
        
        // Update cache
        if useCache {
            cachedWindows = windows
            cacheTimestamp = Date()
        }
        
        return windows
    }
    
    static func boundsDistance(_ b1: CGRect, _ b2: CGRect) -> CGFloat {
        return abs(b1.origin.x - b2.origin.x) + abs(b1.origin.y - b2.origin.y) +
               abs(b1.width - b2.width) + abs(b1.height - b2.height)
    }
    
    static func getAXWindowsForPID(pid: pid_t) -> [(element: AXUIElement, title: String, bounds: CGRect)]? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: AnyObject?
        
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return nil
        }
        
        var result: [(AXUIElement, String, CGRect)] = []
        
        for axWindow in windows {
            var titleRef: AnyObject?
            var posRef: AnyObject?
            var sizeRef: AnyObject?
            
            guard AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef) == .success,
                  let title = titleRef as? String, !title.isEmpty,
                  AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posRef) == .success,
                  AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef) == .success,
                  let posValue = posRef as CFTypeRef?, let sizeValue = sizeRef as CFTypeRef? else {
                continue
            }
            
            var point = CGPoint.zero
            var size = CGSize.zero
            
            if AXValueGetValue(posValue as! AXValue, .cgPoint, &point),
               AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) {
                result.append((axWindow, title, CGRect(origin: point, size: size)))
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    static func invalidateCache() {
        cachedWindows = nil
        cacheTimestamp = nil
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
    
    init(config: Config) {
        self.config = config
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadWindow() {
        // Start with just input box height
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
            x: config.inputPadding,
            y: window.frame.height - config.windowHeight + config.inputPadding,
            width: config.windowWidth - (config.inputPadding * 2),
            height: config.windowHeight - (config.inputPadding * 2)
        )
        
        // Table view for results
        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        tableView.rowHeight = config.listRowHeight
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.focusRingType = .none
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WindowColumn"))
        column.width = config.windowWidth - (config.inputPadding * 2)
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
            x: config.inputPadding,
            y: config.inputPadding,
            width: config.windowWidth - (config.inputPadding * 2),
            height: 0
        )
        
        containerView.addSubview(scrollView)
        containerView.addSubview(searchField)
        
        window.contentView = containerView
        
        // Initial focus
        DispatchQueue.main.async {
            window.makeFirstResponder(self.searchField)
        }
    }
    
    func loadWindows() {
        // Configure cache settings
        WindowManager.setCacheTimeout(config.cacheTimeoutSeconds)
        
        // Load windows (will use cache if enabled)
        allWindows = WindowManager.getAllWindows(useCache: config.cacheWindowList)
        filteredWindows = []
    }
    
    func updateWindowSize() {
        guard let window = self.window else { return }
        
        let hasResults = !filteredWindows.isEmpty
        let listHeight = hasResults ? config.maxListHeight : 0
        let spacing: CGFloat = hasResults ? config.inputPadding : 0
        
        let newHeight = config.windowHeight + listHeight + spacing
        
        var frame = window.frame
        let oldHeight = frame.height
        frame.size.height = newHeight
        frame.origin.y += (oldHeight - newHeight)
        
        window.setFrame(frame, display: true, animate: false)
        
        // Update scroll view frame
        scrollView.frame = NSRect(
            x: config.inputPadding,
            y: config.inputPadding,
            width: config.windowWidth - (config.inputPadding * 2),
            height: listHeight
        )
        
        // Update search field frame
        searchField.frame = NSRect(
            x: config.inputPadding,
            y: newHeight - config.windowHeight + config.inputPadding,
            width: config.windowWidth - (config.inputPadding * 2),
            height: config.windowHeight - (config.inputPadding * 2)
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
            textField.font = NSFont(name: config.fontName, size: config.fontSize - 1) ?? NSFont.systemFont(ofSize: config.fontSize - 1)
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
        // Parse CLI arguments first
        if CLI.parse() {
            // CLI handled the request (--help or --version), exit
            exit(0)
        }
        
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
