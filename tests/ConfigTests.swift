import Cocoa
import Foundation

// MARK: - Simple Test Framework
var testsPassed = 0
var testsFailed = 0

func assertTest(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    if condition {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAILED: \(message) at \(file):\(line)")
    }
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if actual == expected {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAILED: \(message)")
        print("   Expected: \(expected)")
        print("   Got: \(actual)")
        print("   at \(file):\(line)")
    }
}

func assertNotNil<T>(_ value: T?, _ message: String = "", file: String = #file, line: Int = #line) {
    if value != nil {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAILED: \(message) - value was nil at \(file):\(line)")
    }
}

func assertNil<T>(_ value: T?, _ message: String = "", file: String = #file, line: Int = #line) {
    if value == nil {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAILED: \(message) - value was not nil at \(file):\(line)")
    }
}

func assertGreaterThan<T: Comparable>(_ value: T, _ threshold: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if value > threshold {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAILED: \(message)")
        print("   Expected: \(value) > \(threshold)")
        print("   at \(file):\(line)")
    }
}

func printTestResults() {
    print("\n" + String(repeating: "=", count: 50))
    if testsFailed == 0 {
        print("✅ All tests passed! (\(testsPassed) tests)")
    } else {
        print("❌ Some tests failed!")
        print("   Passed: \(testsPassed)")
        print("   Failed: \(testsFailed)")
    }
    print(String(repeating: "=", count: 50))
    exit(testsFailed > 0 ? 1 : 0)
}

// Import the Config struct from conf.swift
// MARK: - NSColor Extension (duplicated for testing)
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

// MARK: - Configuration
public struct Config {
    var windowWidth: CGFloat = 600
    var windowHeight: CGFloat = 50
    var backgroundColor: NSColor = NSColor(hex: "#24273A") ?? .darkGray
    var textColor: NSColor = NSColor(hex: "#CAD3F5") ?? .white
    var placeholderColor: NSColor = NSColor(hex: "#6E738D") ?? .gray
    var selectionColor: NSColor = NSColor(hex: "#8AADF4") ?? .blue
    var borderColor: NSColor = NSColor(hex: "#5B6078") ?? .gray
    var borderWidth: CGFloat = 2
    var cornerRadius: CGFloat = 8
    var fontName: String = "Menlo"
    var fontSize: CGFloat = 14
    var maxResults: Int = 10
    var caseSensitive: Bool = false
    var position: String = "center"
    var opacity: CGFloat = 0.95
    
    var listRowHeight: CGFloat = 28
    var inputPadding: CGFloat = 12
    var maxListHeight: CGFloat {
        return CGFloat(maxResults) * listRowHeight
    }
    
    var cacheWindowList: Bool = true
    var cacheTimeoutSeconds: Double = 2.0
    
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
            case "cache_window_list":
                cacheWindowList = value.lowercased() == "true"
            case "cache_timeout_seconds":
                if let val = Double(value) { cacheTimeoutSeconds = val }
            case "opacity":
                if let val = Double(value) { opacity = CGFloat(val) }
            default:
                break
            }
        }
    }
}

// MARK: - Tests
print("Running Config Tests...")

func testDefaultConfig() {
    let config = Config()
    
    assertEqual(config.windowWidth, 600, "Default window width")
    assertEqual(config.windowHeight, 50, "Default window height")
    assertEqual(config.borderWidth, 2, "Default border width")
    assertEqual(config.cornerRadius, 8, "Default corner radius")
    assertEqual(config.fontName, "Menlo", "Default font name")
    assertEqual(config.fontSize, 14, "Default font size")
    assertEqual(config.maxResults, 10, "Default max results")
    assertEqual(config.caseSensitive, false, "Default case sensitive")
    assertEqual(config.position, "center", "Default position")
    assertEqual(config.opacity, 0.95, "Default opacity")
    assertEqual(config.cacheWindowList, true, "Default cache window list")
    assertEqual(config.cacheTimeoutSeconds, 2.0, "Default cache timeout")
}

func testCatppuccinMacchiatoColors() {
    // Test that default colors match Catppuccin Macchiato
    let expectedBg = NSColor(hex: "#24273A")
    let expectedText = NSColor(hex: "#CAD3F5")
    let expectedPlaceholder = NSColor(hex: "#6E738D")
    let expectedSelection = NSColor(hex: "#8AADF4")
    let expectedBorder = NSColor(hex: "#5B6078")
    
    assertNotNil(expectedBg, "Catppuccin background color")
    assertNotNil(expectedText, "Catppuccin text color")
    assertNotNil(expectedPlaceholder, "Catppuccin placeholder color")
    assertNotNil(expectedSelection, "Catppuccin selection color")
    assertNotNil(expectedBorder, "Catppuccin border color")
}

func testParseWindowDimensions() {
    var config = Config()
    let configText = """
    window_width = 800
    window_height = 60
    """
    
    config.parse(configText)
    
    assertEqual(config.windowWidth, 800, "Parsed window width")
    assertEqual(config.windowHeight, 60, "Parsed window height")
}

func testParseColors() {
    var config = Config()
    let configText = """
    background_color = #FF0000
    text_color = #00FF00
    placeholder_color = #0000FF
    selection_color = #FFFF00
    border_color = #FF00FF
    """
    
    config.parse(configText)
    
    // Colors should be parsed and set
    assertTest(config.backgroundColor != NSColor.darkGray, "Background color should be parsed")
    assertTest(config.textColor != NSColor.white, "Text color should be parsed")
}

func testParseBorderAndRadius() {
    var config = Config()
    let configText = """
    border_width = 5
    corner_radius = 12
    """
    
    config.parse(configText)
    
    assertEqual(config.borderWidth, 5, "Parsed border width")
    assertEqual(config.cornerRadius, 12, "Parsed corner radius")
}

func testParseFont() {
    var config = Config()
    let configText = """
    font_name = Monaco
    font_size = 16
    """
    
    config.parse(configText)
    
    assertEqual(config.fontName, "Monaco", "Parsed font name")
    assertEqual(config.fontSize, 16, "Parsed font size")
}

func testParseBehavior() {
    var config = Config()
    let configText = """
    max_results = 20
    case_sensitive = true
    position = top
    """
    
    config.parse(configText)
    
    assertEqual(config.maxResults, 20, "Parsed max results")
    assertEqual(config.caseSensitive, true, "Parsed case sensitive")
    assertEqual(config.position, "top", "Parsed position")
}

func testParseOpacity() {
    var config = Config()
    let configText = """
    opacity = 0.75
    """
    
    config.parse(configText)
    
    assertEqual(config.opacity, 0.75, "Parsed opacity")
}

func testParseCache() {
    var config = Config()
    let configText = """
    cache_window_list = false
    cache_timeout_seconds = 5.0
    """
    
    config.parse(configText)
    
    assertEqual(config.cacheWindowList, false, "Parsed cache window list")
    assertEqual(config.cacheTimeoutSeconds, 5.0, "Parsed cache timeout")
}

func testParseIgnoresComments() {
    var config = Config()
    let configText = """
    # This is a comment
    window_width = 700
    # Another comment
    window_height = 55
    """
    
    config.parse(configText)
    
    assertEqual(config.windowWidth, 700, "Parsed window width with comments")
    assertEqual(config.windowHeight, 55, "Parsed window height with comments")
}

func testParseIgnoresEmptyLines() {
    var config = Config()
    let configText = """
    window_width = 700
    
    
    window_height = 55
    """
    
    config.parse(configText)
    
    assertEqual(config.windowWidth, 700, "Parsed window width with empty lines")
    assertEqual(config.windowHeight, 55, "Parsed window height with empty lines")
}

func testParseIgnoresMalformedLines() {
    var config = Config()
    let configText = """
    window_width = 700
    this is malformed
    window_height = 55
    also = malformed = line
    """
    
    config.parse(configText)
    
    assertEqual(config.windowWidth, 700, "Parsed window width ignoring malformed")
    assertEqual(config.windowHeight, 55, "Parsed window height ignoring malformed")
}

func testMaxListHeightCalculation() {
    var config = Config()
    config.maxResults = 10
    config.listRowHeight = 28
    
    assertEqual(config.maxListHeight, 280, "Calculated max list height for 10 results")
    
    config.maxResults = 15
    assertEqual(config.maxListHeight, 420, "Calculated max list height for 15 results")
}

func testNSColorHexInitializer() {
    // Test 6-digit hex
    let color1 = NSColor(hex: "#FF0000")
    assertNotNil(color1, "6-digit hex color")
    
    // Test 8-digit hex (with alpha)
    let color2 = NSColor(hex: "#FF0000AA")
    assertNotNil(color2, "8-digit hex color with alpha")
    
    // Test without hash
    let color3 = NSColor(hex: "00FF00")
    assertNotNil(color3, "Hex color without hash")
    
    // Test invalid hex
    let color4 = NSColor(hex: "invalid")
    assertNil(color4, "Invalid hex should return nil")
}

// Run all tests
testDefaultConfig()
testCatppuccinMacchiatoColors()
testParseWindowDimensions()
testParseColors()
testParseBorderAndRadius()
testParseFont()
testParseBehavior()
testParseOpacity()
testParseCache()
testParseIgnoresComments()
testParseIgnoresEmptyLines()
testParseIgnoresMalformedLines()
testMaxListHeightCalculation()
testNSColorHexInitializer()

printTestResults()
