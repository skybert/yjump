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

func assertEqual<T: Equatable>(
    _ actual: T,
    _ expected: T,
    _ message: String = "",
    file: String = #file,
    line: Int = #line
) {
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

func assertGreaterThan<T: Comparable>(
    _ value: T,
    _ threshold: T,
    _ message: String = "",
    file: String = #file,
    line: Int = #line
) {
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

    // 1. Exact substring match - highest priority
    if textToSearch.contains(patternToSearch) {
        if let range = textToSearch.range(of: patternToSearch) {
            let position = textToSearch.distance(from: textToSearch.startIndex, to: range.lowerBound)
            // Higher score for exact matches, even higher if at start
            let score = 10000 - position
            return (true, score)
        }
    }

    // 2. Word boundary matches - medium priority
    // Match pattern at start of words in the text
    let words = textToSearch.components(separatedBy: .whitespacesAndNewlines)
    for (wordIndex, word) in words.enumerated() {
        if word.hasPrefix(patternToSearch) {
            // Score based on word position (earlier is better)
            let score = 5000 - (wordIndex * 100)
            return (true, score)
        }
        // Also check if word contains the pattern as substring
        if word.contains(patternToSearch) {
            let score = 3000 - (wordIndex * 100)
            return (true, score)
        }
    }

    // 3. Consecutive character matching - low priority
    // Only match if characters appear consecutively in individual words
    for word in words {
        var patternIndex = patternToSearch.startIndex
        var consecutiveCount = 0

        for char in word {
            if patternIndex < patternToSearch.endIndex && char == patternToSearch[patternIndex] {
                consecutiveCount += 1
                patternIndex = patternToSearch.index(after: patternIndex)
            } else if consecutiveCount > 0 {
                // Reset if we break the sequence
                patternIndex = patternToSearch.startIndex
                consecutiveCount = 0
            }
        }

        // Only match if we found all characters consecutively in a word
        if patternIndex == patternToSearch.endIndex {
            return (true, 1000 + consecutiveCount * 10)
        }
    }

    // No match found
    return (false, 0)
}

// MARK: - Tests

print("Running Fuzzy Match Tests...")

func testEmptyPattern() {
    let result = fuzzyMatch("", "any text")
    assertTest(result.matches, "Empty pattern should match")
    assertEqual(result.score, 0, "Empty pattern score should be 0")
}

func testExactSubstringMatch() {
    let result = fuzzyMatch("fox", "the quick brown fox jumps")
    assertTest(result.matches, "Should match exact substring")
    assertGreaterThan(result.score, 0, "Match should have positive score")
}

func testSubstringMatchAtBeginning() {
    let result1 = fuzzyMatch("the", "the quick brown fox")
    let result2 = fuzzyMatch("fox", "the quick brown fox")

    assertTest(result1.matches, "Should match at beginning")
    assertTest(result2.matches, "Should match later in string")

    // Match at beginning should have higher score
    assertGreaterThan(result1.score, result2.score, "Earlier match should score higher")
}

func testCaseInsensitiveByDefault() {
    let result1 = fuzzyMatch("FIREFOX", "firefox")
    let result2 = fuzzyMatch("firefox", "FIREFOX")
    let result3 = fuzzyMatch("FiReFoX", "firefox")

    assertTest(result1.matches, "Should match case insensitive (upper to lower)")
    assertTest(result2.matches, "Should match case insensitive (lower to upper)")
    assertTest(result3.matches, "Should match case insensitive (mixed)")
}

func testCaseSensitiveMode() {
    let result1 = fuzzyMatch("Firefox", "firefox", caseSensitive: true)
    let result2 = fuzzyMatch("firefox", "firefox", caseSensitive: true)

    assertTest(!result1.matches, "Should not match with wrong case")
    assertTest(result2.matches, "Should match with correct case")
}

func testFuzzyMatchingWithGaps() {
    // "gchr" should NOT match "google chrome" (too scattered)
    let result = fuzzyMatch("gchr", "google chrome")
    assertTest(!result.matches, "Should NOT match scattered letters across words")
}

func testFuzzyMatchingConsecutiveLetters() {
    // "chr" should match "chrome browser" (consecutive in word)
    let result1 = fuzzyMatch("chr", "chrome browser")
    let result2 = fuzzyMatch("bro", "chrome browser")

    assertTest(result1.matches, "Should match consecutive letters in word")
    assertTest(result2.matches, "Should match consecutive letters in word")

    // "chr" appears in first word, "bro" in second
    assertGreaterThan(result1.score, result2.score, "Earlier word match should score higher")
}

func testNoMatchScatteredLetters() {
    // "kitty" should NOT match "karl in this true year"
    let result = fuzzyMatch("kitty", "karl in this true year")
    assertTest(!result.matches, "Should NOT match scattered letters across multiple words")
}

func testWordBoundaryMatching() {
    // Should match word that starts with pattern
    let result1 = fuzzyMatch("fire", "Firefox Developer Edition")
    let result2 = fuzzyMatch("dev", "Firefox Developer Edition")

    assertTest(result1.matches, "Should match word starting with 'fire'")
    assertTest(result2.matches, "Should match word starting with 'dev'")

    // "fire" is in first word, should score higher
    assertGreaterThan(result1.score, result2.score, "Earlier word should score higher")
}

func testSubstringInWord() {
    // Should match substring within a word
    let result = fuzzyMatch("ube", "Kubernetes Dashboard")
    assertTest(result.matches, "Should match substring 'ube' in 'Kubernetes'")
}

func testNoMatch() {
    let result = fuzzyMatch("xyz", "abc def")
    assertTest(!result.matches, "Should not match unrelated pattern")
    assertEqual(result.score, 0, "No match should have zero score")
}

func testPartialNoMatch() {
    let result = fuzzyMatch("abcd", "abc")
    assertTest(!result.matches, "Should not match if pattern longer than text")
    assertEqual(result.score, 0, "Partial match should have zero score")
}

func testSingleCharacterMatch() {
    let result = fuzzyMatch("f", "firefox")
    assertTest(result.matches, "Should match single character")
    assertGreaterThan(result.score, 0, "Single char match should have positive score")
}

func testWhitespaceHandling() {
    // Whitespace in pattern should match exact phrase
    let result1 = fuzzyMatch("google chrome", "google chrome")
    assertTest(result1.matches, "Should match exact phrase with whitespace")
    
    // Single words should still match
    let result2 = fuzzyMatch("google", "google chrome")
    let result3 = fuzzyMatch("chrome", "google chrome")
    assertTest(result2.matches, "Should match first word")
    assertTest(result3.matches, "Should match second word")
}

func testSpecialCharacters() {
    let result = fuzzyMatch("c++", "visual studio c++")
    assertTest(result.matches, "Should handle special characters")
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

    assertTest(result1.matches, "Should match readme in title")
    assertTest(result2.matches, "Should match code in title")
}

func testScoreComparison() {
    // Earlier matches should score higher
    let text = "Firefox Developer Edition"
    let result1 = fuzzyMatch("fire", text)
    let result2 = fuzzyMatch("dev", text)
    let result3 = fuzzyMatch("edit", text)

    assertTest(result1.matches, "Should match 'fire'")
    assertTest(result2.matches, "Should match 'dev'")
    assertTest(result3.matches, "Should match 'edit'")

    // "fire" appears first, should score highest
    assertGreaterThan(result1.score, result2.score, "'fire' should score higher than 'dev'")
    assertGreaterThan(result2.score, result3.score, "'dev' should score higher than 'edit'")
}

func testUnicodeCharacters() {
    let result = fuzzyMatch("café", "café editor")
    assertTest(result.matches, "Should handle unicode characters")
}

func testNumbers() {
    let result = fuzzyMatch("v2", "Firefox v2.0")
    assertTest(result.matches, "Should match numbers")
}

func testLongPattern() {
    let result = fuzzyMatch("visual studio code", "Visual Studio Code - README.md")
    assertTest(result.matches, "Should match long patterns")
}

// Run all tests
testEmptyPattern()
testExactSubstringMatch()
testSubstringMatchAtBeginning()
testCaseInsensitiveByDefault()
testCaseSensitiveMode()
testFuzzyMatchingWithGaps()
testFuzzyMatchingConsecutiveLetters()
testNoMatchScatteredLetters()
testWordBoundaryMatching()
testSubstringInWord()
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
