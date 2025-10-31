import Cocoa
import Foundation

// MARK: - Configuration

public struct Config {
    var windowWidth: CGFloat = 720
    var windowHeight: CGFloat = 60
    var backgroundColor: NSColor = .init(hex: "#24273A") ?? .darkGray
    var textColor: NSColor = .init(hex: "#CAD3F5") ?? .white
    var placeholderColor: NSColor = .init(hex: "#6E738D") ?? .gray
    var selectionColor: NSColor = .init(hex: "#8AADF4") ?? .blue
    var selectedTextColor: NSColor = .init(hex: "#24273A") ?? .black
    var borderColor: NSColor = .init(hex: "#5B6078") ?? .gray
    var borderWidth: CGFloat = 2
    var cornerRadius: CGFloat = 8
    var fontName: String = "Menlo"
    var fontSize: CGFloat = 20
    var maxResults: Int = 10
    var caseSensitive: Bool = false
    var position: String = "center"
    var opacity: CGFloat = 0.95

    // UI sizing
    var listRowHeight: CGFloat = 28
    var inputPadding: CGFloat = 12
    var maxListHeight: CGFloat {
        return CGFloat(maxResults) * listRowHeight
    }

    // Performance
    var cacheWindowList: Bool = true
    var cacheTimeoutSeconds: Double = 2.0

    // Application behavior
    var hideFromDock: Bool = true

    public static func load() -> Config {
        var config = Config()

        // XDG config locations
        let configPaths = [
            ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"].map { "\($0)/yjump/yjump.conf" },
            "\(NSHomeDirectory())/.config/yjump/yjump.conf",
            "\(NSHomeDirectory())/.yjump.conf",
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
            case "selected_text_color":
                if let color = NSColor(hex: value) { selectedTextColor = color }
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
            case "cache_window_list":
                cacheWindowList = value.lowercased() == "true"
            case "cache_timeout_seconds":
                if let val = Double(value) { cacheTimeoutSeconds = val }
            case "opacity":
                if let val = Double(value) { opacity = CGFloat(val) }
            case "hide_from_dock":
                hideFromDock = value.lowercased() == "true"
            default:
                break
            }
        }
    }
}

// MARK: - NSColor Extension

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
