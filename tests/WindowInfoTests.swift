import CoreGraphics
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

// MARK: - Window Information (duplicated for testing)
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

// MARK: - Bounds Distance Function
func boundsDistance(_ b1: CGRect, _ b2: CGRect) -> CGFloat {
    return abs(b1.origin.x - b2.origin.x) + abs(b1.origin.y - b2.origin.y) +
           abs(b1.width - b2.width) + abs(b1.height - b2.height)
}

// MARK: - Tests
print("Running Window Info Tests...")

func testDisplayTextWithTitle() {
    let window = WindowInfo(
        windowNumber: 1,
        ownerPID: 100,
        ownerName: "Firefox",
        windowTitle: "GitHub - Mozilla Firefox",
        bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
        workspace: 0
    )
    
    assertEqual(window.displayText, "Firefox: GitHub - Mozilla Firefox", "Display text with title")
}

func testDisplayTextWithoutTitle() {
    let window = WindowInfo(
        windowNumber: 2,
        ownerPID: 101,
        ownerName: "Terminal",
        windowTitle: "",
        bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
        workspace: 0
    )
    
    assertEqual(window.displayText, "Terminal", "Display text without title")
}

func testSearchableTextIsLowercase() {
    let window = WindowInfo(
        windowNumber: 3,
        ownerPID: 102,
        ownerName: "Google Chrome",
        windowTitle: "GitHub Homepage",
        bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
        workspace: 0
    )
    
    assertEqual(window.searchableText, "google chrome: github homepage", "Searchable text should be lowercase")
}

func testSearchableTextWithoutTitle() {
    let window = WindowInfo(
        windowNumber: 4,
        ownerPID: 103,
        ownerName: "Safari",
        windowTitle: "",
        bounds: CGRect(x: 0, y: 0, width: 800, height: 600),
        workspace: 0
    )
    
    assertEqual(window.searchableText, "safari", "Searchable text without title")
}

func testBoundsStorage() {
    let bounds = CGRect(x: 100, y: 200, width: 1024, height: 768)
    let window = WindowInfo(
        windowNumber: 5,
        ownerPID: 104,
        ownerName: "VSCode",
        windowTitle: "main.swift",
        bounds: bounds,
        workspace: 1
    )
    
    assertEqual(window.bounds.origin.x, 100, "Bounds x coordinate")
    assertEqual(window.bounds.origin.y, 200, "Bounds y coordinate")
    assertEqual(window.bounds.width, 1024, "Bounds width")
    assertEqual(window.bounds.height, 768, "Bounds height")
}

func testWorkspaceStorage() {
    let window1 = WindowInfo(
        windowNumber: 6,
        ownerPID: 105,
        ownerName: "App1",
        windowTitle: "Title1",
        bounds: CGRect.zero,
        workspace: 0
    )
    
    let window2 = WindowInfo(
        windowNumber: 7,
        ownerPID: 106,
        ownerName: "App2",
        windowTitle: "Title2",
        bounds: CGRect.zero,
        workspace: 2
    )
    
    assertEqual(window1.workspace, 0, "Workspace 0")
    assertEqual(window2.workspace, 2, "Workspace 2")
}

func testPIDAndWindowNumber() {
    let window = WindowInfo(
        windowNumber: 12345,
        ownerPID: 9999,
        ownerName: "TestApp",
        windowTitle: "TestWindow",
        bounds: CGRect.zero,
        workspace: 0
    )
    
    assertEqual(window.windowNumber, 12345, "Window number")
    assertEqual(window.ownerPID, 9999, "Owner PID")
}

func testSpecialCharactersInTitle() {
    let window = WindowInfo(
        windowNumber: 8,
        ownerPID: 107,
        ownerName: "Emacs",
        windowTitle: "README.md - ~/Projects/yjump",
        bounds: CGRect.zero,
        workspace: 0
    )
    
    assertEqual(window.displayText, "Emacs: README.md - ~/Projects/yjump", "Display text with special characters")
    assertTest(window.searchableText.contains("readme.md"), "Searchable text should contain readme.md")
}

func testUnicodeInTitle() {
    let window = WindowInfo(
        windowNumber: 9,
        ownerPID: 108,
        ownerName: "Notes",
        windowTitle: "📝 TODO List",
        bounds: CGRect.zero,
        workspace: 0
    )
    
    assertEqual(window.displayText, "Notes: 📝 TODO List", "Display text with unicode")
    assertTest(window.searchableText.contains("📝"), "Searchable text should contain emoji")
}

// Run all window info tests
testDisplayTextWithTitle()
testDisplayTextWithoutTitle()
testSearchableTextIsLowercase()
testSearchableTextWithoutTitle()
testBoundsStorage()
testWorkspaceStorage()
testPIDAndWindowNumber()
testSpecialCharactersInTitle()
testUnicodeInTitle()

// MARK: - Bounds Distance Tests
print("\nRunning Bounds Distance Tests...")

func testIdenticalBounds() {
    let bounds = CGRect(x: 100, y: 200, width: 800, height: 600)
    let distance = boundsDistance(bounds, bounds)
    
    assertEqual(distance, 0, "Identical bounds should have zero distance")
}

func testDifferentOriginOnly() {
    let bounds1 = CGRect(x: 100, y: 200, width: 800, height: 600)
    let bounds2 = CGRect(x: 110, y: 210, width: 800, height: 600)
    let distance = boundsDistance(bounds1, bounds2)
    
    // |110-100| + |210-200| + |800-800| + |600-600| = 10 + 10 = 20
    assertEqual(distance, 20, "Different origin only distance")
}

func testDifferentSizeOnly() {
    let bounds1 = CGRect(x: 100, y: 200, width: 800, height: 600)
    let bounds2 = CGRect(x: 100, y: 200, width: 850, height: 650)
    let distance = boundsDistance(bounds1, bounds2)
    
    // |100-100| + |200-200| + |850-800| + |650-600| = 50 + 50 = 100
    assertEqual(distance, 100, "Different size only distance")
}

func testCompletelyDifferent() {
    let bounds1 = CGRect(x: 0, y: 0, width: 800, height: 600)
    let bounds2 = CGRect(x: 100, y: 200, width: 1024, height: 768)
    let distance = boundsDistance(bounds1, bounds2)
    
    // |100-0| + |200-0| + |1024-800| + |768-600| = 100 + 200 + 224 + 168 = 692
    assertEqual(distance, 692, "Completely different bounds distance")
}

func testNegativeCoordinates() {
    let bounds1 = CGRect(x: -100, y: -200, width: 800, height: 600)
    let bounds2 = CGRect(x: 100, y: 200, width: 800, height: 600)
    let distance = boundsDistance(bounds1, bounds2)
    
    // |100-(-100)| + |200-(-200)| + |800-800| + |600-600| = 200 + 400 = 600
    assertEqual(distance, 600, "Negative coordinates distance")
}

func testSmallDifference() {
    let bounds1 = CGRect(x: 100, y: 200, width: 800, height: 600)
    let bounds2 = CGRect(x: 101, y: 201, width: 801, height: 601)
    let distance = boundsDistance(bounds1, bounds2)
    
    // Small difference = 1 + 1 + 1 + 1 = 4
    assertEqual(distance, 4, "Small difference distance")
}

func testZeroBounds() {
    let bounds1 = CGRect.zero
    let bounds2 = CGRect(x: 100, y: 200, width: 800, height: 600)
    let distance = boundsDistance(bounds1, bounds2)
    
    assertEqual(distance, 1700, "Zero bounds distance")
}

// Run all bounds distance tests
testIdenticalBounds()
testDifferentOriginOnly()
testDifferentSizeOnly()
testCompletelyDifferent()
testNegativeCoordinates()
testSmallDifference()
testZeroBounds()

printTestResults()
