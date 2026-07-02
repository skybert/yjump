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

// MARK: - Window Filter (duplicated for testing)
//
// Mirrors WindowManager.shouldListWindow in src/gui.swift. Since yjump now
// enumerates windows across every Space (so maximised, native full-screen
// apps are listed too), this filter is what keeps the list to normal,
// reasonably sized application windows.

func shouldListWindow(ownerName: String, layer: Int, bounds: CGRect) -> Bool {
    if ownerName.isEmpty || ownerName == "Window Server" || ownerName == "Dock" {
        return false
    }
    if layer != 0 {
        return false
    }
    if bounds.width < 50 || bounds.height < 50 {
        return false
    }
    return true
}

// MARK: - Tests

print("Running Window Filter Tests...")

let normalBounds = CGRect(x: 0, y: 0, width: 800, height: 600)

func testListsNormalWindow() {
    assertTest(
        shouldListWindow(ownerName: "kitty", layer: 0, bounds: normalBounds),
        "A normal layer-0 window should be listed"
    )
}

func testListsMaximisedWindow() {
    // A maximised app lives on its own Space but is still a normal layer-0
    // window; it must be offered as a jump target.
    let fullScreen = CGRect(x: 0, y: 0, width: 3840, height: 2160)
    assertTest(
        shouldListWindow(ownerName: "kitty", layer: 0, bounds: fullScreen),
        "A maximised window should be listed"
    )
}

func testRejectsEmptyOwner() {
    assertTest(
        !shouldListWindow(ownerName: "", layer: 0, bounds: normalBounds),
        "A window with no owner name should be rejected"
    )
}

func testRejectsWindowServer() {
    assertTest(
        !shouldListWindow(ownerName: "Window Server", layer: 0, bounds: normalBounds),
        "Window Server should be rejected"
    )
}

func testRejectsDock() {
    assertTest(
        !shouldListWindow(ownerName: "Dock", layer: 0, bounds: normalBounds),
        "Dock should be rejected"
    )
}

func testRejectsNonZeroLayer() {
    // Menus, panels and the status bar live above layer 0.
    assertTest(
        !shouldListWindow(ownerName: "kitty", layer: 25, bounds: normalBounds),
        "A non-zero layer window (menu/panel/chrome) should be rejected"
    )
}

func testRejectsNegativeLayer() {
    // Desktop/background windows sit below layer 0.
    assertTest(
        !shouldListWindow(ownerName: "Finder", layer: -1, bounds: normalBounds),
        "A negative layer window should be rejected"
    )
}

func testRejectsTinyWidth() {
    let tiny = CGRect(x: 0, y: 0, width: 49, height: 600)
    assertTest(
        !shouldListWindow(ownerName: "kitty", layer: 0, bounds: tiny),
        "A window narrower than 50px should be rejected"
    )
}

func testRejectsTinyHeight() {
    let tiny = CGRect(x: 0, y: 0, width: 800, height: 49)
    assertTest(
        !shouldListWindow(ownerName: "kitty", layer: 0, bounds: tiny),
        "A window shorter than 50px should be rejected"
    )
}

func testAcceptsExactMinimumSize() {
    let minimum = CGRect(x: 0, y: 0, width: 50, height: 50)
    assertTest(
        shouldListWindow(ownerName: "kitty", layer: 0, bounds: minimum),
        "A window at exactly the 50x50 minimum should be listed"
    )
}

func testRejectsZeroBounds() {
    assertTest(
        !shouldListWindow(ownerName: "kitty", layer: 0, bounds: .zero),
        "A zero-size window should be rejected"
    )
}

testListsNormalWindow()
testListsMaximisedWindow()
testRejectsEmptyOwner()
testRejectsWindowServer()
testRejectsDock()
testRejectsNonZeroLayer()
testRejectsNegativeLayer()
testRejectsTinyWidth()
testRejectsTinyHeight()
testAcceptsExactMinimumSize()
testRejectsZeroBounds()

printTestResults()
