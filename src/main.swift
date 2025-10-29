import Cocoa
import Foundation

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
  var windowController: SearchWindowController?

  func applicationDidFinishLaunching(_: Notification) {
    // Parse CLI arguments first
    if CLI.parse() {
      // CLI handled the request (--help or --version), exit
      exit(0)
    }

    // Check for running instance of yjump
    let runningApps = NSWorkspace.shared.runningApplications
    let yjumpInstances = runningApps.filter { app in
      if let bundleId = app.bundleIdentifier {
        return bundleId.contains("yjump")
      }
      // Also check by executable name
      let execName = app.executableURL?.lastPathComponent ?? ""
      return execName == "yjump"
    }

    // If there are other instances (more than just this one), terminate
    if yjumpInstances.count > 1 {
      // Try to activate the existing instance
      for app in yjumpInstances {
        if app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        {
          app.activate()
          break
        }
      }
      exit(0)
    }

    // Request accessibility permissions
    let options: NSDictionary = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    let accessEnabled = AXIsProcessTrustedWithOptions(options)

    if !accessEnabled {
      let alert = NSAlert()
      alert.messageText = "Accessibility Permission Required"
      alert.informativeText =
        "yjump needs accessibility permissions to switch windows. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility."
      alert.alertStyle = .warning
      alert.addButton(withTitle: "OK")
      alert.runModal()
    }

    // Load config
    let config = Config.load()

    // Create and show window
    windowController = SearchWindowController(config: config)
    windowController?.loadWindow()
    windowController?.window?.makeKeyAndOrderFront(self)

    // Ensure window gets focus
    NSApp.activate(ignoringOtherApps: true)
    windowController?.window?.makeKey()
    windowController?.window?.orderFrontRegardless()
    windowController?.window?.makeFirstResponder(
      windowController?.searchField)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication)
    -> Bool
  {
    return true
  }
}

// MARK: - Main Entry Point

func main() {
  // Load config early to determine activation policy
  let config = Config.load()

  let app = NSApplication.shared
  // Set activation policy based on config
  if config.hideFromDock {
    app.setActivationPolicy(.accessory)  // Don't show in Dock
  } else {
    app.setActivationPolicy(.regular)  // Show in Dock and app switcher
  }

  let delegate = AppDelegate()
  app.delegate = delegate
  app.run()
}

// Start the application
main()
