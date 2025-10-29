import Cocoa
import ApplicationServices

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
}

// MARK: - Fuzzy Matching
func fuzzyMatch(_ pattern: String, _ text: String) -> (matches: Bool, score: Int) {
    let patternLower = pattern.lowercased()
    let textLower = text.lowercased()
    
    if patternLower.isEmpty {
        return (true, 0)
    }
    
    var patternIndex = patternLower.startIndex
    var score = 0
    var consecutiveMatch = 0
    
    for (_, char) in textLower.enumerated() {
        if patternIndex < patternLower.endIndex && char == patternLower[patternIndex] {
            score += 1 + consecutiveMatch * 5
            consecutiveMatch += 1
            patternIndex = patternLower.index(after: patternIndex)
        } else {
            consecutiveMatch = 0
        }
    }
    
    let matches = patternIndex == patternLower.endIndex
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

// MARK: - UI Components
class SearchWindowController: NSWindowController, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    var searchField: NSTextField!
    var tableView: NSTableView!
    var scrollView: NSScrollView!
    
    var allWindows: [WindowInfo] = []
    var filteredWindows: [WindowInfo] = []
    var selectedIndex = 0
    
    override func loadWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "yjump"
        window.center()
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.window = window
        
        setupUI()
        loadWindows()
    }
    
    func setupUI() {
        guard let window = self.window else { return }
        
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        
        // Search field
        searchField = NSTextField(frame: NSRect(x: 20, y: window.contentView!.bounds.height - 50, width: window.contentView!.bounds.width - 40, height: 30))
        searchField.autoresizingMask = [.width, .minYMargin]
        searchField.placeholderString = "Type to search windows..."
        searchField.delegate = self
        searchField.focusRingType = .none
        contentView.addSubview(searchField)
        
        // Table view
        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.focusRingType = .none
        tableView.target = self
        tableView.doubleAction = #selector(activateSelectedWindow)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("WindowColumn"))
        column.width = 560
        tableView.addTableColumn(column)
        
        // Scroll view
        scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: window.contentView!.bounds.width - 40, height: window.contentView!.bounds.height - 90))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        contentView.addSubview(scrollView)
        
        window.contentView = contentView
        window.makeFirstResponder(searchField)
    }
    
    func loadWindows() {
        allWindows = WindowManager.getAllWindows()
        filteredWindows = allWindows
        tableView.reloadData()
    }
    
    // MARK: - NSTextFieldDelegate
    func controlTextDidChange(_ obj: Notification) {
        filterWindows()
    }
    
    override func keyDown(with event: NSEvent) {
        guard self.window != nil else { return }
        
        switch event.keyCode {
        case 125: // Down arrow
            if selectedIndex < filteredWindows.count - 1 {
                selectedIndex += 1
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(selectedIndex)
            }
        case 126: // Up arrow
            if selectedIndex > 0 {
                selectedIndex -= 1
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(selectedIndex)
            }
        case 36: // Return
            activateSelectedWindow()
        case 53: // Escape
            NSApplication.shared.terminate(nil)
        default:
            super.keyDown(with: event)
        }
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
            filteredWindows = allWindows
        } else {
            var scoredWindows: [(window: WindowInfo, score: Int)] = []
            
            for window in allWindows {
                let result = fuzzyMatch(searchText, window.displayText)
                if result.matches {
                    scoredWindows.append((window, result.score))
                }
            }
            
            scoredWindows.sort { $0.score > $1.score }
            filteredWindows = scoredWindows.map { $0.window }
        }
        
        selectedIndex = 0
        tableView.reloadData()
        if !filteredWindows.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    @objc func activateSelectedWindow() {
        guard selectedIndex >= 0 && selectedIndex < filteredWindows.count else { return }
        
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
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -5),
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
        
        windowController = SearchWindowController()
        windowController?.loadWindow()
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
