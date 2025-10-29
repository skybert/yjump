import Foundation

// MARK: - Version Information

let VERSION = "GIT_VERSION_PLACEHOLDER"

// MARK: - CLI Parsing

enum CLI {
    static func parse() -> Bool {
        let args = CommandLine.arguments

        // Check for --help or -h
        if args.contains("--help") || args.contains("-h") {
            printHelp()
            return true
        }

        // Check for --version or -v
        if args.contains("--version") || args.contains("-v") {
            printVersion()
            return true
        }

        // No special flags, continue with normal execution
        return false
    }

    static func printHelp() {
        print("""
        yjump - Fast window switcher for macOS

        USAGE:
            yjump [OPTIONS]

        OPTIONS:
            -h, --help       Show this help message
            -v, --version    Show version information

        DESCRIPTION:
            yjump is a fast window switcher for macOS with fuzzy search.
            When launched, it displays a search interface where you can type
            to filter and switch between open windows across all workspaces.

        KEYBOARD SHORTCUTS:
            Type             Search and filter windows
            ↑/↓              Navigate results
            Enter            Activate selected window
            Esc              Cancel and quit

        CONFIGURATION:
            Config file: ~/.config/yjump/yjump.conf
            Man page:    man yjump

        For more information, see: https://github.com/skybert/yjump
        """)
    }

    static func printVersion() {
        print("yjump version \(VERSION)")
    }
}
