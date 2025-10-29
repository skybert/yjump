import Foundation

// MARK: - Simple Test Framework
var testsPassed = 0
var testsFailed = 0

func assert(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
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

// MARK: - Fuzzy Matching (duplicated for testing)
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

// MARK: - Tests
print("Running Fuzzy Match Tests...")

func testEmptyPattern() {
    let result = fuzzyMatch("", "any text")
    assert(result.matches, "Empty pattern should match")
    assertEqual(result.score, 0, "Empty pattern score should be 0")
}

func testExactSubstringMatch() {
    let result = fuzzyMatch("fox", "the quick brown fox jumps")
    assert(result.matches, "Should match exact substring")
    assertGreaterThan(result.score, 0, "Match should have positive score")
}

func testSubstringMatchAtBeginning() {
    let result1 = fuzzyMatch("the", "the quick brown fox")
    let result2 = fuzzyMatch("fox", "the quick brown fox")
    
    assert(result1.matches, "Should match at beginning")
    assert(result2.matches, "Should match later in string")
    
    // Match at beginning should have higher score
    assertGreaterThan(result1.score, result2.score, "Earlier match should score higher")
}

func testCaseInsensitiveByDefault() {
    let result1 = fuzzyMatch("FIREFOX", "firefox")
    let result2 = fuzzyMatch("firefox", "FIREFOX")
    let result3 = fuzzyMatch("FiReFoX", "firefox")
    
    assert(result1.matches, "Should match case insensitive (upper to lower)")
    assert(result2.matches, "Should match case insensitive (lower to upper)")
    assert(result3.matches, "Should match case insensitive (mixed)")
}

func testCaseSensitiveMode() {
    let result1 = fuzzyMatch("Firefox", "firefox", caseSensitive: true)
    let result2 = fuzzyMatch("firefox", "firefox", caseSensitive: true)
    
    assert(!result1.matches, "Should not match with wrong case")
    assert(result2.matches, "Should match with correct case")
}

func testFuzzyMatchingWithGaps() {
    let result = fuzzyMatch("gchr", "google chrome")
    assert(result.matches, "Should fuzzy match with gaps")
    assertGreaterThan(result.score, 0, "Fuzzy match should have positive score")
}

func testFuzzyMatchingConsecutiveLetters() {
    // Consecutive matches should score higher
    let result1 = fuzzyMatch("chr", "chrome browser")
    let result2 = fuzzyMatch("cbr", "chrome browser")
    
    assert(result1.matches, "Should match consecutive letters")
    assert(result2.matches, "Should match non-consecutive letters")
    
    // "chr" is consecutive in "chrome", so should score higher
    assertGreaterThan(result1.score, result2.score, "Consecutive match should score higher")
}

func testNoMatch() {
    let result = fuzzyMatch("xyz", "abc def")
    assert(!result.matches, "Should not match unrelated pattern")
    assertEqual(result.score, 0, "No match should have zero score")
}

func testPartialNoMatch() {
    let result = fuzzyMatch("abcd", "abc")
    assert(!result.matches, "Should not match if pattern longer than text")
    assertEqual(result.score, 0, "Partial match should have zero score")
}

func testSingleCharacterMatch() {
    let result = fuzzyMatch("f", "firefox")
    assert(result.matches, "Should match single character")
    assertGreaterThan(result.score, 0, "Single char match should have positive score")
}

func testWhitespaceHandling() {
    let result = fuzzyMatch("go ch", "google chrome")
    assert(result.matches, "Should handle whitespace in pattern")
}

func testSpecialCharacters() {
    let result = fuzzyMatch("c++", "visual studio c++")
    assert(result.matches, "Should handle special characters")
}

func testApplicationNameMatching() {
    // Real-world examples
    let testCases = [
        ("chr", "Google Chrome"),
        ("fire", "Firefox"),
        ("code", "Visual Studio Code"),
        ("term", "Terminal"),
        ("safa", "Safari"),
    ]
    
    for (pattern, text) in testCases {
        let result = fuzzyMatch(pattern, text)
        assert(result.matches, "Failed to match '\(pattern)' in '\(text)'")
        assertGreaterThan(result.score, 0, "Match '\(pattern)' in '\(text)' should have positive score")
    }
}

func testWindowTitleMatching() {
    let result1 = fuzzyMatch("readme", "README.md - Visual Studio Code")
    let result2 = fuzzyMatch("code", "README.md - Visual Studio Code")
    
    assert(result1.matches, "Should match readme in title")
    assert(result2.matches, "Should match code in title")
}

func testScoreComparison() {
    // Earlier matches should score higher
    let text = "Firefox Developer Edition"
    let result1 = fuzzyMatch("fire", text)
    let result2 = fuzzyMatch("dev", text)
    let result3 = fuzzyMatch("edit", text)
    
    assert(result1.matches, "Should match 'fire'")
    assert(result2.matches, "Should match 'dev'")
    assert(result3.matches, "Should match 'edit'")
    
    // "fire" appears first, should score highest
    assertGreaterThan(result1.score, result2.score, "'fire' should score higher than 'dev'")
    assertGreaterThan(result2.score, result3.score, "'dev' should score higher than 'edit'")
}

func testUnicodeCharacters() {
    let result = fuzzyMatch("café", "café editor")
    assert(result.matches, "Should handle unicode characters")
}

func testNumbers() {
    let result = fuzzyMatch("v2", "Firefox v2.0")
    assert(result.matches, "Should match numbers")
}

func testLongPattern() {
    let result = fuzzyMatch("visual studio code", "Visual Studio Code - README.md")
    assert(result.matches, "Should match long patterns")
}

// Run all tests
testEmptyPattern()
testExactSubstringMatch()
testSubstringMatchAtBeginning()
testCaseInsensitiveByDefault()
testCaseSensitiveMode()
testFuzzyMatchingWithGaps()
testFuzzyMatchingConsecutiveLetters()
testNoMatch()
testPartialNoMatch()
testSingleCharacterMatch()
testWhitespaceHandling()
testSpecialCharacters()
testApplicationNameMatching()
testWindowTitleMatching()
testScoreComparison()
testUnicodeCharacters()
testNumbers()
testLongPattern()

printTestResults()
